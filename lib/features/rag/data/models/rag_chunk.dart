import 'dart:convert';

class RagChunk {
  final int? id;
  final String docId;
  final int chunkIndex;
  final String text;
  final List<double> embedding;
  final String sourceName;
  final int createdAt;

  const RagChunk({
    this.id,
    required this.docId,
    required this.chunkIndex,
    required this.text,
    required this.embedding,
    required this.sourceName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'doc_id': docId,
        'chunk_index': chunkIndex,
        'text': text,
        'embedding': jsonEncode(embedding),
        'source_name': sourceName,
        'created_at': createdAt,
      };

  factory RagChunk.fromMap(Map<String, dynamic> map) {
    final rawEmb = map['embedding'];
    List<double> emb = [];
    if (rawEmb is String) {
      emb = (jsonDecode(rawEmb) as List).map((e) => (e as num).toDouble()).toList();
    }
    return RagChunk(
      id: map['id'] as int?,
      docId: map['doc_id'] as String? ?? '',
      chunkIndex: map['chunk_index'] as int? ?? 0,
      text: map['text'] as String? ?? '',
      embedding: emb,
      sourceName: map['source_name'] as String? ?? '',
      createdAt: map['created_at'] as int? ?? 0,
    );
  }
}
