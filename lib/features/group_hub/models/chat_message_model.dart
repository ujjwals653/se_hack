import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, code, whiteboard, file }

class ChatMessage {
  final String id;
  final String uid;
  final MessageType type;
  final String content;
  final bool pinned;
  final DateTime createdAt;
  // Display info
  String? senderName;
  String? senderPhoto;

  ChatMessage({
    required this.id,
    required this.uid,
    required this.type,
    required this.content,
    this.pinned = false,
    required this.createdAt,
    this.senderName,
    this.senderPhoto,
  });

  factory ChatMessage.fromMap(String id, Map<String, dynamic> d) {
    return ChatMessage(
      id: id,
      uid: d['uid'] ?? '',
      type: _parseType(d['type'] ?? 'text'),
      content: d['content'] ?? '',
      pinned: d['pinned'] ?? false,
      createdAt: d['createdAt'] is Timestamp
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(d['createdAt'] ?? '') ?? DateTime.now(),
      senderName: d['senderName'],
      senderPhoto: d['senderPhoto'],
    );
  }

  factory ChatMessage.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatMessage.fromMap(doc.id, d);
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'type': type.name,
        'content': content,
        'pinned': pinned,
        'createdAt': FieldValue.serverTimestamp(),
      };

  static MessageType _parseType(String t) {
    switch (t) {
      case 'code':
        return MessageType.code;
      case 'whiteboard':
        return MessageType.whiteboard;
      case 'file':
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }
}
