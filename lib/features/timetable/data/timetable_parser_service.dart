// lib/features/timetable/data/timetable_parser_service.dart
// Lumina — AI parser using Gemini to parse timetables

import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/constants/env.dart';
import '../../../core/constants/prompts.dart';

class TimetableParserService {
  static Future<Map<String, dynamic>> parseTimetablePdf(File pdfFile) async {
    if (Env.geminiApiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY is not set. Compile with --dart-define=GEMINI_API_KEY=...');
    }

    final model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: Env.geminiApiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );

    final bytes = await pdfFile.readAsBytes();

    final promptAndDoc = [
      Content.multi([
        TextPart(timetableExtractionPrompt),
        DataPart('application/pdf', bytes),
      ])
    ];

    try {
      final response = await model.generateContent(promptAndDoc);
      
      if (response.text == null || response.text!.isEmpty) {
        throw Exception("Gemini returned an empty response.");
      }

      // Safe parse the returned JSON string
      final Map<String, dynamic> parsedJson = jsonDecode(response.text!);
      return parsedJson;
    } catch (e) {
      throw Exception('Failed to extract timetable data via AI: $e');
    }
  }
}
