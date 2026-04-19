import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:se_hack/core/constants/api_keys.dart';

/// Generates 768-dimensional text embeddings using Gemini text-embedding-004.
class EmbeddingService {
  int _keyIndex = 0;

  GenerativeModel get _model => GenerativeModel(
    model: 'embedding-001',
    apiKey: geminiApiKeysPool[_keyIndex % geminiApiKeysPool.length],
  );

  Future<List<double>> embedText(String text) async {
    int attempts = 0;
    while (attempts < geminiApiKeysPool.length * 2) {
      try {
        final result = await _model.embedContent(Content.text(text));
        return result.embedding.values;
      } catch (e) {
        final errorText = e.toString().toLowerCase();
        if (errorText.contains('quota') ||
            errorText.contains('429') ||
            errorText.contains('retry in')) {
          _keyIndex++;
          attempts++;

          if (_keyIndex % geminiApiKeysPool.length == 0) {
            int delaySeconds = 60;
            final match = RegExp(r'retry in ([\d\.]+)s').firstMatch(errorText);
            if (match != null) {
              delaySeconds = double.parse(match.group(1)!).ceil() + 1;
            }
            print(
              'All keys exhausted! Waiting $delaySeconds seconds before trying again...',
            );
            await Future.delayed(Duration(seconds: delaySeconds));
          } else {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } else {
          // If it's a model not found or other API error, don't crash loop, just break and fallback to OpenAI directly.
          print('Encountered non-quota Gemini error: $errorText');
          break;
        }
      }
    }

    // If we reach here, all Gemini attempts exhausted or fell back due to API error.
    return _fallbackToOpenAiEmbedding(text);
  }

  Future<List<double>> _fallbackToOpenAiEmbedding(String text) async {
    print('Gemini exhausted, falling back to OpenAI embedding...');
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/embeddings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $openAiApiKey',
      },
      body: jsonEncode({
        'input': text,
        'model': 'text-embedding-3-small',
        'dimensions': 768, // Match Gemini's 768 dimensions!
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final embedding = List<double>.from(
        data['data'][0]['embedding'].map((e) => e.toDouble()),
      );
      return embedding;
    } else {
      throw Exception('OpenAI fallback also failed: ${response.body}');
    }
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
