import 'package:cloud_firestore/cloud_firestore.dart';

enum KanbanColumn { backlog, todo, doing, review, done }

enum TaskPriority { low, medium, high }

class KanbanTask {
  final String id;
  final String title;
  final String description;
  final KanbanColumn column;
  final List<String> assignees;
  final DateTime? dueDate;
  final TaskPriority priority;
  final String createdBy;
  final DateTime createdAt;

  KanbanTask({
    required this.id,
    required this.title,
    required this.description,
    required this.column,
    required this.assignees,
    this.dueDate,
    required this.priority,
    required this.createdBy,
    required this.createdAt,
  });

  factory KanbanTask.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return KanbanTask(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      column: _parseColumn(d['column'] ?? 'backlog'),
      assignees: List<String>.from(d['assignees'] ?? []),
      dueDate: (d['dueDate'] as Timestamp?)?.toDate(),
      priority: _parsePriority(d['priority'] ?? 'medium'),
      createdBy: d['createdBy'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'column': column.name,
        'assignees': assignees,
        'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
        'priority': priority.name,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
      };

  KanbanTask copyWith({KanbanColumn? column}) => KanbanTask(
        id: id,
        title: title,
        description: description,
        column: column ?? this.column,
        assignees: assignees,
        dueDate: dueDate,
        priority: priority,
        createdBy: createdBy,
        createdAt: createdAt,
      );

  static KanbanColumn _parseColumn(String c) {
    switch (c) {
      case 'todo':
        return KanbanColumn.todo;
      case 'doing':
        return KanbanColumn.doing;
      case 'review':
        return KanbanColumn.review;
      case 'done':
        return KanbanColumn.done;
      default:
        return KanbanColumn.backlog;
    }
  }

  static TaskPriority _parsePriority(String p) {
    switch (p) {
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }
}
