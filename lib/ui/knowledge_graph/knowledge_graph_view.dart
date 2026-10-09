import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../notebook/models/notebook_models.dart';

class KnowledgeGraphView extends StatefulWidget {
  final void Function(String subjectId, String pageId)? onOpenPage;

  const KnowledgeGraphView({super.key, this.onOpenPage});

  @override
  State<KnowledgeGraphView> createState() => _KnowledgeGraphViewState();
}

class _KnowledgeGraphViewState extends State<KnowledgeGraphView> with SingleTickerProviderStateMixin {
  late AnimationController _physicsController;
  final List<KnowledgeNode> _nodes = [];
  final List<KnowledgeEdge> _edges = [];

  Offset _panOffset = Offset.zero;
  final double _zoomLevel = 1.0;
  KnowledgeNode? _selectedNode;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initGraphData();

    _physicsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_stepPhysics);

    _physicsController.repeat();
  }

  @override
  void dispose() {
    _physicsController.dispose();
    super.dispose();
  }

  void _initGraphData() {
    final rand = Random(42);

    // Seed academic curriculum nodes
    final rawNodes = [
      KnowledgeNode(id: 'c_mech', label: 'Classical Mechanics', category: 'Subject', colorValue: 0xFF1E3A8A),
      KnowledgeNode(id: 'c_calc', label: 'Vector Calculus', category: 'Subject', colorValue: 0xFF2D6A4F),
      KnowledgeNode(id: 'c_em', label: 'Electromagnetism', category: 'Subject', colorValue: 0xFFB91C1C),
      KnowledgeNode(id: 'c_optics', label: 'Wave Optics', category: 'Subject', colorValue: 0xFFD97706),

      KnowledgeNode(id: 'n_kepler', label: 'Kepler\'s Laws', category: 'Theorem', colorValue: 0xFF3B82F6),
      KnowledgeNode(id: 'n_lagrange', label: 'Euler-Lagrange Eq.', category: 'Theorem', colorValue: 0xFF3B82F6),
      KnowledgeNode(id: 'n_hamilton', label: 'Hamiltonian Phase Space', category: 'Formula', colorValue: 0xFF60A5FA),
      KnowledgeNode(id: 'n_stokes', label: 'Stokes\' Theorem', category: 'Theorem', colorValue: 0xFF10B981),
      KnowledgeNode(id: 'n_gauss', label: 'Divergence Theorem', category: 'Theorem', colorValue: 0xFF10B981),
      KnowledgeNode(id: 'n_fourier', label: 'Fourier Decomposition', category: 'Formula', colorValue: 0xFF34D399),
      KnowledgeNode(id: 'n_maxwell', label: 'Maxwell\'s 4 Equations', category: 'Theorem', colorValue: 0xFFEF4444),
      KnowledgeNode(id: 'n_lorentz', label: 'Lorentz Force Law', category: 'Formula', colorValue: 0xFFF87171),
      KnowledgeNode(id: 'n_poynting', label: 'Poynting Energy Vector', category: 'Formula', colorValue: 0xFFFCA5A5),
      KnowledgeNode(id: 'n_huygens', label: 'Huygens-Fresnel Principle', category: 'Theorem', colorValue: 0xFFF59E0B),
      KnowledgeNode(id: 'n_diffract', label: 'Fraunhofer Diffraction', category: 'Formula', colorValue: 0xFFFBBF24),
    ];

    // Distribute nodes randomly around center
    for (var i = 0; i < rawNodes.length; ++i) {
      final angle = (i / rawNodes.length) * 2 * pi;
      final dist = 120.0 + rand.nextDouble() * 180.0;
      rawNodes[i].x = 350 + cos(angle) * dist;
      rawNodes[i].y = 350 + sin(angle) * dist;
      _nodes.add(rawNodes[i]);
    }

    // Connect edges
    _edges.addAll([
      KnowledgeEdge(sourceId: 'c_mech', targetId: 'n_kepler', label: 'governs'),
      KnowledgeEdge(sourceId: 'c_mech', targetId: 'n_lagrange', label: 'generalizes'),
      KnowledgeEdge(sourceId: 'n_lagrange', targetId: 'n_hamilton', label: 'Legendre transform'),
      KnowledgeEdge(sourceId: 'c_calc', targetId: 'n_stokes', label: 'curl integral'),
      KnowledgeEdge(sourceId: 'c_calc', targetId: 'n_gauss', label: 'flux integral'),
      KnowledgeEdge(sourceId: 'c_calc', targetId: 'n_fourier', label: 'orthogonality'),
      KnowledgeEdge(sourceId: 'c_em', targetId: 'n_maxwell', label: 'field equations'),
      KnowledgeEdge(sourceId: 'n_stokes', targetId: 'n_maxwell', label: 'Faraday & Ampere'),
      KnowledgeEdge(sourceId: 'n_gauss', targetId: 'n_maxwell', label: 'Coulomb & Gauss'),
      KnowledgeEdge(sourceId: 'n_maxwell', targetId: 'n_lorentz', label: 'forces'),
      KnowledgeEdge(sourceId: 'n_maxwell', targetId: 'n_poynting', label: 'flux'),
      KnowledgeEdge(sourceId: 'c_optics', targetId: 'n_huygens', label: 'wavefront'),
      KnowledgeEdge(sourceId: 'n_huygens', targetId: 'n_diffract', label: 'interference'),
      KnowledgeEdge(sourceId: 'n_maxwell', targetId: 'c_optics', label: 'EM radiation'),
    ]);
  }

  void _stepPhysics() {
    const kRepulsion = 1800.0;
    const kSpring = 0.035;
    const restLength = 110.0;
    const damping = 0.88;

    // 1. Repulsion between all node pairs
    for (var i = 0; i < _nodes.length; ++i) {
      for (var j = i + 1; j < _nodes.length; ++j) {
        final a = _nodes[i];
        final b = _nodes[j];
        var dx = b.x - a.x;
        var dy = b.y - a.y;
        var dist = sqrt(dx * dx + dy * dy);
        if (dist < 1.0) dist = 1.0;

        final force = kRepulsion / (dist * dist);
        final fx = (dx / dist) * force;
        final fy = (dy / dist) * force;

        a.vx -= fx;
        a.vy -= fy;
        b.vx += fx;
        b.vy += fy;
      }
    }

    // 2. Spring attraction along edges
    final nodeMap = {for (final n in _nodes) n.id: n};
    for (final e in _edges) {
      final a = nodeMap[e.sourceId];
      final b = nodeMap[e.targetId];
      if (a == null || b == null) continue;

      final dx = b.x - a.x;
      final dy = b.y - a.y;
      final dist = sqrt(dx * dx + dy * dy);
      final displacement = dist - restLength;
      final force = kSpring * displacement;

      final fx = (dist > 0.1) ? (dx / dist) * force : 0.0;
      final fy = (dist > 0.1) ? (dy / dist) * force : 0.0;

      a.vx += fx;
      a.vy += fy;
      b.vx -= fx;
      b.vy -= fy;
    }

    // 3. Center gravity pull toward (350, 350)
    for (final n in _nodes) {
      n.vx += (350 - n.x) * 0.005;
      n.vy += (350 - n.y) * 0.005;

      n.vx *= damping;
      n.vy *= damping;

      n.x += n.vx;
      n.y += n.vy;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFBF8F2), // Warm Ivory
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE2DCD0), width: 1.0),
      ),
      child: Container(
        width: 860,
        height: 720,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Top Bar
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1C1E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.gitFork, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Obsidian-Style Knowledge Graph',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B1C1E),
                      ),
                    ),
                    Text(
                      'Interactive topological concept network of curriculum notes',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
                const Spacer(),
                // Search filter
                SizedBox(
                  width: 220,
                  height: 36,
                  child: TextField(
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Filter concepts...',
                      prefixIcon: const Icon(LucideIcons.search, size: 14, color: Color(0xFF9CA3AF)),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2DCD0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2DCD0))),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim().toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 18, color: Color(0xFF6B7280)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: Color(0xFFE2DCD0), height: 24),

            // Graph Interactive Canvas
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GestureDetector(
                  onPanUpdate: (d) {
                    setState(() {
                      _panOffset += d.delta;
                    });
                  },
                  child: Container(
                    color: const Color(0xFFF7F4EE),
                    child: Stack(
                      children: [
                        // Custom Painter for Graph Nodes & Edges
                        CustomPaint(
                          size: Size.infinite,
                          painter: _GraphPainter(
                            nodes: _nodes,
                            edges: _edges,
                            panOffset: _panOffset,
                            zoomLevel: _zoomLevel,
                            selectedNode: _selectedNode,
                            searchQuery: _searchQuery,
                          ),
                        ),

                        // Interactive Node Hit-testing overlay
                        for (final node in _nodes)
                          Positioned(
                            left: _panOffset.dx + node.x * _zoomLevel - 30,
                            top: _panOffset.dy + node.y * _zoomLevel - 30,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedNode = node;
                                });
                              },
                              child: Container(
                                width: 60,
                                height: 60,
                                color: Colors.transparent,
                              ),
                            ),
                          ),

                        // Selected Node Details Card (Bottom-Left)
                        if (_selectedNode != null)
                          Positioned(
                            left: 16,
                            bottom: 16,
                            child: Container(
                              width: 320,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2DCD0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: Color(_selectedNode!.colorValue),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _selectedNode!.category.toUpperCase(),
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Color(_selectedNode!.colorValue),
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () => setState(() => _selectedNode = null),
                                        child: const Icon(LucideIcons.x, size: 14, color: Color(0xFF9CA3AF)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _selectedNode!.label,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B1C1E),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Connected to ${_edges.where((e) => e.sourceId == _selectedNode!.id || e.targetId == _selectedNode!.id).length} related curriculum concepts.',
                                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF6B7280)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final List<KnowledgeNode> nodes;
  final List<KnowledgeEdge> edges;
  final Offset panOffset;
  final double zoomLevel;
  final KnowledgeNode? selectedNode;
  final String searchQuery;

  _GraphPainter({
    required this.nodes,
    required this.edges,
    required this.panOffset,
    required this.zoomLevel,
    this.selectedNode,
    this.searchQuery = '',
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(zoomLevel, zoomLevel);

    final nodeMap = {for (final n in nodes) n.id: n};

    // Draw Edges
    final edgePaint = Paint()
      ..color = const Color(0xFFCBD5E1).withValues(alpha: 0.7)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final activeEdgePaint = Paint()
      ..color = const Color(0xFF1E3A8A)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final e in edges) {
      final a = nodeMap[e.sourceId];
      final b = nodeMap[e.targetId];
      if (a == null || b == null) continue;

      final isEdgeSelected = selectedNode != null && (selectedNode!.id == a.id || selectedNode!.id == b.id);
      canvas.drawLine(Offset(a.x, a.y), Offset(b.x, b.y), isEdgeSelected ? activeEdgePaint : edgePaint);
    }

    // Draw Nodes
    for (final n in nodes) {
      final isSelected = selectedNode?.id == n.id;
      final isMatch = searchQuery.isEmpty || n.label.toLowerCase().contains(searchQuery);

      final radius = n.category == 'Subject' ? 12.0 : 8.0;
      final nodeColor = isMatch
          ? Color(n.colorValue)
          : Color(n.colorValue).withValues(alpha: 0.2);

      // Node Fill
      final fillPaint = Paint()..color = nodeColor;
      canvas.drawCircle(Offset(n.x, n.y), radius, fillPaint);

      // Node Selection Ring
      if (isSelected) {
        final ringPaint = Paint()
          ..color = const Color(0xFF1B1C1E)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(Offset(n.x, n.y), radius + 4, ringPaint);
      }

      // Label
      final textPainter = TextPainter(
        text: TextSpan(
          text: n.label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: n.category == 'Subject' ? 11 : 9.5,
            fontWeight: n.category == 'Subject' ? FontWeight.w700 : FontWeight.w500,
            color: isMatch ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, Offset(n.x - textPainter.width / 2, n.y + radius + 4));
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) => true;
}
