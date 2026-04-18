/// Centralized Gemini prompts for Lumina AI parsing tasks.

const String kTimetableParsePrompt = '''
You are parsing a university timetable. Extract the weekly schedule as structured JSON.

CRITICAL RULES:

1. LAB SESSION DETECTION:
   A time slot containing multiple subjects listed together
   (e.g., "OS/B/AGN/607-B, DAA/C/SND/604, CCN/D/JS/703-B")
   is ONE lab rotation session, NOT multiple separate lectures.
   - These appear as 2-hour blocks with 3-5 subject+batch combinations stacked in the same cell.
   - Each student attends only ONE of these subjects (they are divided by batch A/B/C/D).
   - Count this entire block as: 1 occurrence of EACH subject listed (one per batch rotation).
   - Do NOT count it as multiple subjects happening simultaneously for the same student.

2. LECTURE SESSION DETECTION:
   A slot with a single subject entry like "DAA / PBB / 508" is a regular lecture.
   - Count this as 1 lecture for ALL students.

3. BATCH LOGIC:
   When you see entries like "DAA / A / NR / 608" and "DAA / B / SND / 604" in the same slot,
   these are the SAME subject for different batches — count it as 1 occurrence, not 2.

4. DEDUPLICATION:
   Each subject should appear AT MOST ONCE per day in the output.
   If a subject appears in multiple slots on the same day (e.g., a lecture AND a lab on Monday),
   still list it only ONCE — what matters is: does this subject meet this day? Yes/No.

5. FREE/BREAK SLOTS:
   Ignore lunch, library, breaks, and self-study slots entirely.
   Do NOT include them as subjects.

6. SUBJECT NAMES:
   Use short codes as they appear in the timetable (e.g., "DAA", "OS", "CCN", "FOM-II", "SMCS").
   Do not expand abbreviations.

7. OUTPUT FORMAT:
   Return ONLY valid JSON, no markdown, no explanation:
   {
     "Mon": ["DAA", "CCN", "OS"],
     "Tue": ["OS", "DAA", "PCS"],
     "Wed": ["CCN", "PCS", "FOM-II"],
     "Thu": ["OS", "DAA", "CCN", "PCS", "SMCS"],
     "Fri": ["OS", "CCN", "FOM-II", "SMCS"],
     "Sat": []
   }

Use exactly these day keys: Mon, Tue, Wed, Thu, Fri, Sat.
If a day has no classes, return an empty array [].
Return ONLY the JSON object, nothing else.
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
