import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class StemUtilitiesDialog extends StatefulWidget {
  const StemUtilitiesDialog({super.key});

  @override
  State<StemUtilitiesDialog> createState() => _StemUtilitiesDialogState();
}

class _StemUtilitiesDialogState extends State<StemUtilitiesDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF7F4EE), // Warm parchment
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE2DCD0), width: 1.0),
      ),
      child: Container(
        width: 680,
        height: 520,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Icon(LucideIcons.cpu, size: 22, color: Color(0xFF1B1C1E)),
                const SizedBox(width: 12),
                const Text(
                  'STEM Utilities & Physics Simulations',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B1C1E),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 18, color: Color(0xFF6B7280)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tab Bar
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: const Color(0xFF1B1C1E),
              unselectedLabelColor: const Color(0xFF6B7280),
              indicatorColor: const Color(0xFF1B1C1E),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(icon: Icon(LucideIcons.orbit, size: 16), text: 'Planetary Orbits'),
                Tab(icon: Icon(LucideIcons.activity, size: 16), text: 'Wave Motion'),
                Tab(icon: Icon(LucideIcons.timer, size: 16), text: 'Harmonic Pendulum'),
                Tab(icon: Icon(LucideIcons.calculator, size: 16), text: 'Scientific Calc'),
                Tab(icon: Icon(LucideIcons.clock, size: 16), text: 'World Clocks'),
              ],
            ),
            const Divider(color: Color(0xFFE2DCD0), height: 1),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _PlanetaryOrbitWidget(),
                  _WaveMotionWidget(),
                  _HarmonicPendulumWidget(),
                  _CalculatorWidget(),
                  _WorldClockWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 1. PLANETARY ORBIT SIMULATOR
// -----------------------------------------------------------------------------
class _PlanetaryOrbitWidget extends StatefulWidget {
  const _PlanetaryOrbitWidget();

  @override
  State<_PlanetaryOrbitWidget> createState() => _PlanetaryOrbitWidgetState();
}

class _PlanetaryOrbitWidgetState extends State<_PlanetaryOrbitWidget> {
  double _time = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      setState(() => _time += 0.04);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OrbitPainter(time: _time),
      size: Size.infinite,
    );
  }
}

class _OrbitPainter extends CustomPainter {
  final double time;
  _OrbitPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Central Sun
    final sunPaint = Paint()..color = const Color(0xFFD97706);
    canvas.drawCircle(Offset(cx, cy), 16, sunPaint);

    // Orbit 1: Inner Planet
    final r1 = 60.0;
    final orbitPaint = Paint()
      ..color = const Color(0xFFE2DCD0)
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(cx, cy), r1, orbitPaint);
    final p1x = cx + r1 * math.cos(time * 1.5);
    final p1y = cy + r1 * math.sin(time * 1.5);
    canvas.drawCircle(Offset(p1x, p1y), 7, Paint()..color = const Color(0xFF1E3A8A));

    // Orbit 2: Outer Planet
    final r2 = 120.0;
    canvas.drawCircle(Offset(cx, cy), r2, orbitPaint);
    final p2x = cx + r2 * math.cos(time * 0.8);
    final p2y = cy + r2 * math.sin(time * 0.8);
    canvas.drawCircle(Offset(p2x, p2y), 10, Paint()..color = const Color(0xFFB91C1C));
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) => true;
}

// -----------------------------------------------------------------------------
// 2. TRAVELING WAVE SIMULATOR
// -----------------------------------------------------------------------------
class _WaveMotionWidget extends StatefulWidget {
  const _WaveMotionWidget();

  @override
  State<_WaveMotionWidget> createState() => _WaveMotionWidgetState();
}

class _WaveMotionWidgetState extends State<_WaveMotionWidget> {
  double _time = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      setState(() => _time += 0.08);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WavePainter(time: _time),
      size: Size.infinite,
    );
  }
}

class _WavePainter extends CustomPainter {
  final double time;
  _WavePainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final wavePaint = Paint()
      ..color = const Color(0xFF1B4965)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (var x = 0.0; x <= size.width; x += 3.0) {
      final y = midY + 45.0 * math.sin(0.03 * x - time);
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => true;
}

// -----------------------------------------------------------------------------
// 3. HARMONIC PENDULUM
// -----------------------------------------------------------------------------
class _HarmonicPendulumWidget extends StatefulWidget {
  const _HarmonicPendulumWidget();

