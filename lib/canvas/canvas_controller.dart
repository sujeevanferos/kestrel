import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../../core/native_bindings.dart';
import 'models/canvas_item.dart';

enum CanvasTool {
  pen,
  highlighter,
  eraser,
  lasso,
}

enum PaperStyle {
  ivoryPlain,
  engineeringGrid,
  dotGrid,
  darkChalkboard,
}

class CanvasController extends ChangeNotifier {
  final List<CanvasItem> _items = [];
  final List<List<CanvasItem>> _undoStack = [];
  final List<List<CanvasItem>> _redoStack = [];

  List<CanvasItem> get items => List.unmodifiable(_items);

  // Inking state
  CanvasTool _currentTool = CanvasTool.pen;
  Color _currentColor = const Color(0xFF1B1C1E); // Archival Carbon Black
  double _strokeWidth = 3.0;
  PaperStyle _paperStyle = PaperStyle.ivoryPlain;

  CanvasTool get currentTool => _currentTool;
  Color get currentColor => _currentColor;
  double get strokeWidth => _strokeWidth;
  PaperStyle get paperStyle => _paperStyle;

  // Viewport transformation
  Offset _panOffset = Offset.zero;
  double _zoomLevel = 1.0;

  Offset get panOffset => _panOffset;
  double get zoomLevel => _zoomLevel;

  // Current live stroke in progress
  final List<StrokePoint> _activePoints = [];
  List<StrokePoint> get activePoints => List.unmodifiable(_activePoints);

  // Hold-to-Snap state machine
  Timer? _holdTimer;
  StrokePoint? _holdAnchorPoint;
  bool _didSnap = false;
  static const int holdDurationMs = 250;
  static const double holdMoveThresholdPx = 6.0;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void setTool(CanvasTool tool) {
    if (_currentTool != tool) {
      _currentTool = tool;
      notifyListeners();
    }
  }

  void setColor(Color color) {
    if (_currentColor != color) {
      _currentColor = color;
      notifyListeners();
    }
  }

  void setStrokeWidth(double width) {
    _strokeWidth = width.clamp(1.0, 32.0);
    notifyListeners();
  }

  void setPaperStyle(PaperStyle style) {
    if (_paperStyle != style) {
      _paperStyle = style;
      notifyListeners();
    }
  }

  void updatePanAndZoom(Offset deltaPan, double scaleMultiplier, Offset focalPoint) {
    final oldZoom = _zoomLevel;
    final newZoom = (_zoomLevel * scaleMultiplier).clamp(0.1, 5.0);
    
    // Zoom toward focal point
    _panOffset = focalPoint - (focalPoint - _panOffset) * (newZoom / oldZoom) + deltaPan;
    _zoomLevel = newZoom;
    notifyListeners();
  }

