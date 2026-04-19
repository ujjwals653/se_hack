import 'dart:convert';

class RagChunk {
  final int? id;
  final String docId;
  final int chunkIndex;
  final String text;
  final String sourceName;
  final int createdAt;
  final List<double> embedding;

  const RagChunk({
    this.id,
    required this.docId,
    required this.chunkIndex,
    required this.text,
    required this.sourceName,
    required this.createdAt,
    this.embedding = const [],
  });

  Map<String, dynamic> toMap() => {
        'doc_id': docId,
        'chunk_index': chunkIndex,
        'text': text,
        'source_name': sourceName,
        'created_at': createdAt,
      };

  factory RagChunk.fromMap(Map<String, dynamic> map) {
    return RagChunk(
      // rowid in FTS5 acts as the id
      id: map['rowid'] as int?,
      docId: map['doc_id'] as String? ?? '',
      chunkIndex: map['chunk_index'] as int? ?? 0,
      text: map['text'] as String? ?? '',
      sourceName: map['source_name'] as String? ?? '',
      createdAt: map['created_at'] as int? ?? 0,
    );
  }
}
