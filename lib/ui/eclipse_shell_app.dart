@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02030A),
      body: Stack(
        children: [
          // 1. Fondo Cósmico con gradiente estilo MoonShell
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF02030A), Color(0xFF050818), Color(0xFF11172F)],
                ),
              ),
            ),
          ),
          // 2. Efecto de Estrellas de fondo
          Positioned.fill(
            child: CustomPaint(
              painter: StarfieldPainter(), 
            ),
          ),
          // 3. Interfaz de ventanas rígidas estilo DS
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Expanded(
                    child: _buildWindow(
                      title: 'MOONSHL FILE EXPLORER',
                      child: _buildFileExplorer(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 280,
                    child: _buildWindow(
                      title: 'PLAYCONTROL',
                      child: _buildPlayControl(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ], // <--- CORCHETE DE CIERRE OBLIGATORIO DEL STACK
      ),
    );
  }