import 'package:hive/hive.dart';

part 'cached_resource.g.dart';

@HiveType(typeId: 1)
class CachedResource extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String fileName;
  @HiveField(2) String localPath;
  @HiveField(3) String subject;
  @HiveField(4) String semester;
  @HiveField(5) String uploaderName;
  @HiveField(6) DateTime downloadedAt;
  @HiveField(7) String fileType;
  @HiveField(8) DateTime remoteUpdatedAt;

  CachedResource({
    required this.id, 
    required this.fileName, 
    required this.localPath,
    required this.subject, 
    required this.semester, 
    required this.uploaderName,
    required this.downloadedAt, 
    required this.fileType, 
    required this.remoteUpdatedAt,
  });
}
