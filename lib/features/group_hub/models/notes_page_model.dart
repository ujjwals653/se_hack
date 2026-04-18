import 'package:cloud_firestore/cloud_firestore.dart';

class NotesPage {
  final String id;
  final String title;
  final String content;
  final String subject;
  final String? lastEditedBy;
  final String? lastEditedByName;
  final DateTime lastEditedAt;

  NotesPage({
    required this.id,
    required this.title,
    required this.content,
    this.subject = '',
    this.lastEditedBy,
    this.lastEditedByName,
    required this.lastEditedAt,
  });

  factory NotesPage.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NotesPage(
      id: doc.id,
      title: d['title'] ?? 'Untitled',
      content: d['content'] ?? '',
      subject: d['subject'] ?? '',
      lastEditedBy: d['lastEditedBy'],
      lastEditedByName: d['lastEditedByName'],
      lastEditedAt: (d['lastEditedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'content': content,
        'subject': subject,
        'lastEditedAt': FieldValue.serverTimestamp(),
      };
}
