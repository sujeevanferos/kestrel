import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../../core/native_bindings.dart';
import 'models/canvas_item.dart';

enum CanvasTool {
  pen,
  highlighter,
  eraser,
  rectangleSelect,
  lassoSelect,
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

  // Selected item IDs (multi-selection support)
  final Set<String> _selectedItemIds = {};
  Set<String> get selectedItemIds => Set.unmodifiable(_selectedItemIds);
  bool get hasActiveSelection => _selectedItemIds.isNotEmpty;
  String? get selectedItemId => _selectedItemIds.isNotEmpty ? _selectedItemIds.first : null;

  // Selection interaction state
  Offset? _selectionStart;
  Rect? _selectionMarquee;
  Rect? get selectionMarquee => _selectionMarquee;

  final List<Offset> _lassoPoints = [];
  List<Offset> get activeLassoPoints => List.unmodifiable(_lassoPoints);

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
      _activePoints.clear();
      _lassoPoints.clear();
      _selectionMarquee = null;
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
  // MULTI-ELEMENT SELECTION ACTIONS
  // ---------------------------------------------------------------------------

  List<CanvasItem> getSelectedItems() {
    if (_selectedItemIds.isEmpty) {
      return List.unmodifiable(_items); // Fallback to all items if none explicitly selected
    }
    return _items.where((it) => _selectedItemIds.contains(it.id)).toList();
  }

  void clearSelection() {
    if (_selectedItemIds.isNotEmpty) {
      _selectedItemIds.clear();
      for (final it in _items) {
        it.isSelected = false;
      }
      notifyListeners();
    }
  }

  void deleteSelectedItems() {
    if (_selectedItemIds.isEmpty) return;
    _recordSnapshot();
    _items.removeWhere((it) => _selectedItemIds.contains(it.id));
    _selectedItemIds.clear();
    notifyListeners();
  }

