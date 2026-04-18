import 'package:cloud_firestore/cloud_firestore.dart';

class MicroChallenge {
  final String id;
  final String title;
  final int targetMinutes;
  final String date; // "YYYY-MM-DD"
  final List<String> completedBy;
  final int coinReward;
  final String status; // "active" | "completed" | "expired"

  MicroChallenge({
    required this.id,
    required this.title,
    required this.targetMinutes,
    required this.date,
    required this.completedBy,
    required this.coinReward,
    required this.status,
  });

  factory MicroChallenge.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MicroChallenge(
      id: doc.id,
      title: d['title'] ?? '',
      targetMinutes: (d['targetMinutes'] as num?)?.toInt() ?? 0,
      date: d['date'] ?? '',
      completedBy: List<String>.from(d['completedBy'] ?? []),
      coinReward: (d['coinReward'] as num?)?.toInt() ?? 15,
      status: d['status'] ?? 'active',
    );
  }
}

class SquadResource {
  final String id;
  final String fileName;
  final String storagePath;
  final String subject;
  final String semester;
  final String uploadedBy;
  final String? uploaderName;
  final DateTime uploadedAt;
  final String fileType; // "pdf" | "image" | "other"

  SquadResource({
    required this.id,
    required this.fileName,
    required this.storagePath,
    required this.subject,
    required this.semester,
    required this.uploadedBy,
    this.uploaderName,
    required this.uploadedAt,
    required this.fileType,
  });

  factory SquadResource.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SquadResource(
      id: doc.id,
      fileName: d['fileName'] ?? '',
      storagePath: d['storagePath'] ?? '',
      subject: d['subject'] ?? '',
      semester: d['semester'] ?? '',
      uploadedBy: d['uploadedBy'] ?? '',
      uploaderName: d['uploaderName'],
      uploadedAt: (d['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fileType: d['fileType'] ?? 'other',
    );
  }
}
