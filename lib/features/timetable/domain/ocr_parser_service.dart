import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:se_hack/core/constants/api_keys.dart';
import 'package:se_hack/features/timetable/data/models/academic_calendar.dart';
import 'package:se_hack/features/timetable/data/models/timetable.dart';
import 'package:se_hack/features/timetable/data/models/timetable_entry.dart';

class GeminiParserService {
  late final GenerativeModel _model;

  GeminiParserService() {
    _model = GenerativeModel(model: 'gemini-3.0-flash', apiKey: geminiApiKey);
  }

  /// Main entry point: extract timetable from an image or PDF file path.
  Future<Timetable> parseFile(String filePath, {bool isPdf = false}) async {
    final Uint8List imageBytes;

    if (isPdf) {
      imageBytes = await _renderPdfToImage(filePath);
    } else {
      imageBytes = await File(filePath).readAsBytes();
    }

    return _analyzeWithGemini(imageBytes);
  }

  /// Render first page of PDF to a PNG image.
  Future<Uint8List> _renderPdfToImage(String pdfPath) async {
    final document = await PdfDocument.openFile(pdfPath);
    final page = await document.getPage(1);
    final pageImage = await page.render(
      width: page.width * 2,
      height: page.height * 2,
      format: PdfPageImageFormat.png,
    );
    await page.close();
    await document.close();

    if (pageImage == null) {
      throw Exception('Failed to render PDF page');
    }

    return pageImage.bytes;
  }

  /// Send the image to Gemini and get structured timetable JSON back.
  Future<Timetable> _analyzeWithGemini(Uint8List imageBytes) async {
    final prompt = '''
Analyze this timetable image and extract ALL class information.

Return ONLY a valid JSON    object (no markdown, no code fences) with this exact structure:
{
  "days": {
    "Mon": [
      {"period": 1, "subject": "English", "startTime": "09:00", "endTime": "10:00", "section": "", "isFree": false},
      {"period": 2, "subject": "Free Period", "startTime": "10:00", "endTime": "11:00", "section": "", "isFree": true}
    ],
    "Tue": [...],
    "Wed": [...],
    "Thu": [...],
    "Fri": [...],
    "Sat": [...]
  }
}

Rules:
- Use 24-hour format for times (e.g., "09:00", "14:00")
- Set "isFree": true for free periods, breaks, lunch, library, self-study
- Set "isFree": false for actual classes
- For free periods, set subject to "Free Period"
- Period numbers should start at 1 and increment
- If a day has no classes, use an empty array []
- If section info is visible (like "7A", "Section B"), include it
- Extract ALL days visible in the timetable
- Return ONLY the JSON, nothing else
''';

    final content = Content.multi([
      TextPart(prompt),
      DataPart('image/png', imageBytes),
    ]);

    final response = await _model.generateContent([content]);
    final responseText = response.text;

    if (responseText == null || responseText.isEmpty) {
      throw Exception('Gemini returned empty response');
    }

    return _parseGeminiResponse(responseText);
  }

  /// Parse Gemini's JSON response into a Timetable object.
  Timetable _parseGeminiResponse(String responseText) {
    // Clean up response — remove markdown code fences if present
    String cleaned = responseText.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      throw Exception(
        'Failed to parse Gemini response as JSON: $e\nRaw: $cleaned',
      );
    }

    final now = DateTime.now();
    final days = <String, List<TimetableEntry>>{};

    final daysRaw = json['days'] as Map<String, dynamic>? ?? {};

    for (final dayKey in Timetable.dayKeys) {
      final entries = daysRaw[dayKey] as List<dynamic>? ?? [];
      days[dayKey] = entries.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        return TimetableEntry.fromMap(map);
      }).toList();
    }

    // If no meaningful data, throw to trigger fallback
    final totalEntries = days.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );
    if (totalEntries == 0) {
      throw Exception('No timetable data found in the image');
    }

    return Timetable(
      hasTimetable: true,
      createdAt: now,
      updatedAt: now,
      days: days,
    );
  }

  /// Extracts Academic Calendar information.
  Future<AcademicCalendar> parseAcademicCalendar(
    String filePath, {
    bool isPdf = false,
  }) async {
    final Uint8List imageBytes;
    if (isPdf) {
      // Just render the first page or iterate. For simplicity in academic calendar,
      // often the calendar fits on page 1.
      imageBytes = await _renderPdfToImage(filePath);
    } else {
      imageBytes = await File(filePath).readAsBytes();
    }

    final prompt = '''
Analyze this Academic Calendar image. Extract the following information:
1. Semester Start Date
2. Semester End Date
3. Explicit Holidays (like festivals, national holidays, etc.)
4. Exam weeks / Exam durations

Return ONLY a valid JSON object matching this structure:
{
  "startDate": "YYYY-MM-DD",
  "endDate": "YYYY-MM-DD",
  "holidays": [
    {"name": "Diwali", "date": "YYYY-MM-DD"}
  ],
  "exams": [
    {"name": "Mid-Terms", "startDate": "YYYY-MM-DD", "endDate": "YYYY-MM-DD"}
  ]
}

- For any missing dates, do your best to estimate or derive. If totally missing, return current year-month-01.
- DO NOT wrap in Markdown code blocks (like ```json). Just output the raw JSON text.
''';

    final content = Content.multi([
      TextPart(prompt),
      DataPart('image/png', imageBytes),
    ]);

    final response = await _model.generateContent([content]);
    final responseText = response.text;

    if (responseText == null || responseText.isEmpty) {
      throw Exception('Gemini returned empty response for Academic Calendar');
    }

    String cleaned = responseText.trim();
    if (cleaned.startsWith('```json'))
      cleaned = cleaned.substring(7);
    else if (cleaned.startsWith('```'))
      cleaned = cleaned.substring(3);
    if (cleaned.endsWith('```'))
      cleaned = cleaned.substring(0, cleaned.length - 3);
    cleaned = cleaned.trim();

    try {
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      return AcademicCalendar.fromJson(json);
    } catch (e) {
      throw Exception(
        'Failed to parse Gemini calendar JSON: $e\nRaw: $cleaned',
      );
    }
  }

  void dispose() {
    // No resources to release for Gemini client
  }
}
