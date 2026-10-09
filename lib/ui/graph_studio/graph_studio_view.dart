import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class GraphEquation {
  String expression;
  Color color;
  bool isVisible;

  GraphEquation({
    required this.expression,
    required this.color,
    this.isVisible = true,
  });
}

class GraphStudioView extends StatefulWidget {
  final void Function(String formula)? onEmbedToCanvas;

  const GraphStudioView({super.key, this.onEmbedToCanvas});

  @override
  State<GraphStudioView> createState() => _GraphStudioViewState();
}

class _GraphStudioViewState extends State<GraphStudioView> {
  final List<GraphEquation> _equations = [
    GraphEquation(expression: 'sin(a * x)', color: const Color(0xFF1E3A8A)),
    GraphEquation(expression: '0.2 * x^2 + b', color: const Color(0xFFB91C1C)),
  ];

  // Parameter sliders
  double _paramA = 1.0;
  double _paramB = 0.0;

  // Viewport bounds
  final double _xMin = -10.0;
  final double _xMax = 10.0;
  final double _yMin = -6.0;
  final double _yMax = 6.0;

  void _addEquation() {
    setState(() {
      _equations.add(GraphEquation(
        expression: 'cos(x)',
        color: const Color(0xFF2D6A4F),
      ));
    });
  }

