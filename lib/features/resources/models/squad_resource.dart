import 'package:cloud_firestore/cloud_firestore.dart';

class SquadResource {
  final String id;
  final String fileName;
  final String supabasePath;    
  final String supabaseUrl;     
  final String subject;
  final String semester;
  final String uploadedBy;      
  final String uploaderName;
  final DateTime uploadedAt;
  final int fileSizeBytes;
  final String fileType;        

  SquadResource({
    required this.id,
    required this.fileName,
    required this.supabasePath,
    required this.supabaseUrl,
    required this.subject,
    required this.semester,
    required this.uploadedBy,
    required this.uploaderName,
    required this.uploadedAt,
    required this.fileSizeBytes,
    required this.fileType,
  });

  factory SquadResource.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SquadResource(
      id: doc.id,
      fileName: d['fileName'] ?? '',
      supabasePath: d['supabasePath'] ?? '',
      supabaseUrl: d['supabaseUrl'] ?? '',
      subject: d['subject'] ?? '',
      semester: d['semester'] ?? '',
      uploadedBy: d['uploadedBy'] ?? '',
      uploaderName: d['uploaderName'] ?? 'Unknown',
      uploadedAt: (d['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fileSizeBytes: d['fileSizeBytes'] ?? 0,
      fileType: d['fileType'] ?? 'other',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'supabasePath': supabasePath,
      'supabaseUrl': supabaseUrl,
      'subject': subject,
      'semester': semester,
      'uploadedBy': uploadedBy,
      'uploaderName': uploaderName,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'fileSizeBytes': fileSizeBytes,
      'fileType': fileType,
    };
  }
}
