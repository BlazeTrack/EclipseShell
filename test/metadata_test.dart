import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:eclipse_shell/utils/metadata.dart';

/// Encodes [size] as a 32-bit synchsafe integer (used by the ID3v2 header).
List<int> _synchsafe(int size) => [
      (size >> 21) & 0x7f,
      (size >> 14) & 0x7f,
      (size >> 7) & 0x7f,
      size & 0x7f,
    ];

/// Encodes [size] as a plain 32-bit big-endian integer (ID3v2.3 frame size).
List<int> _be32(int size) => [
      (size >> 24) & 0xff,
      (size >> 16) & 0xff,
      (size >> 8) & 0xff,
      size & 0xff,
    ];

List<int> _frame(String id, List<int> data) =>
    [...id.codeUnits, ..._be32(data.length), 0, 0, ...data];

void main() {
  test('reads ID3v2.3 title/artist/album and embedded APIC art', () async {
    final pngBytes = Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 1, 2, 3, 4, 5]);

    final tit2 = _frame('TIT2', [0x00, ...'My Song'.codeUnits]);
    final tpe1 = _frame('TPE1', [0x00, ...'My Artist'.codeUnits]);
    final talb = _frame('TALB', [0x00, ...'My Album'.codeUnits]);
    final apic = _frame('APIC', [
      0x00, // ISO-8859-1 encoding
      ...'image/png'.codeUnits, 0x00, // MIME, null-terminated
      0x03, // picture type: front cover
      0x00, // empty description, null-terminated
      ...pngBytes,
    ]);

    final body = [...tit2, ...tpe1, ...talb, ...apic];
    final tag = [
      ...'ID3'.codeUnits, 0x03, 0x00, 0x00, // header: v2.3, no flags
      ..._synchsafe(body.length),
      ...body,
    ];
    // Append some fake audio frame bytes after the tag.
    final fileBytes = [...tag, 0xff, 0xfb, 0x90, 0x00];

    final tmp = File(
        '${Directory.systemTemp.path}/eclipse_meta_test_${DateTime.now().microsecondsSinceEpoch}.mp3');
    tmp.writeAsBytesSync(fileBytes, flush: true);
    addTearDown(() {
      if (tmp.existsSync()) tmp.deleteSync();
    });

    final tags = readTrackTags(tmp.path);

    expect(tags.title, 'My Song');
    expect(tags.artist, 'My Artist');
    expect(tags.album, 'My Album');
    expect(tags.artwork, isNotNull);
    expect(tags.artwork, equals(pngBytes));
  });

  test('returns empty tags for a file with no ID3 metadata', () {
    final tmp = File(
        '${Directory.systemTemp.path}/eclipse_meta_empty_${DateTime.now().microsecondsSinceEpoch}.mp3');
    tmp.writeAsBytesSync([0xff, 0xfb, 0x90, 0x00, 1, 2, 3, 4], flush: true);
    addTearDown(() {
      if (tmp.existsSync()) tmp.deleteSync();
    });

    final tags = readTrackTags(tmp.path);
    expect(tags.title, isNull);
    expect(tags.artwork, isNull);
  });
}
