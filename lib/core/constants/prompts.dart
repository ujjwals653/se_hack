/// Centralized Gemini prompts for Lumina AI parsing tasks.

const String kTimetableParsePrompt = '''
You are parsing a university timetable image. Extract the weekly schedule as structured JSON.

═══════════════════════════════════════════════════
SECTION A — HOW TO IDENTIFY A LAB ROTATION BLOCK
═══════════════════════════════════════════════════

A lab rotation block looks like this in a single cell (stacked vertically):
  OS / B / AGN / 607-B
  DAA / C / SND / 604
  CCN / D / JS / 703-B
  PCS / A / KT / 604

Key markers:
  - 3 or more subject codes with batch letters (A/B/C/D) and room numbers in the SAME cell
  - The cell spans 2 consecutive hours (e.g., 11:00–13:00)

═══════════════════════════════════════════════════
SECTION B — WHAT TO DO WITH A LAB ROTATION BLOCK
═══════════════════════════════════════════════════

RULE: Replace the ENTIRE lab rotation block with ONE single entry:
  {
    "period": <next period number>,
    "subject": "Compulsory Lab",
    "startTime": "<block start, e.g. 11:00>",
    "endTime": "<block end — 2 hours later, e.g. 13:00>",
    "section": "",
    "isFree": false,
    "isLab": true
  }

CRITICAL — DO NOT:
  ✗ Output OS, DAA, CCN, PCS as separate entries for this block
  ✗ Output the lab subjects again elsewhere on the SAME day
  ✗ Shrink the lab entry to 1 hour — it is always a 2-HOUR block
  ✗ Add any individual subject from this cell as a standalone lecture on this day

═══════════════════════════════════════════════════
SECTION C — REGULAR LECTURES
═══════════════════════════════════════════════════

A regular lecture looks like: "DAA / PBB / 508"  or  "CCN / SR / 603"
  → A single subject, faculty, and room.
  → Output normally with "isLab": false.

If two entries in the SAME slot differ only by batch (e.g., "DAA/A/NR" and "DAA/B/SND"):
  → They are the same lecture split by batch. Output DAA once as a regular lecture.

═══════════════════════════════════════════════════
SECTION D — WORKED EXAMPLE (Wednesday)
═══════════════════════════════════════════════════

Suppose Wednesday shows:
  09:00-10:00 →  CCN / SR / 603          (regular lecture)
  10:00-11:00 →  DAA / PBB / 508         (regular lecture)
  11:00-13:00 →  OS/B/AGN/607, DAA/C/SND/604, CCN/D/JS/703, PCS/A/KT/604   (lab rotation)
  13:00-14:00 →  Lunch

CORRECT output for Wednesday:
  [
    {"period":1,"subject":"CCN","startTime":"09:00","endTime":"10:00","section":"","isFree":false,"isLab":false},
    {"period":2,"subject":"DAA","startTime":"10:00","endTime":"11:00","section":"","isFree":false,"isLab":false},
    {"period":3,"subject":"Compulsory Lab","startTime":"11:00","endTime":"13:00","section":"","isFree":false,"isLab":true},
    {"period":4,"subject":"Free Period","startTime":"13:00","endTime":"14:00","section":"","isFree":true,"isLab":false}
  ]

WRONG — do NOT output like this:
  [CCN, DAA, OS, DAA(lab), CCN(lab), PCS] ← inflated, lab subjects leaked as lectures

═══════════════════════════════════════════════════
SECTION E — FREE / BREAK PERIODS
═══════════════════════════════════════════════════

Lunch, library, self-study, breaks:
  → "subject": "Free Period", "isFree": true, "isLab": false

═══════════════════════════════════════════════════
SECTION F — OUTPUT FORMAT
═══════════════════════════════════════════════════

Return ONLY a valid JSON object — no markdown, no code fences, no explanation.

{
  "days": {
    "Mon": [ ... ],
    "Tue": [ ... ],
    "Wed": [ ... ],
    "Thu": [ ... ],
    "Fri": [ ... ],
    "Sat": [ ... ]
  }
}

Each entry: {"period": int, "subject": string, "startTime": "HH:MM", "endTime": "HH:MM", "section": string, "isFree": bool, "isLab": bool}

- Times in 24-hour format
- Period numbers start at 1 and increment per day
- Empty days → []
- Return ONLY the JSON object, nothing else
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
