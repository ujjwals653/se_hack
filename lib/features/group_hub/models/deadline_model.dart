import 'package:cloud_firestore/cloud_firestore.dart';

class Deadline {
  final String id;
  final String title;
  final String subject;
  final DateTime dueDate;
  final List<String> addedBy;
  final String priority; // "normal" | "squad_priority"
  final DateTime createdAt;

  Deadline({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    required this.addedBy,
    this.priority = 'normal',
    required this.createdAt,
  });

  bool get isSquadPriority => addedBy.length >= 3;
  int get daysLeft => dueDate.difference(DateTime.now()).inDays;
  bool get isOverdue => dueDate.isBefore(DateTime.now());

  factory Deadline.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Deadline(
      id: doc.id,
      title: d['title'] ?? '',
      subject: d['subject'] ?? '',
      dueDate: (d['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      addedBy: List<String>.from(d['addedBy'] ?? []),
      priority: d['priority'] ?? 'normal',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'subject': subject,
        'dueDate': Timestamp.fromDate(dueDate),
        'addedBy': addedBy,
        'priority': priority,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
