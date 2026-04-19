import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sync_pdf;
import 'package:uuid/uuid.dart';
import 'package:se_hack/core/constants/api_keys.dart';
import 'package:se_hack/features/rag/data/models/rag_chunk.dart';
import 'package:se_hack/features/rag/data/models/rag_document.dart';
import 'package:se_hack/features/rag/data/rag_repository.dart';
import 'package:se_hack/features/rag/domain/text_chunker.dart';

class RagAnswer {
  final String text;
  final List<String> sources;
  RagAnswer({required this.text, required this.sources});
}

class RagService {
  int _keyIndex = 0;

  GenerativeModel get _llm => GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: geminiApiKeysPool[_keyIndex % geminiApiKeysPool.length],
      );

  GenerativeModel get _ocrModel => GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: geminiApiKeysPool[_keyIndex % geminiApiKeysPool.length],
      );

  final RagRepository _repo;
  final TextChunker _chunker;
  final _uuid = const Uuid();

  RagService({
    RagRepository? repo,
    TextChunker? chunker,
  })  : _repo = repo ?? RagRepository(),
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
    
    // Physically copy the file to local safe sandbox storage
    final appDocDir = await getApplicationDocumentsDirectory();
    final ext = p.extension(file.path);
    final localPath = p.join(appDocDir.path, '${docId}${ext}');
    await file.copy(localPath);

    // Simulate fake progress for UI
    if (onProgress != null) {
      for (int i = 0; i < chunkTexts.length; i++) {
        onProgress(i + 1, chunkTexts.length);
        await Future.delayed(const Duration(milliseconds: 10)); // tiny ui delay
      }
    }

    final chunks = List.generate(
      chunkTexts.length,
      (i) => RagChunk(
        docId: docId,
        chunkIndex: i,
        text: chunkTexts[i],
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
      localPath: localPath,
    );
    await _repo.insertDocument(doc);
    return doc;
  }

  // ── Query Pipeline ────────────────────────────────────────────────────────

  Future<RagAnswer> query(String question, {int topK = 5}) async {
    final topChunks = await _repo.searchChunks(question);

    if (topChunks.isEmpty) {
      return RagAnswer(
        text: 'I couldn\'t find any local notes matching your question. Please adjust your query or upload more notes.',
        sources: [],
      );
    }

    final context = topChunks
        .asMap()
        .entries
        .map((e) =>
            '[${e.key + 1}] (from ${e.value.sourceName}):\n${e.value.text}')
        .join('\n\n');

    final prompt =
        '''You are a study assistant. Answer the student\'s question using ONLY the context provided below.
If the answer is not in the context, say "I couldn\'t find this in your notes."
Be concise, clear, and use bullet points where helpful.

CONTEXT:
$context

QUESTION: $question

ANSWER:''';

    final sources = topChunks.map((c) => c.sourceName).toSet().toList();

    int attempts = 0;
    while (attempts < geminiApiKeysPool.length * 2) {
      try {
        final response = await _llm.generateContent([Content.text(prompt)]);
        final answer = response.text ?? "Sorry, I couldn't generate an answer.";
        
        final sources = topChunks.map((c) => c.sourceName).toSet().toList();
        return RagAnswer(text: answer.trim(), sources: sources);
      } catch (e) {
        final errorText = e.toString().toLowerCase();
        if (errorText.contains('quota') || errorText.contains('429') || errorText.contains('retry in')) {
          _keyIndex++;
          attempts++;
          print('Quota exceeded during Query. Rotating API Key (Attempt $attempts)...');
          
          if (_keyIndex % geminiApiKeysPool.length == 0) {
            int delaySeconds = 60;
            final match = RegExp(r'retry in ([\d\.]+)s').firstMatch(errorText);
            if (match != null) {
              delaySeconds = double.parse(match.group(1)!).ceil() + 1;
            }
            return RagAnswer(text: "Gemini is out of quota across all keys.", sources: []);
          } else {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } else {
          // Return EXACT error so we can see why it fails
          return RagAnswer(text: "Gemini API Error: ${e.toString()}", sources: []);
        }
      }
    }
    return RagAnswer(text: "Sorry, I couldn't generate an answer due to rate limits.", sources: []);
  }

  // ── OCR Helpers ───────────────────────────────────────────────────────────

  Future<String> _extractTextFromPdf(File file) async {
    // Completely native local PDF extraction! No more API errors.
    final bytes = await file.readAsBytes();
    final document = sync_pdf.PdfDocument(inputBytes: bytes);
    
    final textExtractor = sync_pdf.PdfTextExtractor(document);
    final text = textExtractor.extractText();
    
    document.dispose();
    return text;
  }

  Future<String> _extractTextFromPdfPageByPage(File file) async {
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
      // 4s gap between pages to respect gemini free tier
      if (i < doc.pagesCount) {
        await Future.delayed(const Duration(seconds: 4));
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
    int attempts = 0;
    while (attempts < geminiApiKeysPool.length * 2) {
      try {
        final res = await _ocrModel.generateContent([content]);
        return res.text ?? '';
      } catch (e) {
        final errorText = e.toString().toLowerCase();
        if (errorText.contains('quota') || errorText.contains('429') || errorText.contains('retry in')) {
          _keyIndex++;
          attempts++;
          print('Quota exceeded during OCR. Rotating API Key (Attempt $attempts)...');
          
          if (_keyIndex % geminiApiKeysPool.length == 0) {
            int delaySeconds = 60;
            final match = RegExp(r'retry in ([\d\.]+)s').firstMatch(errorText);
            if (match != null) {
              delaySeconds = double.parse(match.group(1)!).ceil() + 1;
            }
            print('All keys exhausted! Waiting $delaySeconds seconds before trying again...');
            await Future.delayed(Duration(seconds: delaySeconds));
          } else {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } else {
          rethrow;
        }
      }
    }
    throw Exception('All API keys have exhausted their quota.');
  }
}
