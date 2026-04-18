// Whiteboard placeholder — uses CustomPainter for collaborative drawing.
// Strokes are sent via Socket.io and stored as Firestore snapshots.
import 'package:flutter/material.dart';

class WhiteboardScreen extends StatefulWidget {
  final String squadId;
  const WhiteboardScreen({super.key, required this.squadId});

  @override
  State<WhiteboardScreen> createState() => _WhiteboardScreenState();
}

class _WhiteboardScreenState extends State<WhiteboardScreen> {
  static const Color _primary = Color(0xFF4C4D7B);

  final List<_Stroke> _strokes = [];
  _Stroke? _currentStroke;
  Color _penColor = const Color(0xFF4C4D7B);
  double _strokeWidth = 4.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: const Text(
          '🖊️ Whiteboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => setState(() => _strokes.clear()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Color palette
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ...const [
                  Color(0xFF4C4D7B),
                  Colors.black,
                  Color(0xFFE53935),
                  Color(0xFF2E7D32),
                  Color(0xFFEF6C00),
                  Color(0xFF7B61FF),
                  Colors.white,
                ].map((c) => GestureDetector(
                      onTap: () => setState(() => _penColor = c),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _penColor == c
                                ? const Color(0xFF7B61FF)
                                : Colors.grey.shade300,
                            width: _penColor == c ? 2.5 : 1,
                          ),
                        ),
                      ),
                    )),
                const Spacer(),
                const Text('Size:',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                Slider(
                  value: _strokeWidth,
                  min: 1,
                  max: 20,
                  activeColor: _primary,
                  onChanged: (v) =>
                      setState(() => _strokeWidth = v),
                ),
              ],
            ),
          ),

          // Canvas
          Expanded(
            child: GestureDetector(
              onPanStart: (d) {
                setState(() {
                  _currentStroke = _Stroke(
                    color: _penColor,
                    width: _strokeWidth,
                    points: [d.localPosition],
                  );
                });
              },
              onPanUpdate: (d) {
                setState(() {
                  _currentStroke?.points.add(d.localPosition);
                });
              },
              onPanEnd: (d) {
                if (_currentStroke != null) {
                  setState(() {
                    _strokes.add(_currentStroke!);
                    _currentStroke = null;
                  });
                }
              },
              child: Container(
                color: Colors.grey.shade50,
                child: CustomPaint(
                  painter: _WhiteboardPainter(
                    strokes: _strokes,
                    current: _currentStroke,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stroke {
  final Color color;
  final double width;
  final List<Offset> points;
  _Stroke({required this.color, required this.width, required this.points});
}

class _WhiteboardPainter extends CustomPainter {
  final List<_Stroke> strokes;
  final _Stroke? current;
  _WhiteboardPainter({required this.strokes, this.current});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in [...strokes, if (current != null) current!]) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path()..moveTo(stroke.points[0].dx, stroke.points[0].dy);
      for (var i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WhiteboardPainter old) => true;
}