  void selectItem(String? id) {
    _selectedItemIds.clear();
    if (id != null) {
      _selectedItemIds.add(id);
    }
    for (final it in _items) {
      it.isSelected = _selectedItemIds.contains(it.id);
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // INTERACTIVE CARD ITEMS MANAGEMENT
  // ---------------------------------------------------------------------------

  void addStickyNote({Offset? position, Color? color, String? text}) {
    _recordSnapshot();
    final centerScene = position ?? (-_panOffset + const Offset(200, 200)) / _zoomLevel;
    final note = StickyNoteItem(
      id: 'note_${DateTime.now().microsecondsSinceEpoch}',
      x: centerScene.dx,
      y: centerScene.dy,
      text: text ?? 'Key Concept...',
      noteColor: color ?? const Color(0xFFFEF3C7),
    );
    _items.add(note);
    selectItem(note.id);
  }

  void addTextBox({Offset? position, String? text}) {
    _recordSnapshot();
    final centerScene = position ?? (-_panOffset + const Offset(200, 200)) / _zoomLevel;
    final tb = TextBoxItem(
      id: 'text_${DateTime.now().microsecondsSinceEpoch}',
      x: centerScene.dx,
      y: centerScene.dy,
      text: text ?? 'Double tap to edit heading or note',
    );
    _items.add(tb);
    selectItem(tb.id);
  }

  void addTable({Offset? position, int rows = 3, int cols = 3}) {
    _recordSnapshot();
    final centerScene = position ?? (-_panOffset + const Offset(200, 200)) / _zoomLevel;
    final table = TableItem(
      id: 'table_${DateTime.now().microsecondsSinceEpoch}',
      x: centerScene.dx,
      y: centerScene.dy,
      rows: rows,
      cols: cols,
      cells: {
        '0,0': 'Variable',
        '0,1': 'Unit',
        '0,2': 'Value',
      },
    );
    _items.add(table);
    selectItem(table.id);
  }

  void addVideoPlayer({required String videoPath, String? title, Offset? position}) {
    _recordSnapshot();
    final centerScene = position ?? (-_panOffset + const Offset(150, 150)) / _zoomLevel;
    final vp = VideoFloatItem(
      id: 'video_${DateTime.now().microsecondsSinceEpoch}',
      x: centerScene.dx,
      y: centerScene.dy,
      videoPath: videoPath,
      title: title ?? 'Lesson Presentation',
    );
    _items.add(vp);
    selectItem(vp.id);
  }

  void updateItemPosition(String id, Offset newPos) {
    for (final it in _items) {
      if (it.id == id) {
        it.x = newPos.dx;
        it.y = newPos.dy;
        notifyListeners();
        return;
      }
    }
  }

  void updateItemSize(String id, double width, double height) {
    for (final it in _items) {
      if (it.id == id) {
        if (it is StickyNoteItem) {
          it.width = width.clamp(120, 800);
          it.height = height.clamp(100, 800);
        } else if (it is TextBoxItem) {
          it.width = width.clamp(100, 900);
          it.height = height.clamp(60, 900);
        } else if (it is VideoFloatItem) {
          it.width = width.clamp(320, 1280);
          it.height = height.clamp(200, 720);
        }
        notifyListeners();
        return;
      }
    }
  }

  void updateStickyNoteText(String id, String newText) {
    for (final it in _items) {
      if (it.id == id && it is StickyNoteItem) {
        it.text = newText;
        notifyListeners();
        return;
      }
    }
  }

  void updateStickyNoteColor(String id, Color newColor) {
    for (final it in _items) {
      if (it.id == id && it is StickyNoteItem) {
        it.noteColor = newColor;
        notifyListeners();
        return;
      }
    }
  }

  void updateTextBox(String id, {String? text, double? fontSize, Color? color, bool? isBold}) {
    for (final it in _items) {
      if (it.id == id && it is TextBoxItem) {
        if (text != null) it.text = text;
        if (fontSize != null) it.fontSize = fontSize;
        if (color != null) it.textColor = color;
        if (isBold != null) it.isBold = isBold;
        notifyListeners();
        return;
      }
    }
  }

  void updateTableCell(String id, int row, int col, String value) {
    for (final it in _items) {
      if (it.id == id && it is TableItem) {
        it.cells['$row,$col'] = value;
        notifyListeners();
        return;
      }
    }
  }

  void deleteItem(String id) {
    _recordSnapshot();
    _items.removeWhere((item) => item.id == id);
    _selectedItemIds.remove(id);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // POINTER EVENT LIFECYCLE (INKING & SELECTION TOOLS)
  // ---------------------------------------------------------------------------

  void onPointerDown(Offset scenePos, double pressure, double tilt) {
    _holdTimer?.cancel();
    _didSnap = false;

    if (_currentTool == CanvasTool.eraser) {
      _eraseAt(scenePos);
      return;
    }

    if (_currentTool == CanvasTool.rectangleSelect) {
      _selectionStart = scenePos;
      _selectionMarquee = Rect.fromPoints(scenePos, scenePos);
      _selectedItemIds.clear();
      for (final it in _items) {
        it.isSelected = false;
      }
      notifyListeners();
      return;
    }

    if (_currentTool == CanvasTool.lassoSelect) {
      _lassoPoints.clear();
      _lassoPoints.add(scenePos);
      _selectedItemIds.clear();
      for (final it in _items) {
        it.isSelected = false;
      }
      notifyListeners();
      return;
    }

    // Default Inking (Pen / Highlighter)
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

    if (_currentTool == CanvasTool.rectangleSelect) {
      if (_selectionStart != null) {
        _selectionMarquee = Rect.fromPoints(_selectionStart!, scenePos);
        notifyListeners();
      }
      return;
    }

    if (_currentTool == CanvasTool.lassoSelect) {
      _lassoPoints.add(scenePos);
      notifyListeners();
      return;
    }

    // Default Inking
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

    if (_currentTool == CanvasTool.rectangleSelect) {
      if (_selectionMarquee != null && _selectionMarquee!.width > 4 && _selectionMarquee!.height > 4) {
        final marquee = _selectionMarquee!;
        for (final item in _items) {
          if (marquee.overlaps(item.boundingBox) || marquee.contains(item.boundingBox.center)) {
            _selectedItemIds.add(item.id);
            item.isSelected = true;
          }
        }
      }
      _selectionMarquee = null;
      _selectionStart = null;
      notifyListeners();
      return;
    }

    if (_currentTool == CanvasTool.lassoSelect) {
      if (_lassoPoints.length > 3) {
        for (final item in _items) {
          if (_isPointInPolygon(item.boundingBox.center, _lassoPoints)) {
            _selectedItemIds.add(item.id);
            item.isSelected = true;
          } else if (item is InkStrokeItem) {
            // Also test individual stroke points
            for (final pt in item.points) {
              if (_isPointInPolygon(Offset(pt.x, pt.y), _lassoPoints)) {
                _selectedItemIds.add(item.id);
                item.isSelected = true;
                break;
              }
            }
          }
        }
      }
      _lassoPoints.clear();
      notifyListeners();
      return;
    }

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

  bool _isPointInPolygon(Offset p, List<Offset> polygon) {
    if (polygon.length < 3) return false;
    var inside = false;
    for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].dx, yi = polygon[i].dy;
      final xj = polygon[j].dx, yj = polygon[j].dy;
      final intersect = ((yi > p.dy) != (yj > p.dy)) &&
          (p.dx < (xj - xi) * (p.dy - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
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
  // UNDO / REDO HISTORY & PERSISTENCE
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
    _selectedItemIds.clear();
    notifyListeners();
  }

  void loadBoard(List<CanvasItem> newItems) {
    _recordSnapshot();
    _items.clear();
    _items.addAll(newItems);
    _selectedItemIds.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> exportBoardJson() {
    return _items.map((it) => it.toJson()).toList();
  }

  void importBoardJson(List<dynamic> jsonList) {
    _recordSnapshot();
    _items.clear();
    _selectedItemIds.clear();
    for (final itemJson in jsonList) {
      if (itemJson is Map<String, dynamic>) {
        final it = deserializeCanvasItem(itemJson);
        if (it != null) _items.add(it);
      }
    }
    notifyListeners();
  }
}
