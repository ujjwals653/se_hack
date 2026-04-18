import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

class Whiteboard {
  final String id;
  final String name;
  final String createdBy;
  final DateTime createdAt;

  Whiteboard({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
  });

  factory Whiteboard.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Whiteboard(
      id: doc.id,
      name: d['name'] ?? 'Untitled',
      createdBy: d['createdBy'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class WhiteboardStroke {
  final String id;
  final List<Offset> points;
  final int color;
  final double width;
  final String tool; // 'pen' | 'highlighter' | 'eraser' | 'rectangle' | 'circle' | 'line'
  final String? stickyText;
  final int? stickyColor;
  final String uid;
  final DateTime createdAt;

  WhiteboardStroke({
    required this.id,
    required this.points,
    required this.color,
    required this.width,
    required this.tool,
    this.stickyText,
    this.stickyColor,
    required this.uid,
    required this.createdAt,
  });

  factory WhiteboardStroke.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final rawPoints = (d['points'] as List<dynamic>?) ?? [];
    final points = rawPoints.map((p) {
      final m = p as Map<String, dynamic>;
      return Offset((m['x'] as num).toDouble(), (m['y'] as num).toDouble());
    }).toList();

    return WhiteboardStroke(
      id: doc.id,
      points: points,
      color: (d['color'] as num?)?.toInt() ?? 0xFF000000,
      width: (d['width'] as num?)?.toDouble() ?? 4.0,
      tool: d['tool'] ?? 'pen',
      stickyText: d['stickyText'],
      stickyColor: (d['stickyColor'] as num?)?.toInt(),
      uid: d['uid'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'color': color,
      'width': width,
      'tool': tool,
      if (stickyText != null) 'stickyText': stickyText,
      if (stickyColor != null) 'stickyColor': stickyColor,
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
