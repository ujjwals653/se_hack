import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:se_hack/core/constants/api_keys.dart';
import 'package:se_hack/core/constants/prompts.dart';
import 'package:se_hack/features/timetable/data/models/academic_calendar.dart';
import 'package:se_hack/features/timetable/data/models/timetable.dart';
import 'package:se_hack/features/timetable/data/models/timetable_entry.dart';

class GeminiParserService {
  late final GenerativeModel _model;

  GeminiParserService() {
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: geminiApiKey);
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
    final content = Content.multi([
      TextPart(kTimetableParsePrompt),
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
  /// Supports both the new {Mon:["DAA","CCN"]} format and old full-entry format.
  Timetable _parseGeminiResponse(String responseText) {
    // Clean markdown fences if present
    String cleaned = responseText.trim();
    if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
    else if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
    if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
    cleaned = cleaned.trim();

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to parse Gemini response as JSON: $e\nRaw: $cleaned');
    }

    final now = DateTime.now();
    final days = <String, List<TimetableEntry>>{};

    // Detect which format Gemini returned:
    // New format: {"Mon": ["DAA", "CCN"]} — simple list of subject strings
    // Old format: {"days": {"Mon": [{period, subject, startTime, ...}]}}
    final hasDaysWrapper = json.containsKey('days');
    final daysRaw = (hasDaysWrapper
        ? json['days'] as Map<String, dynamic>?
        : json) ?? {};

    for (final dayKey in Timetable.dayKeys) {
      final rawList = daysRaw[dayKey];

      if (rawList == null) {
        days[dayKey] = [];
        continue;
      }

      if (rawList is List && rawList.isNotEmpty && rawList.first is String) {
        // NEW FORMAT: list of subject name strings
        // Dedup: if Gemini repeats a subject for the same day, collapse to 1
        final seen = <String>{};
        final entries = <TimetableEntry>[];
        int period = 1;
        for (final subjectName in rawList) {
          if (subjectName is String && subjectName.isNotEmpty && seen.add(subjectName)) {
            entries.add(TimetableEntry(
              period: period++,
              subject: subjectName,
              startTime: '',
              endTime: '',
              section: '',
              isFree: false,
            ));
          }
        }
        days[dayKey] = entries;
      } else if (rawList is List) {
        // OLD FORMAT: list of full entry maps
        final entries = rawList.map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          return TimetableEntry.fromMap(map);
        }).toList();

        // Dedup guard: collapse duplicate subjects on the same day
        final seen = <String>{};
        days[dayKey] = entries.where((e) {
          if (e.isFree) return true; // keep free periods as-is
          return seen.add(e.subject);
        }).toList();
      } else {
        days[dayKey] = [];
      }
    }

    final totalEntries = days.values.fold<int>(0, (sum, list) => sum + list.length);
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

    final content = Content.multi([
      TextPart(kAcademicCalendarParsePrompt),
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