  @override
  State<_HarmonicPendulumWidget> createState() => _HarmonicPendulumWidgetState();
}

class _HarmonicPendulumWidgetState extends State<_HarmonicPendulumWidget> {
  double _time = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      setState(() => _time += 0.05);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final angle = 0.6 * math.sin(_time * 2.5); // theta(t)
    return CustomPaint(
      painter: _PendulumPainter(theta: angle),
      size: Size.infinite,
    );
  }
}

class _PendulumPainter extends CustomPainter {
  final double theta;
  _PendulumPainter({required this.theta});

  @override
  void paint(Canvas canvas, Size size) {
    final pivotX = size.width / 2;
    const pivotY = 40.0;
    const length = 180.0;

    final bobX = pivotX + length * math.sin(theta);
    final bobY = pivotY + length * math.cos(theta);

    // Pivot mount
    canvas.drawCircle(Offset(pivotX, pivotY), 5, Paint()..color = const Color(0xFF1B1C1E));

    // Rod
    final rodPaint = Paint()
      ..color = const Color(0xFF4A4E57)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(pivotX, pivotY), Offset(bobX, bobY), rodPaint);

    // Bob
    canvas.drawCircle(Offset(bobX, bobY), 16, Paint()..color = const Color(0xFF2D6A4F));
  }

  @override
  bool shouldRepaint(covariant _PendulumPainter oldDelegate) => true;
}

// -----------------------------------------------------------------------------
// 4. SCIENTIFIC CALCULATOR
// -----------------------------------------------------------------------------
class _CalculatorWidget extends StatefulWidget {
  const _CalculatorWidget();

  @override
  State<_CalculatorWidget> createState() => _CalculatorWidgetState();
}

class _CalculatorWidgetState extends State<_CalculatorWidget> {
  String _display = '0';
  double? _firstOperand;
  String? _operator;

  void _onKey(String key) {
    setState(() {
      if (key == 'C') {
        _display = '0';
        _firstOperand = null;
        _operator = null;
      } else if (key == '+' || key == '-' || key == '*' || key == '/') {
        _firstOperand = double.tryParse(_display);
        _operator = key;
        _display = '0';
      } else if (key == '=') {
        if (_firstOperand != null && _operator != null) {
          final second = double.tryParse(_display) ?? 0.0;
          double res = 0.0;
          if (_operator == '+') res = _firstOperand! + second;
          if (_operator == '-') res = _firstOperand! - second;
          if (_operator == '*') res = _firstOperand! * second;
          if (_operator == '/') res = second != 0 ? _firstOperand! / second : 0.0;
          _display = res.toStringAsPrecision(6).replaceAll(RegExp(r'\.?0+$'), '');
          _firstOperand = null;
          _operator = null;
        }
      } else {
        if (_display == '0') {
          _display = key;
        } else {
          _display += key;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['7', '8', '9', '/'],
      ['4', '5', '6', '*'],
      ['1', '2', '3', '-'],
      ['0', 'C', '=', '+'],
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2DCD0)),
            ),
            child: Text(
              _display,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B1C1E),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              children: keys.map((row) {
                return Expanded(
                  child: Row(
                    children: row.map((k) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1B1C1E),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: Color(0xFFE2DCD0)),
                              ),
                            ),
                            onPressed: () => _onKey(k),
                            child: Text(k, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 5. WORLD CLOCKS
// -----------------------------------------------------------------------------
class _WorldClockWidget extends StatelessWidget {
  const _WorldClockWidget();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          _clockCard('UTC Universal', now, 0),
          _clockCard('London, UK', now, 1),
          _clockCard('New York, USA', now, -4),
          _clockCard('Tokyo, Japan', now, 9),
        ],
      ),
    );
  }

  Widget _clockCard(String city, DateTime utcNow, int offsetHours) {
    final local = utcNow.add(Duration(hours: offsetHours));
    final timeStr = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}:${local.second.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2DCD0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(city, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF6B7280))),
          const SizedBox(height: 4),
          Text(
            timeStr,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B1C1E),
            ),
          ),
        ],
      ),
    );
  }
}
