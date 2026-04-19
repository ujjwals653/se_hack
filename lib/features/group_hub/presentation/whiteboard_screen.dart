import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:async';
import 'dart:ui';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import '../data/squad_repository.dart';
import '../models/squad_model.dart';
import '../models/whiteboard_model.dart';

class WhiteboardScreen extends StatefulWidget {
  final String squadId;
  final String uid;
  final SquadRepository repo;
  final String whiteboardId;
  final String whiteboardName;
  final SquadRole myRole;

  const WhiteboardScreen({
    super.key,
    required this.squadId,
    required this.uid,
    required this.repo,
    required this.whiteboardId,
    required this.whiteboardName,
    required this.myRole,
  });

  @override
  State<WhiteboardScreen> createState() => _WhiteboardScreenState();
}

class _WhiteboardScreenState extends State<WhiteboardScreen> {
  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _accent = Color(0xFF7B61FF);

  // Tools
  String _activeTool = 'pen';
  Color _penColor = const Color(0xFF4C4D7B);
  double _strokeWidth = 4.0;
  double _eraserWidth = 20.0;

  // Local undo stack — stores Firestore doc IDs of committed strokes
  final List<String> _myStrokeIds = [];

  // Local drawing state for zero latency
  WhiteboardStroke? _currentStroke;

  // Transformation controller for InteractiveViewer
  final TransformationController _transformCtrl = TransformationController();

  final List<Color> _palette = [
    const Color(0xFF4C4D7B), // primary
    const Color(0xFF1A1A2E), // black/dark
    const Color(0xFFE53935), // red
    const Color(0xFF2E7D32), // green
    const Color(0xFF1565C0), // blue
    const Color(0xFFEF6C00), // orange
    const Color(0xFFF5A623), // amber
    const Color(0xFF7B61FF), // accent
    const Color(0xFF00B4D8), // teal
    const Color(0xFFFFFFFF), // white
  ];

  // Committed strokes from Firestore — updated via stream subscription
  List<WhiteboardStroke> _committedStrokes = [];
  StreamSubscription<List<WhiteboardStroke>>? _strokesSub;

  @override
  void initState() {
    super.initState();
    _strokesSub = widget.repo
        .watchStrokes(widget.squadId, widget.whiteboardId)
        .listen((strokes) {
      if (mounted) setState(() => _committedStrokes = strokes);
    });
  }