  void resetZoom() {
    _panOffset = Offset.zero;
    _zoomLevel = 1.0;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // POINTER STROKE EVENT LIFECYCLE
  // ---------------------------------------------------------------------------

  void onPointerDown(Offset scenePos, double pressure, double tilt) {
    _holdTimer?.cancel();
    _didSnap = false;

    if (_currentTool == CanvasTool.eraser) {
      _eraseAt(scenePos);
      return;
    }

    final pt = StrokePoint(
      x: scenePos.dx,
      y: scenePos.dy,
      pressure: pressure,
      tilt: tilt,
      timestamp: DateTime.now().millisecondsSinceEpoch.toDouble(),
    );

    _activePoints.clear();
    _activePoints.add(pt);
    _holdAnchorPoint = pt;

    // Start hold timer
    _holdTimer = Timer(const Duration(milliseconds: holdDurationMs), () {
      _checkHoldToSnap();
    });

    notifyListeners();
  }

  void onPointerMove(Offset scenePos, double pressure, double tilt) {
    if (_currentTool == CanvasTool.eraser) {
      _eraseAt(scenePos);
      return;
    }

    final pt = StrokePoint(
      x: scenePos.dx,
      y: scenePos.dy,
      pressure: pressure,
      tilt: tilt,
      timestamp: DateTime.now().millisecondsSinceEpoch.toDouble(),
    );

    _activePoints.add(pt);

    // Check if movement exceeds threshold to reset hold timer
    if (_holdAnchorPoint != null) {
      final dx = pt.x - _holdAnchorPoint!.x;
      final dy = pt.y - _holdAnchorPoint!.y;
      if ((dx * dx + dy * dy) > (holdMoveThresholdPx * holdMoveThresholdPx)) {
        _holdTimer?.cancel();
        _holdAnchorPoint = pt;
        _holdTimer = Timer(const Duration(milliseconds: holdDurationMs), () {
          _checkHoldToSnap();
        });
      }
    }

    notifyListeners();
  }

  void onPointerUp() {
    _holdTimer?.cancel();

    if (_activePoints.isEmpty) return;

    if (!_didSnap && _currentTool != CanvasTool.eraser) {
      // Check for snap on release if stroke was held at the end
      if (_holdAnchorPoint != null) {
        final last = _activePoints.last;
        final dx = last.x - _holdAnchorPoint!.x;
        final dy = last.y - _holdAnchorPoint!.y;
        if ((dx * dx + dy * dy) <= (holdMoveThresholdPx * holdMoveThresholdPx)) {
          _checkHoldToSnap();
        }
      }

      if (!_didSnap) {
        // Commit smoothed freehand stroke
        _recordSnapshot();
        final smoothed = NativeCore.instance.smoothStroke(_activePoints);
        final strokeItem = InkStrokeItem(
          id: 'stroke_${DateTime.now().microsecondsSinceEpoch}',
          points: smoothed,
          color: _currentColor,
          strokeWidth: _strokeWidth,
          isHighlighter: _currentTool == CanvasTool.highlighter,
        );
        _items.add(strokeItem);
      }
    }

    _activePoints.clear();
    _holdAnchorPoint = null;
    _didSnap = false;
    notifyListeners();
  }

  void _checkHoldToSnap() {
    if (_activePoints.length < 5 || _didSnap) return;

    final shape = NativeCore.instance.classifyStroke(_activePoints);
    if (shape.type != KestrelShapeType.handwriting && shape.confidence >= 0.85) {
      _didSnap = true;
      _recordSnapshot();

      SmartShapeCanvasItem? shapeItem;
      final id = 'shape_${DateTime.now().microsecondsSinceEpoch}';

      switch (shape.type) {
        case KestrelShapeType.line:
          shapeItem = SmartShapeCanvasItem(
            id: id,
            shapeType: KestrelShapeType.line,
            bounds: Rect.fromLTRB(shape.minX, shape.minY, shape.minX + shape.width, shape.minY + shape.height),
            strokeColor: _currentColor,
            strokeWidth: _strokeWidth,
            p1: Offset(shape.p1X, shape.p1Y),
            p2: Offset(shape.p2X, shape.p2Y),
          );
          break;

        case KestrelShapeType.arrow:
          shapeItem = SmartShapeCanvasItem(
            id: id,
            shapeType: KestrelShapeType.arrow,
            bounds: Rect.fromLTRB(shape.minX, shape.minY, shape.minX + shape.width, shape.minY + shape.height),
            strokeColor: _currentColor,
            strokeWidth: _strokeWidth,
            p1: Offset(shape.p1X, shape.p1Y),
            p2: Offset(shape.p2X, shape.p2Y),
            arrowHeadAtP2: shape.arrowHeadAtP2,
          );
          break;

        case KestrelShapeType.circle:
        case KestrelShapeType.ellipse:
        case KestrelShapeType.rectangle:
        case KestrelShapeType.square:
          shapeItem = SmartShapeCanvasItem(
            id: id,
            shapeType: shape.type,
            bounds: Rect.fromLTWH(shape.minX, shape.minY, shape.width, shape.height),
            strokeColor: _currentColor,
            strokeWidth: _strokeWidth,
          );
          break;

        case KestrelShapeType.triangle:
        case KestrelShapeType.cloud:
          shapeItem = SmartShapeCanvasItem(
            id: id,
            shapeType: shape.type,
            bounds: Rect.fromLTWH(shape.minX, shape.minY, shape.width, shape.height),
            strokeColor: _currentColor,
            strokeWidth: _strokeWidth,
            vertices: shape.vertices,
          );
          break;

        default:
          break;
      }

      if (shapeItem != null) {
        _items.add(shapeItem);
        _activePoints.clear();
        notifyListeners();
      }
    }
  }

  void _eraseAt(Offset scenePos) {
    const eraseRadius = 18.0;
    final toRemove = <CanvasItem>[];

    for (final item in _items) {
      if (item.boundingBox.inflate(eraseRadius).contains(scenePos)) {
        toRemove.add(item);
      }
    }

    if (toRemove.isNotEmpty) {
      _recordSnapshot();
      _items.removeWhere(toRemove.contains);
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // UNDO / REDO HISTORY
  // ---------------------------------------------------------------------------

  void _recordSnapshot() {
    _undoStack.add(List.of(_items));
    if (_undoStack.length > 50) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void undo() {
    if (!canUndo) return;
    _redoStack.add(List.of(_items));
    final prev = _undoStack.removeLast();
    _items.clear();
    _items.addAll(prev);
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _undoStack.add(List.of(_items));
    final next = _redoStack.removeLast();
    _items.clear();
    _items.addAll(next);
    notifyListeners();
  }

  void clearCanvas() {
    if (_items.isEmpty) return;
    _recordSnapshot();
    _items.clear();
    notifyListeners();
  }
}
