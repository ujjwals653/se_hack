/// Centralized Gemini prompts for Lumina AI parsing tasks.

const String kTimetableParsePrompt = '''
You are parsing a university timetable image. Extract the weekly schedule as structured JSON.

CRITICAL RULES FOR LAB / BATCH SESSIONS:

1. LAB ROTATION DETECTION:
   A time slot showing multiple subjects with batch codes stacked together
   (e.g., "OS/B/AGN/607-B, DAA/C/SND/604, CCN/D/JS/703-B") is ONE lab rotation block.
   - Each student attends only ONE subject in this block (they are in batch A/B/C/D).
   - Output each subject from that block as a SEPARATE entry with the SAME time slot.
   - Mark each such entry as isFree: false, but use the lab block's start/end time for all.
   - Do NOT list the same subject twice in the same day. If a subject appears in BOTH a lecture
     AND a lab slot on the same day, output it ONCE (the lecture slot takes priority).

2. BATCH DEDUPLICATION:
   If "DAA/A/NR/608" and "DAA/B/SND/604" appear in the same slot for different batches,
   output DAA only once (one entry), not twice.

3. FREE SLOTS:
   Mark lunch, library, breaks, self-study as isFree: true with subject "Free Period".
   Do NOT include them in the list otherwise.

4. SUBJECT NAMES:
   Use the short code exactly as written (e.g. "DAA", "OS", "CCN", "FOM-II", "SMCS").

Return ONLY a valid JSON object (no markdown, no code fences) with this exact structure:
{
  "days": {
    "Mon": [
      {"period": 1, "subject": "CCN", "startTime": "09:00", "endTime": "10:00", "section": "", "isFree": false},
      {"period": 2, "subject": "DAA", "startTime": "10:00", "endTime": "11:00", "section": "", "isFree": false},
      {"period": 3, "subject": "Free Period", "startTime": "13:00", "endTime": "14:00", "section": "", "isFree": true}
    ],
    "Tue": [...],
    "Wed": [...],
    "Thu": [...],
    "Fri": [...],
    "Sat": [...]
  }
}

Additional rules:
- Use 24-hour format for times (e.g. "09:00", "14:30").
- Period numbers start at 1 and increment through the day.
- If a day has no classes, use an empty array [].
- If section/room info is visible, include it in "section".
- Extract ALL days visible in the timetable.
- Return ONLY the JSON object, nothing else.
''';

const String kAcademicCalendarParsePrompt = '''
Analyze this Academic Calendar image. Extract the following information:
1. Semester Start Date
2. Semester End Date
3. Explicit Holidays (festivals, national holidays, bank holidays, etc.)
4. Exam weeks / Exam durations

Return ONLY a valid JSON object matching this exact structure:
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

Rules:
- For any missing dates, estimate from context. If totally missing, use the current year-month-01.
- Do NOT wrap output in Markdown code blocks. Output raw JSON only.
- Include ALL holidays visible on the calendar.
- If exam is a single day, set startDate and endDate to the same date.
''';
