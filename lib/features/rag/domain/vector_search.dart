import 'dart:math';
import 'package:se_hack/features/rag/data/models/rag_chunk.dart';

/// Pure-Dart cosine similarity and top-K retrieval.
class VectorSearch {
  /// Returns a value in [-1, 1]. Higher = more similar.
  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0.0;
    double dot = 0, normA = 0, normB = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    final denom = sqrt(normA) * sqrt(normB);
    return denom == 0 ? 0.0 : dot / denom;
  }

  /// Ranks [corpus] by similarity to [queryEmbedding] and returns the top [k].
  static List<({RagChunk chunk, double score})> topK(
    List<double> queryEmbedding,
    List<RagChunk> corpus, {
    int k = 5,
  }) {
    final scored = corpus
        .map((c) => (chunk: c, score: cosineSimilarity(queryEmbedding, c.embedding)))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored.take(k).toList();
  }
}
