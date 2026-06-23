import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Tags parsed from an audio file using a pure-Dart ID3 reader (no native deps).
class TrackTags {
  final String? title;
  final String? artist;
  final String? album;
  final Uint8List? artwork;

  const TrackTags({this.title, this.artist, this.album, this.artwork});
}

/// Reads title/artist/album and embedded cover art from a file.
/// Tries ID3v2 (mp3) first, then falls back to ID3v1. Returns empty tags on
/// failure; the caller decides how to fall back (e.g. to the file name).
TrackTags readTrackTags(String path) {
  try {
    final file = File(path);
    if (!file.existsSync()) return const TrackTags();
    final v2 = _readId3v2(file);
    if (v2 != null) return v2;
    final v1 = _readId3v1(file);
    if (v1 != null) return v1;
  } catch (_) {}
  return const TrackTags();
}

int _synchsafe(int b1, int b2, int b3, int b4) =>
    ((b1 & 0x7f) << 21) | ((b2 & 0x7f) << 14) | ((b3 & 0x7f) << 7) | (b4 & 0x7f);

int _be(int b1, int b2, int b3, int b4) =>
    (b1 << 24) | (b2 << 16) | (b3 << 8) | b4;

TrackTags? _readId3v2(File file) {
  final raf = file.openSync(mode: FileMode.read);
  try {
    final len = raf.lengthSync();
    if (len < 10) return null;
    final header = raf.readSync(10);
    if (header[0] != 0x49 || header[1] != 0x44 || header[2] != 0x33) {
      return null; // not "ID3"
    }
    final major = header[3];
    final tagSize = _synchsafe(header[6], header[7], header[8], header[9]);
    if (tagSize <= 0 || tagSize > len) return null;
    final body = raf.readSync(tagSize);

    String? title;
    String? artist;
    String? album;
    Uint8List? artwork;

    final idLen = major == 2 ? 3 : 4;
    final sizeLen = major == 2 ? 3 : 4;
    int pos = 0;
    while (pos + idLen + sizeLen <= body.length) {
      final id = String.fromCharCodes(body.sublist(pos, pos + idLen));
      if (id.codeUnitAt(0) == 0) break; // padding

      int frameSize;
      int headerLen;
      if (major == 2) {
        frameSize = (body[pos + 3] << 16) | (body[pos + 4] << 8) | body[pos + 5];
        headerLen = 6;
      } else {
        final s1 = body[pos + 4], s2 = body[pos + 5], s3 = body[pos + 6], s4 = body[pos + 7];
        frameSize = major == 4 ? _synchsafe(s1, s2, s3, s4) : _be(s1, s2, s3, s4);
        headerLen = 10;
      }
      final dataStart = pos + headerLen;
      if (frameSize <= 0 || dataStart + frameSize > body.length) break;
      final data = body.sublist(dataStart, dataStart + frameSize);

      if (id == 'TIT2' || id == 'TT2') {
        title = _decodeText(data);
      } else if (id == 'TPE1' || id == 'TP1') {
        artist = _decodeText(data);
      } else if (id == 'TALB' || id == 'TAL') {
        album = _decodeText(data);
      } else if (id == 'APIC' || id == 'PIC') {
        artwork ??= _decodeApic(data, major);
      }

      pos = dataStart + frameSize;
    }

    if (title == null && artist == null && album == null && artwork == null) {
      return null;
    }
    return TrackTags(
      title: _clean(title),
      artist: _clean(artist),
      album: _clean(album),
      artwork: artwork,
    );
  } finally {
    raf.closeSync();
  }
}

String? _clean(String? s) {
  if (s == null) return null;
  final t = s.replaceAll('\u0000', '').trim();
  return t.isEmpty ? null : t;
}

String _decodeText(List<int> data) {
  if (data.isEmpty) return '';
  final encoding = data[0];
  final bytes = data.sublist(1);
  return _decodeByEncoding(encoding, bytes);
}

String _decodeByEncoding(int encoding, List<int> bytes) {
  try {
    switch (encoding) {
      case 0: // ISO-8859-1
        return latin1.decode(bytes, allowInvalid: true);
      case 1: // UTF-16 with BOM
        return _decodeUtf16(bytes);
      case 2: // UTF-16BE without BOM
        return _decodeUtf16(bytes, bigEndian: true);
      case 3: // UTF-8
      default:
        return utf8.decode(bytes, allowMalformed: true);
    }
  } catch (_) {
    return latin1.decode(bytes, allowInvalid: true);
  }
}

String _decodeUtf16(List<int> bytes, {bool bigEndian = false}) {
  var data = bytes;
  var be = bigEndian;
  if (data.length >= 2) {
    if (data[0] == 0xFF && data[1] == 0xFE) {
      be = false;
      data = data.sublist(2);
    } else if (data[0] == 0xFE && data[1] == 0xFF) {
      be = true;
      data = data.sublist(2);
    }
  }
  final units = <int>[];
  for (var i = 0; i + 1 < data.length; i += 2) {
    units.add(be ? (data[i] << 8) | data[i + 1] : (data[i + 1] << 8) | data[i]);
  }
  return String.fromCharCodes(units);
}

Uint8List? _decodeApic(List<int> data, int major) {
  if (data.isEmpty) return null;
  final encoding = data[0];
  int i = 1;
  if (major == 2) {
    // v2.2 PIC: 3-byte image format instead of MIME string.
    i += 3;
  } else {
    // MIME type, null-terminated ISO-8859-1.
    while (i < data.length && data[i] != 0) {
      i++;
    }
    i++; // skip null
  }
  if (i >= data.length) return null;
  i++; // picture type byte
  // Description, terminated by null (single byte) or double-null (UTF-16).
  if (encoding == 1 || encoding == 2) {
    while (i + 1 < data.length && !(data[i] == 0 && data[i + 1] == 0)) {
      i += 2;
    }
    i += 2;
  } else {
    while (i < data.length && data[i] != 0) {
      i++;
    }
    i++;
  }
  if (i >= data.length) return null;
  return Uint8List.fromList(data.sublist(i));
}

TrackTags? _readId3v1(File file) {
  final raf = file.openSync(mode: FileMode.read);
  try {
    final len = raf.lengthSync();
    if (len < 128) return null;
    raf.setPositionSync(len - 128);
    final bytes = raf.readSync(128);
    if (bytes[0] != 0x54 || bytes[1] != 0x41 || bytes[2] != 0x47) {
      return null; // not "TAG"
    }
    String read(int start, int end) =>
        latin1.decode(bytes.sublist(start, end), allowInvalid: true);
    return TrackTags(
      title: _clean(read(3, 33)),
      artist: _clean(read(33, 63)),
      album: _clean(read(63, 93)),
    );
  } finally {
    raf.closeSync();
  }
}