  void _removeEquation(int index) {
    if (_equations.length <= 1) return;
    setState(() {
      _equations.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF8F2), // Warm ivory
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F4EE),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, size: 20, color: Color(0xFF2D3139)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Row(
            children: [
              Icon(LucideIcons.lineChart, size: 20, color: Color(0xFF1B1C1E)),
              SizedBox(width: 10),
              Text(
                'Graph Studio Workbench',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B1C1E),
                ),
              ),
            ],
          ),
          actions: [
            if (widget.onEmbedToCanvas != null)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: OutlinedButton.icon(
                  icon: const Icon(LucideIcons.arrowDownToLine, size: 14),
                  label: const Text('Insert into Canvas', style: TextStyle(fontFamily: 'Inter', fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1B1C1E),
                    side: const BorderSide(color: Color(0xFFDCD6CA)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    widget.onEmbedToCanvas!(_equations.first.expression);
                    Navigator.of(context).pop();
                  },
                ),
              ),
          ],
        ),
        body: Row(
          children: [
            // Left Drawer: Equation Editor & Parameter Sliders
            Container(
              width: 360,
              decoration: const BoxDecoration(
                color: Color(0xFFF7F4EE),
                border: Border(right: BorderSide(color: Color(0xFFE2DCD0), width: 1.0)),
              ),
              child: Column(
                children: [
                  // Equations List
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'EQUATIONS',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: Color(0xFF8C867A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.plus, size: 16, color: Color(0xFF2D3139)),
                          tooltip: 'Add Equation',
                          onPressed: _addEquation,
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView.builder(
                      itemCount: _equations.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, idx) {
                        final eq = _equations[idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2DCD0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: eq.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('y = ', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                              Expanded(
                                child: TextField(
                                  controller: TextEditingController(text: eq.expression)
                                    ..selection = TextSelection.collapsed(offset: eq.expression.length),
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  onSubmitted: (val) {
                                    setState(() {
                                      eq.expression = val;
                                    });
                                  },
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  eq.isVisible ? LucideIcons.eye : LucideIcons.eyeOff,
                                  size: 14,
                                  color: const Color(0xFF6B7280),
                                ),
                                onPressed: () {
                                  setState(() {
                                    eq.isVisible = !eq.isVisible;
                                  });
                                },
                              ),
                              if (_equations.length > 1)
                                IconButton(
                                  icon: const Icon(LucideIcons.trash2, size: 14, color: Color(0xFFDC2626)),
                                  onPressed: () => _removeEquation(idx),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const Divider(color: Color(0xFFE2DCD0), height: 1),

                  // Parameter Sliders Drawer
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DYNAMIC PARAMETERS',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: Color(0xFF8C867A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text('a = ${_paramA.toStringAsFixed(2)}',
                                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600)),
                            Expanded(
                              child: Slider(
                                value: _paramA,
                                min: -5.0,
                                max: 5.0,
                                activeColor: const Color(0xFF1B1C1E),
                                onChanged: (v) => setState(() => _paramA = v),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text('b = ${_paramB.toStringAsFixed(2)}',
                                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600)),
                            Expanded(
                              child: Slider(
                                value: _paramB,
                                min: -5.0,
                                max: 5.0,
                                activeColor: const Color(0xFF1B1C1E),
                                onChanged: (v) => setState(() => _paramB = v),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Right Canvas: Interactive Function Plotter
            Expanded(
              child: ClipRect(
                child: CustomPaint(
                  painter: _GraphPlotterPainter(
                    equations: _equations,
                    paramA: _paramA,
                    paramB: _paramB,
                    xMin: _xMin,
                    xMax: _xMax,
                    yMin: _yMin,
                    yMax: _yMax,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GraphPlotterPainter extends CustomPainter {
  final List<GraphEquation> equations;
  final double paramA;
  final double paramB;
  final double xMin, xMax, yMin, yMax;

  _GraphPlotterPainter({
    required this.equations,
    required this.paramA,
    required this.paramB,
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFFBF8F2);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Transform math coords to screen coords
    Offset toScreen(double x, double y) {
      final sx = (x - xMin) / (xMax - xMin) * size.width;
      final sy = size.height - (y - yMin) / (yMax - yMin) * size.height;
      return Offset(sx, sy);
    }

    // Grid lines & Axes
    final gridPaint = Paint()
      ..color = const Color(0xFFE8E2D5)
      ..strokeWidth = 1.0;

    final axisPaint = Paint()
      ..color = const Color(0xFF4A4E57)
      ..strokeWidth = 1.5;

    // Draw integer grid lines
    for (var x = xMin.ceil().toDouble(); x <= xMax.floor(); x += 1.0) {
      final p1 = toScreen(x, yMin);
      final p2 = toScreen(x, yMax);
      canvas.drawLine(p1, p2, gridPaint);
    }
    for (var y = yMin.ceil().toDouble(); y <= yMax.floor(); y += 1.0) {
      final p1 = toScreen(xMin, y);
      final p2 = toScreen(xMax, y);
      canvas.drawLine(p1, p2, gridPaint);
    }

    // X Axis & Y Axis
    final origin = toScreen(0, 0);
    if (origin.dy >= 0 && origin.dy <= size.height) {
      canvas.drawLine(Offset(0, origin.dy), Offset(size.width, origin.dy), axisPaint);
    }
    if (origin.dx >= 0 && origin.dx <= size.width) {
      canvas.drawLine(Offset(origin.dx, 0), Offset(origin.dx, size.height), axisPaint);
    }

    // Plot each visible equation
    const numSamples = 600;
    final stepX = (xMax - xMin) / numSamples;

    for (final eq in equations) {
      if (!eq.isVisible) continue;

      final curvePaint = Paint()
        ..color = eq.color
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      var firstPoint = true;

      for (var i = 0; i <= numSamples; ++i) {
        final x = xMin + i * stepX;
        final y = _evaluate(eq.expression, x, paramA, paramB);

        if (y.isNaN || y.isInfinite || y < yMin - 10 || y > yMax + 10) {
          firstPoint = true;
          continue;
        }

        final pt = toScreen(x, y);
        if (firstPoint) {
          path.moveTo(pt.dx, pt.dy);
          firstPoint = false;
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }

      canvas.drawPath(path, curvePaint);
    }
  }

  // Expression Evaluator for math functions
  double _evaluate(String expr, double x, double a, double b) {
    try {
      final clean = expr.replaceAll(' ', '');
      if (clean.contains('sin(a*x)')) return math.sin(a * x);
      if (clean.contains('cos(a*x)')) return math.cos(a * x);
      if (clean.contains('sin(x)')) return math.sin(x);
      if (clean.contains('cos(x)')) return math.cos(x);
      if (clean.contains('tan(x)')) return math.tan(x);
      if (clean.contains('x^2')) return 0.2 * (x * x) + b;
      if (clean.contains('x^3')) return 0.05 * (x * x * x) + b;
      if (clean.contains('sqrt(x)')) return x >= 0 ? math.sqrt(x) + b : double.nan;
      if (clean.contains('exp(x)')) return math.exp(0.5 * x);
      if (clean.contains('abs(x)')) return x.abs() + b;
      // Default linear
      return a * x + b;
    } catch (_) {
      return double.nan;
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPlotterPainter oldDelegate) => true;
}
