// lib/core/constants/prompts.dart
// Lumina — AI Prompts for extracting data from PDFs

const String timetableExtractionPrompt = """
You are a timetable parser for an Indian engineering college app.

I will give you a college timetable PDF.
Parse it and return ONLY a valid JSON object — no markdown, no explanation, no backticks.

Rules:
- Extract each unique lecture slot per day
- A slot format is usually: SUBJECT / BATCH / TEACHER / ROOM
- If a slot has multiple batch entries, extract ALL of them separately
- Expand short subject codes into full names if visible anywhere in the document
- Days are typically Monday to Friday or Monday to Saturday
- Ignore rows like BREAK, SHORT-BREAK, STUDENT ACTIVITY, LUNCH

Return this exact JSON structure:
{
  "semester": "",
  "division": "",
  "effective_from": "",
  "schedule": {
    "monday": [
      {
        "start": "",
        "end": "",
        "subject_code": "",
        "subject_name": "",
        "teacher": "",
        "room": "",
        "batch": ""
      }
    ],
    "tuesday": [],
    "wednesday": [],
    "thursday": [],
    "friday": []
  }
}
""";

const String calendarExtractionPrompt = """
You are an academic calendar parser for an Indian engineering college app.

I will give you an academic calendar PDF.
Parse it and return ONLY a valid JSON object — no markdown, no explanation, no backticks.

Extract whatever is present in the document:
- Semester start and end dates
- All holidays with dates and names
- All important events with dates
- Total instructional days per weekday if mentioned
- Exam schedules if mentioned

Return this exact JSON structure:
{
  "academic_year": "",
  "semester": "",
  "semester_start": "",
  "semester_end": "",
  "ese_start": "",
  "ese_end": "",
  "total_instructional_days": {
    "monday": 0,
    "tuesday": 0,
    "wednesday": 0,
    "thursday": 0,
    "friday": 0,
    "total": 0
  },
  "holidays": [
    {
      "date": "",
      "day": "",
      "name": ""
    }
  ],
  "special_days": [
    {
      "date": "",
      "description": ""
    }
  ],
  "events": [
    {
      "date": "",
      "description": ""
    }
  ]
}
""";
