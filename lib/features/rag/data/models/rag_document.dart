class RagDocument {
  final String id;
  final String name;
  final int chunkCount;
  final int createdAt;
  final String localPath;

  const RagDocument({
    required this.id,
    required this.name,
    required this.chunkCount,
    required this.createdAt,
    this.localPath = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'chunk_count': chunkCount,
        'created_at': createdAt,
        'local_path': localPath,
      };

  factory RagDocument.fromMap(Map<String, dynamic> map) => RagDocument(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        chunkCount: map['chunk_count'] as int? ?? 0,
        createdAt: map['created_at'] as int? ?? 0,
        localPath: map['local_path'] as String? ?? '',
      );
}
