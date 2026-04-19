import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:se_hack/core/constants/api_keys.dart';

/// Generates 768-dimensional text embeddings using Gemini text-embedding-004.
class EmbeddingService {
  // Uses geminiApiKey
  final _model = GenerativeModel(
    model: 'text-embedding-004',
    apiKey: geminiApiKey,
  );

  /// Embeds a single text string. Returns a 768-dim float list.
  Future<List<double>> embedText(String text) async {
    final result = await _model.embedContent(Content.text(text));
    return result.embedding.values;
  }

  /// Embeds a list of texts one-by-one, reporting progress each step.
  Future<List<List<double>>> embedBatch(
    List<String> texts, {
    int batchSize = 20, // kept for API compat
    void Function(int done, int total)? onProgress,
  }) async {
    final results = <List<double>>[];
    for (int i = 0; i < texts.length; i++) {
      results.add(await embedText(texts[i]));
      onProgress?.call(i + 1, texts.length);
      // Small delay to stay within free-tier rate limits (100 RPM for text-embedding-004)
      if (i < texts.length - 1) {
        await Future.delayed(const Duration(milliseconds: 400));
      }
    }
    return results;
  }
}
