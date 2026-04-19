import 'package:cloud_firestore/cloud_firestore.dart';

class LabReportMeta {
  final String pdfUrl;
  final String commitSha;
  final DateTime compiledAt;
  final String status;       // 'success' | 'error' | 'compiling'
  final String? error;

  const LabReportMeta({
    required this.pdfUrl,
    required this.commitSha,
    required this.compiledAt,
    required this.status,
    this.error,
  });

  factory LabReportMeta.fromFirestore(Map<String, dynamic> data) {
    return LabReportMeta(
      pdfUrl:     data['pdfUrl']     as String? ?? '',
      commitSha:  data['commitSha']  as String? ?? '',
      compiledAt: (data['compiledAt'] as Timestamp).toDate(),
      status:     data['status']     as String? ?? 'unknown',
      error:      data['error']      as String?,
    );
  }
}

class OverleafPreviewService {
  final _db = FirebaseFirestore.instance;

  // Real-time stream — Flutter UI rebuilds whenever a new compile lands
  Stream<LabReportMeta> watchReport(String repoName) {
    return _db
        .collection('lab_reports')
        .doc(repoName)
        .snapshots()
        .where((snap) => snap.exists)
        .map((snap) => LabReportMeta.fromFirestore(snap.data()!));
  }
}
