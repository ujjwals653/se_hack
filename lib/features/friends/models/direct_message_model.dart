import 'package:cloud_firestore/cloud_firestore.dart';
import '../../group_hub/models/chat_message_model.dart'; 

class DirectMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final MessageType type;
  final bool isDeleted;
  
  // File attachments
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;

  DirectMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.type,
    this.isDeleted = false,
    this.fileUrl,
    this.fileName,
    this.fileSize,
  });

  factory DirectMessage.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DirectMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: MessageType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      isDeleted: data['isDeleted'] ?? false,
      fileUrl: data['fileUrl'],
      fileName: data['fileName'],
      fileSize: (data['fileSize'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type.name,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (fileName != null) 'fileName': fileName,
      if (fileSize != null) 'fileSize': fileSize,
    };
  }
}
