import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F2D),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(child: _buildMapContent(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A0F2D), Color(0xFF151A3A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            'Карта Б-Корпуса',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          _buildFloorSelector(),
        ],
      ),
    );
  }

  Widget _buildFloorSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.layers_rounded, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            '1 этаж',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildMapContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildLegend(),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF151A3A),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: InteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(100),
                  minScale: 0.05,
                  maxScale: 5.0,
                  constrained: false,
                  child: Container(
                    width: 2000,
                    height: 1200,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E2344), Color(0xFF151A3A)],
                      ),
                    ),
                    child: Stack(
                      children: [
                        _buildGrid(),
                        ..._buildFirstFloorRooms(context),
                        ..._buildCorridors(),
                        ..._buildStairs(),
                        ..._buildToilets(),
                        ..._buildLabels(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildControlsHint(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    final legendItems = [
      _buildLegendItem(const Color(0xFF2E86AB), 'Аудитории'),
      _buildLegendItem(const Color(0xFF00D4AA), 'Лаборатории'),
      _buildLegendItem(const Color(0xFFFFD700), 'Общественные'),
      _buildLegendItem(const Color(0xFFFF6B6B), 'Лестницы'),
      _buildLegendItem(const Color(0xFF4CAF50), 'Туалеты'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151A3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: legendItems),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return CustomPaint(painter: GridPainter());
  }

  List<Widget> _buildFirstFloorRooms(BuildContext context) {
    return [
      // Левое крыло (до лестницы А)
      _buildRoom(context, '101', 'Леционная', 25, 800, const Color(0xFF2E86AB), 150, 100),
      
      // Левое крыло (после лестницы А)
      _buildRoom(context, 'Главный вход', '', 430, 1000, const Color(0xFF2E86AB), 100, 80),
      _buildRoom(context, 'Гардероб', '', 680, 1000, const Color(0xFF2E86AB), 120, 80),
      _buildRoom(context, 'Охрана', '', 580, 1000, const Color(0xFF2E86AB), 80, 80),
      _buildRoom(context, '104', 'Коворкинг', 300, 800, const Color(0xFFFFD700), 200, 120),
      _buildRoom(context, '105', 'Вендинг', 520, 800, const Color(0xFFFFD700), 120, 120),
      _buildRoom(context, '106', 'Мешки', 660, 800, const Color(0xFFFFD700), 100, 120),

      // Правое крыло
      _buildRoom(context, '111', 'Аудитория 111', 920, 1000, const Color(0xFF2E86AB), 100, 80),
      _buildRoom(context, '112', 'Аудитория 112', 1040, 1000, const Color(0xFF2E86AB), 315, 80),
      _buildRoom(context, '114', 'Аудитория 114', 920, 800, const Color(0xFF2E86AB), 120, 120),
      _buildRoom(context, '115', 'Компьютерный класс', 1110, 800, const Color(0xFF00D4AA), 250, 120),
    ];
  }

  List<Widget> _buildCorridors() {
    return [
      _buildCorridor(280, 950, 500, 40),
      _buildCorridor(900, 950, 500, 40),
      _buildCorridor(260, 600, 40, 500),
      _buildCorridor(780, 600, 40, 500),
      _buildCorridor(860, 600, 40, 500),
      _buildCorridor(1380, 600, 40, 500),
    ];
  }

  List<Widget> _buildStairs() {
    return [
      _buildStair('Лестница A', 200, 600, 50, 500),
      _buildStair('Лестница B', 815, 600, 50, 500),
    ];
  }

  List<Widget> _buildToilets() {
    return [
      _buildToilet('М', 1055, 800, 40, 60),
    ];
  }

  List<Widget> _buildLabels() {
    return [
      _buildFloorLabel('1 ЭТАЖ', 800, 950),
      _buildSectionLabel('Левое крыло', 500, 700),
      _buildSectionLabel('Правое крыло', 1100, 700),
    ];
  }

  Widget _buildRoom(BuildContext context, String number, String name, double left, double top, Color color, double width, double height) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => _showRoomInfo(context, name, number),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.25),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(number, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 2),
              Text(name, textAlign: TextAlign.center, style: TextStyle(fontSize: 7, color: Colors.white.withOpacity(0.9), height: 1.1),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCorridor(double left, double top, double width, double height) {
    return Positioned(
      left: left, top: top,
      child: Container(
        width: width, height: height,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  Widget _buildStair(String name, double left, double top, double width, double height) {
    return Positioned(
      left: left, top: top,
      child: Container(
        width: width, height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B6B).withOpacity(0.25),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFF6B6B), width: 1.5),
        ),
        child: RotatedBox(
          quarterTurns: 1,
          child: Center(child: Text(name, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white))),
        ),
      ),
    );
  }

  Widget _buildToilet(String type, double left, double top, double width, double height) {
    return Positioned(
      left: left, top: top,
      child: Container(
        width: width, height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.25),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF4CAF50), width: 1.5),
        ),
        child: Center(child: Text(type, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
      ),
    );
  }

  Widget _buildFloorLabel(String text, double left, double top) {
    return Positioned(
      left: left, top: top,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2E86AB).withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2E86AB), width: 1),
        ),
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildSectionLabel(String text, double left, double top) {
    return Positioned(
      left: left, top: top,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
        child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.8))),
      ),
    );
  }

  Widget _buildControlsHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF151A3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.touch_app_rounded, color: Color(0xFF00D4AA), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Масштабируйте и перемещайтесь по карте. Нажимайте на аудитории для информации.',
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showRoomInfo(BuildContext context, String name, String number) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151A3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Аудитория $number', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(name, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть', style: TextStyle(color: Color(0xFF00D4AA))),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.03)..strokeWidth = 0.5;
    final boldPaint = Paint()..color = Colors.white.withOpacity(0.08)..strokeWidth = 1;

    for (double x = 0; x < 2000; x += 25) {
      canvas.drawLine(Offset(x, 0), Offset(x, 1200), paint);
    }
    for (double y = 0; y < 1200; y += 25) {
      canvas.drawLine(Offset(0, y), Offset(2000, y), paint);
    }
    for (double x = 0; x < 2000; x += 100) {
      canvas.drawLine(Offset(x, 0), Offset(x, 1200), boldPaint);
    }
    for (double y = 0; y < 1200; y += 100) {
      canvas.drawLine(Offset(0, y), Offset(2000, y), boldPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}