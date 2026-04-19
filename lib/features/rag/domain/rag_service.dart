import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:pdfx/pdfx.dart';
import 'package:uuid/uuid.dart';
import 'package:se_hack/core/constants/api_keys.dart';
import 'package:se_hack/features/rag/data/models/rag_chunk.dart';
import 'package:se_hack/features/rag/data/models/rag_document.dart';
import 'package:se_hack/features/rag/data/rag_repository.dart';
import 'package:se_hack/features/rag/domain/embedding_service.dart';
import 'package:se_hack/features/rag/domain/text_chunker.dart';
import 'package:se_hack/features/rag/domain/vector_search.dart';

class RagAnswer {
  final String text;
  final List<String> sources;
  RagAnswer({required this.text, required this.sources});
}

class RagService {
  // Uses geminiApiKey
  final _llm = GenerativeModel(model: 'gemini-2.0-flash', apiKey: geminiApiKey);
  final _ocrModel = GenerativeModel(model: 'gemini-2.0-flash', apiKey: geminiApiKey);

  final RagRepository _repo;
  final EmbeddingService _embeddings;
  final TextChunker _chunker;
  final _uuid = const Uuid();

  RagService({
    RagRepository? repo,
    EmbeddingService? embeddings,
    TextChunker? chunker,
  })  : _repo = repo ?? RagRepository(),
        _embeddings = embeddings ?? EmbeddingService(),
        _chunker = chunker ?? const TextChunker();

  // ── Documents ────────────────────────────────────────────────────────────

  Future<List<RagDocument>> getDocuments() => _repo.getAllDocuments();

  Future<void> deleteDocument(String docId) => _repo.deleteDocument(docId);

  // ── Ingest Pipeline ───────────────────────────────────────────────────────

  Future<RagDocument> ingestFile(
    File file, {
    bool isPdf = false,
    void Function(int done, int total)? onProgress,
  }) async {
    final text = isPdf
        ? await _extractTextFromPdf(file)
        : await _extractTextFromImage(file);

    if (text.trim().isEmpty) {
      throw Exception('No text could be extracted from the file.');
    }

    final chunkTexts = _chunker.chunk(text);
    if (chunkTexts.isEmpty) {
      throw Exception('File is too short to index.');
    }

    final docId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    // Embed with Gemini text-embedding-004
    final embeddings = await _embeddings.embedBatch(
      chunkTexts,
      onProgress: onProgress,
    );

    final chunks = List.generate(
      chunkTexts.length,
      (i) => RagChunk(
        docId: docId,
        chunkIndex: i,
        text: chunkTexts[i],
        embedding: embeddings[i],
        sourceName: file.path.split(Platform.pathSeparator).last,
        createdAt: now,
      ),
    );
    await _repo.insertChunks(chunks);

    final doc = RagDocument(
      id: docId,
      name: file.path.split(Platform.pathSeparator).last,
      chunkCount: chunks.length,
      createdAt: now,
    );
    await _repo.insertDocument(doc);
    return doc;
  }

  // ── Query Pipeline ────────────────────────────────────────────────────────

  Future<RagAnswer> query(String question, {int topK = 5}) async {
    final queryEmbedding = await _embeddings.embedText(question);

    final allChunks = await _repo.getAllChunks();
    if (allChunks.isEmpty) {
      return RagAnswer(
        text: 'No documents uploaded yet. Please upload a PDF or notes first.',
        sources: [],
      );
    }

    final topChunks = VectorSearch.topK(queryEmbedding, allChunks, k: topK);

    final context = topChunks
        .asMap()
        .entries
        .map((e) =>
            '[${e.key + 1}] (from ${e.value.chunk.sourceName}):\n${e.value.chunk.text}')
        .join('\n\n');

    final prompt =
        '''You are a study assistant. Answer the student\'s question using ONLY the context provided below.
If the answer is not in the context, say "I couldn\'t find this in your notes."
Be concise, clear, and use bullet points where helpful.

CONTEXT:
$context

QUESTION: $question

ANSWER:''';

    final response = await _llm.generateContent([Content.text(prompt)]);
    final answer = response.text ?? "Sorry, I couldn't generate an answer.";

    final sources = topChunks.map((r) => r.chunk.sourceName).toSet().toList();
    return RagAnswer(text: answer.trim(), sources: sources);
  }

  // ── OCR Helpers ───────────────────────────────────────────────────────────

  Future<String> _extractTextFromPdf(File file) async {
    final doc = await PdfDocument.openFile(file.path);
    final buffer = StringBuffer();

    for (int i = 1; i <= doc.pagesCount; i++) {
      final page = await doc.getPage(i);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
      );
      await page.close();
      if (pageImage != null) {
        buffer.writeln(await _ocrImage(pageImage.bytes));
      }
      // 5s gap between pages to respect gemini-2.0-flash 15 RPM free tier strictly
      if (i < doc.pagesCount) {
        await Future.delayed(const Duration(seconds: 5));
      }
    }
    await doc.close();
    return buffer.toString();
  }

  Future<String> _extractTextFromImage(File file) async {
    final bytes = await file.readAsBytes();
    return _ocrImage(bytes);
  }

  Future<String> _ocrImage(Uint8List imageBytes) async {
    const prompt =
        'Extract ALL text from this image. Output only the raw text, no formatting, no explanations.';
    final content = Content.multi([
      TextPart(prompt),
      DataPart('image/png', imageBytes),
    ]);
    final res = await _ocrModel.generateContent([content]);
    return res.text ?? '';
  }
}