  @override
  void dispose() {
    _strokesSub?.cancel();
    _transformCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 1,
        shadowColor: Colors.black12,
        title: Text(
          widget.whiteboardName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo my last stroke',
            onPressed: _myStrokeIds.isEmpty ? null : _undoLocal,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            tooltip: 'Clear board',
            onPressed: () => _confirmClearBoard(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildToolbar(),
          Expanded(
            child: ClipRect(
              child: Stack(
                children: [
                  // Infinite panning canvas — repaints on every setState call
                  InteractiveViewer(
                    transformationController: _transformCtrl,
                    constrained: false,
                    minScale: 0.1,
                    maxScale: 5.0,
                    child: GestureDetector(
                      onPanStart: _handlePanStart,
                      onPanUpdate: _handlePanUpdate,
                      onPanEnd: _handlePanEnd,
                      onTapUp: _activeTool == 'sticky' ? _handleTapUpSticky : null,
                      child: Container(
                        width: 10000,
                        height: 10000,
                        color: Colors.grey.shade50,
                        child: CustomPaint(
                          painter: _WhiteboardPainter(
                            strokes: _committedStrokes,
                            current: _currentStroke,
                          ),
                          size: const Size(10000, 10000),
                        ),
                      ),
                    ),
                  ),

                  // Return to center button
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: FloatingActionButton.small(
                      heroTag: null,
                      backgroundColor: Colors.white,
                      foregroundColor: _primary,
                      onPressed: () {
                        _transformCtrl.value = Matrix4.identity();
                      },
                      child: const Icon(Icons.my_location),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildToolBtn(Icons.edit, 'pen'),
                _buildToolBtn(Icons.brush, 'highlighter'),
                _buildToolBtn(Icons.crop_square, 'rectangle'),
                _buildToolBtn(Icons.radio_button_unchecked, 'circle'),
                _buildToolBtn(Icons.show_chart, 'line'),
                _buildToolBtn(Icons.note_add, 'sticky'),
                Container(width: 1, height: 24, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 8)),
                _buildToolBtn(Icons.cleaning_services, 'eraser'),
              ],
            ),
          ),
          if (_activeTool != 'sticky') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (_activeTool != 'eraser')
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _palette.map((c) => GestureDetector(
                          onTap: () => setState(() => _penColor = c),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _penColor == c ? _accent : Colors.grey.shade300,
                                width: _penColor == c ? 2.5 : 1,
                              ),
                            ),
                          ),
                        )).toList(),
                      ),
                    ),
                  )
                else
                  // Eraser label placeholder so the slider sits nicely
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.cleaning_services, size: 16, color: Colors.grey),
                        SizedBox(width: 6),
                        Text('Eraser', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                const SizedBox(width: 12),
                Text(
                  'Size: ${(_activeTool == 'eraser' ? _eraserWidth : _strokeWidth).toInt()}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                SizedBox(
                  width: 110,
                  child: Slider(
                    value: _activeTool == 'eraser' ? _eraserWidth : _strokeWidth,
                    min: _activeTool == 'eraser' ? 5 : 1,
                    max: _activeTool == 'eraser' ? 60 : 20,
                    activeColor: _activeTool == 'eraser' ? Colors.redAccent : _primary,
                    onChanged: (v) => setState(() {
                      if (_activeTool == 'eraser') {
                        _eraserWidth = v;
                      } else {
                        _strokeWidth = v;
                      }
                    }),
                  ),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _buildToolBtn(IconData icon, String toolId) {
    final active = _activeTool == toolId;
    return GestureDetector(
      onTap: () => setState(() => _activeTool = toolId),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: active ? _accent.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? _accent.withOpacity(0.5) : Colors.transparent),
        ),
        child: Icon(icon, color: active ? _accent : Colors.grey.shade600, size: 22),
      ),
    );
  }

  // -------------------------
  // Interaction Logic
  // -------------------------

  Offset _getCanvasPosition(Offset localPosition) {
    // Convert local tap into infinite canvas coordinates by applying inverse transform
    final RenderBox? rb = context.findRenderObject() as RenderBox?;
    if (rb == null) return localPosition;
    
    // We get points back in local coord space relative to the container.
    // Apply inverse matrix to find absolute position in the 10k x 10k space
    final Matrix4 transform = _transformCtrl.value;
    final Matrix4 inverse = Matrix4.inverted(transform);
    final Vector3 untransformed = inverse.transform3(Vector3(localPosition.dx, localPosition.dy, 0));
    return Offset(untransformed.x, untransformed.y);
  }

  void _handlePanStart(DragStartDetails details) {
    if (_activeTool == 'sticky') return; // Stickies are created via tap

    final pos = _getCanvasPosition(details.localPosition);
    
    setState(() {
      _currentStroke = WhiteboardStroke(
        id: '', // Empty until sent
        points: [pos],
        color: _activeTool == 'eraser' ? 0xFFF5F5F5 : _penColor.value,
        width: _activeTool == 'highlighter'
            ? (_strokeWidth * 3)
            : _activeTool == 'eraser'
                ? _eraserWidth
                : _strokeWidth,
        tool: _activeTool,
        uid: widget.uid,
        createdAt: DateTime.now(),
      );
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_currentStroke == null) return;
    
    final pos = _getCanvasPosition(details.localPosition);
    setState(() {
      _currentStroke!.points.add(pos);
    });
  }

  void _handlePanEnd(DragEndDetails details) async {
    if (_currentStroke == null || _currentStroke!.points.isEmpty) return;

    final strokeToSave = _currentStroke!;
    setState(() => _currentStroke = null);

    // Save to Firestore and capture the doc ID for local undo
    final docId = await widget.repo.addStrokeGetId(
        widget.squadId, widget.whiteboardId, strokeToSave);
    if (docId != null) setState(() => _myStrokeIds.add(docId));
  }

  void _undoLocal() {
    if (_myStrokeIds.isEmpty) return;
    final lastId = _myStrokeIds.removeLast();
    setState(() {}); // update undo button disabled state
    widget.repo.deleteStrokeById(widget.squadId, widget.whiteboardId, lastId);
  }
  void _handleTapUpSticky(TapUpDetails details) async {
    if (_activeTool != 'sticky') return;

    final pos = _getCanvasPosition(details.localPosition);
    
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Sticky Note'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Type your note...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _penColor, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Pin Note'),
          ),
        ],
      )
    );

    if (text != null && text.isNotEmpty) {
      final sticky = WhiteboardStroke(
        id: '',
        points: [pos],
        color: 0x00000000, // Transparent, handled by tool rendering
        width: 1.0,
        tool: 'sticky',
        stickyText: text,
        stickyColor: _penColor.value,
        uid: widget.uid,
        createdAt: DateTime.now(),
      );
      await widget.repo.addStroke(widget.squadId, widget.whiteboardId, sticky);
    }
  }

  void _confirmClearBoard() {
     showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Whiteboard?'),
        content: const Text('This will delete all content on this whiteboard for everyone. It cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.repo.clearAllStrokes(widget.squadId, widget.whiteboardId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

// -------------------------
// Rendering logic
// -------------------------

class _WhiteboardPainter extends CustomPainter {
  final List<WhiteboardStroke> strokes;
  final WhiteboardStroke? current;
  
  _WhiteboardPainter({required this.strokes, this.current});

  @override
  void paint(Canvas canvas, Size size) {
    // We compose the strokes and the current one
    final allStrokes = [...strokes];
    if (current != null) allStrokes.add(current!);

    for (final s in allStrokes) {
      if (s.points.isEmpty) continue;

      if (s.tool == 'sticky') {
        _paintSticky(canvas, s);
        continue;
      }

      final paint = Paint()
        ..color = Color(s.color).withOpacity(s.tool == 'highlighter' ? 0.3 : 1.0)
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      // Handle shapes vs freehand
      if (s.tool == 'pen' || s.tool == 'highlighter' || s.tool == 'eraser') {
        _paintFreehand(canvas, s.points, paint);
      } else if (s.tool == 'rectangle') {
        _paintRect(canvas, s.points, paint);
      } else if (s.tool == 'circle') {
        _paintCircle(canvas, s.points, paint);
      } else if (s.tool == 'line') {
        _paintLine(canvas, s.points, paint);
      }
    }
  }

  void _paintFreehand(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length == 1) {
      canvas.drawPoints(PointMode.points, points, paint);
      return;
    }
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  void _paintRect(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;
    final start = points.first;
    final end = points.last;
    canvas.drawRect(Rect.fromPoints(start, end), paint);
  }

  void _paintCircle(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;
    final start = points.first;
    final end = points.last;
    final radius = (end - start).distance;
    canvas.drawCircle(start, radius, paint);
  }

  void _paintLine(Canvas canvas, List<Offset> points, Paint paint) {
     if (points.length < 2) return;
     final start = points.first;
     final end = points.last;
     canvas.drawLine(start, end, paint);
     // Arrowhead if we wanted to get fancy!
  }

  void _paintSticky(Canvas canvas, WhiteboardStroke s) {
    final pos = s.points.first;
    final paint = Paint()
      ..color = Color(s.stickyColor ?? 0xFFF5A623)
      ..style = PaintingStyle.fill;
    
    // Draw shadow
    canvas.drawRect(
      Rect.fromLTWH(pos.dx + 4, pos.dy + 4, 150, 150),
      Paint()..color = Colors.black12
    );

    // Draw sticky body
    canvas.drawRect(Rect.fromLTWH(pos.dx, pos.dy, 150, 150), paint);

    // Draw text
    if (s.stickyText != null) {
      final textSpan = TextSpan(
        text: s.stickyText,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        maxLines: 5,
      );
      // Give it padding
      textPainter.layout(maxWidth: 130);
      textPainter.paint(canvas, Offset(pos.dx + 10, pos.dy + 10));
    }

    // Folded corner effect
    final cornerPath = Path()
      ..moveTo(pos.dx + 130, pos.dy + 150)
      ..lineTo(pos.dx + 150, pos.dy + 130)
      ..lineTo(pos.dx + 130, pos.dy + 130)
      ..close();
    canvas.drawPath(cornerPath, Paint()..color = Colors.black26);
  }

  @override
  bool shouldRepaint(_WhiteboardPainter old) => true; // simplified update
}
