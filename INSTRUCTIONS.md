# 🤖 INSTRUCTIONS.md — For AI Agents Working on Lumina

> Read this entire file before writing a single line of code.
> This is the source of truth for architecture, conventions, and non-negotiable decisions.
> **Never insert placeholder values, TODO comments, or stub implementations without flagging them explicitly.**

---

## 0. Prime Directives

1. **No placeholders.** Never write `// TODO: implement`, `YOUR_API_KEY`, `/* add logic here */`, or stub functions that silently return empty/null. If you cannot implement something fully, say so in a code comment that starts with `// AGENT_INCOMPLETE:` and explain exactly what is missing and why.
2. **No new packages.** The tech stack is frozen (see Section 2). Do not add pubspec dependencies not listed here without explicit human approval.
3. **No new architecture patterns.** All features follow Feature-First Clean Architecture (data / domain / presentation). Do not introduce providers, riverpod, getx, or any pattern outside of `flutter_bloc`.
4. **Write real code.** Every function must have a real body. Every model must have real fields matching the actual data shape.
5. **Ask before inventing.** If the problem statement is ambiguous about a behaviour, do not invent one. Surface the ambiguity as `// AGENT_QUESTION:` and implement the most conservative interpretation.

---

## 1. App Identity

```
App name:       Lumina
Package name:   com.lumina.sidekick
Min SDK:        24 (Android)
Target SDK:     34
Flutter:        3.22+ stable
Dart:           3.4+
State mgmt:     flutter_bloc (BLoC pattern, not Cubit unless screen is trivially simple)
Navigation:     go_router
Theme:          Dark-first. See Section 3 for exact color tokens.
```

---

## 2. Locked Tech Stack

Every package below is already in `pubspec.yaml`. Do not replace or alias them.

```yaml
# PDF
pdfx: ^2.6.0
native_pdf_renderer: ^6.4.0
dart_pdf: ^3.10.8

# OCR
google_mlkit_text_recognition: ^0.13.1

# Real-time
socket_io_client: ^2.0.3+1

# Auth + Google APIs
google_sign_in: ^6.2.1
googleapis: ^12.0.0
googleapis_auth: ^1.6.0

# App Usage (Android native bridge — no pub package needed)
# Accessed via MethodChannel('com.lumina.sidekick/usage_stats')

# Background
flutter_foreground_task: ^8.0.1

# Whiteboard
flutter_painter_v2: ^3.0.0

# Code editor
flutter_code_editor: ^0.3.2
flutter_highlight: ^0.7.0

# Kanban
appflowy_board: ^0.1.4
flutter_draggable: ^4.0.0

# Local storage
sqflite: ^2.3.2
hive: ^2.2.3
hive_flutter: ^1.1.0

# State
flutter_bloc: ^8.1.5
equatable: ^2.0.5

# Navigation
go_router: ^14.2.7

# ML / embeddings
tflite_flutter: ^0.10.4

# Utils
permission_handler: ^11.3.1
flutter_local_notifications: ^17.2.1+2
connectivity_plus: ^6.0.3
intl: ^0.19.0
path_provider: ^2.1.3
```

---

## 3. Theme & Color Tokens

**All colors must reference these constants from `lib/core/constants/app_colors.dart`.** Never hardcode hex values inline.

```dart
// lib/core/constants/app_colors.dart

class AppColors {
  // Backgrounds
  static const Color bgPrimary     = Color(0xFF1A1A2E);   // Main scaffold
  static const Color bgSurface     = Color(0xFF16213E);   // Cards, sheets
  static const Color bgElevated    = Color(0xFF0F3460);   // Elevated cards

  // Accent
  static const Color accentAmber   = Color(0xFFF5A623);   // CTAs, highlights, attendance
  static const Color accentPurple  = Color(0xFF6C63FF);   // Collaboration surfaces
  static const Color accentTeal    = Color(0xFF00B4D8);   // Second Brain, info

  // Stress states (Heatmap)
  static const Color stressLow     = Color(0xFF4CAF50);   // Green  — calm
  static const Color stressMed     = Color(0xFFFF9800);   // Amber  — moderate
  static const Color stressHigh    = Color(0xFFF44336);   // Red    — deadline collision

  // Text
  static const Color textPrimary   = Color(0xFFEAEAEA);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textDisabled  = Color(0xFF616161);

  // Kanban column colors
  static const Color kanbanDoing   = Color(0xFF6C63FF);
  static const Color kanbanWant    = Color(0xFFF5A623);
  static const Color kanbanDone    = Color(0xFF4CAF50);
}
```

---

## 4. Data Models — Exact Shapes

Do not invent new fields. Do not omit listed fields. All Hive models need `@HiveType` and `@HiveField` annotations. All sqflite models need `toMap()` and `fromMap()` methods.

### 4.1 TimetableEntry (Hive, box: `timetableBox`)
```dart
@HiveType(typeId: 0)
class TimetableEntry extends HiveObject {
  @HiveField(0) String id;            // uuid v4
  @HiveField(1) String subjectName;
  @HiveField(2) int    weekday;       // 1=Mon … 6=Sat
  @HiveField(3) String startTime;    // "HH:mm" 24h
  @HiveField(4) String endTime;      // "HH:mm" 24h
  @HiveField(5) String room;
  @HiveField(6) String professorName;
}
```

### 4.2 AttendanceRecord (Hive, box: `attendanceBox`)
```dart
@HiveType(typeId: 1)
class AttendanceRecord extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String timetableEntryId;  // FK → TimetableEntry.id
  @HiveField(2) DateTime date;
  @HiveField(3) bool attended;            // true = present, false = absent
}
```

### 4.3 Bunk Analytics — computed, not stored
```dart
// lib/core/utils/attendance_calculator.dart
// Given a subjectId, returns:
class BunkStats {
  final int totalClasses;
  final int attended;
  final double currentPercentage;   // attended / totalClasses * 100
  final int canBunk;                // floor((attended - 0.75 * totalClasses) / 0.25)
  final int mustAttend;             // classes needed to reach 75% from below
}
```
`canBunk` is 0 if already below 75%. `mustAttend` is 0 if at or above 75%.
Formula: `canBunk = max(0, floor((4 * attended - 3 * totalClasses) / 3))`

### 4.4 AppUsageLog (Hive, box: `usageBox`)
```dart
@HiveType(typeId: 2)
class AppUsageLog extends HiveObject {
  @HiveField(0) String packageName;
  @HiveField(1) String appLabel;
  @HiveField(2) DateTime timestamp;
  @HiveField(3) int durationSeconds;
}
```

### 4.5 CognitiveDebtSnapshot (Hive, box: `debtBox`)
```dart
@HiveType(typeId: 3)
class CognitiveDebtSnapshot extends HiveObject {
  @HiveField(0) DateTime recordedAt;
  @HiveField(1) double debtScore;   // 0.0 – 100.0
  @HiveField(2) int switchCount;    // context switches in last 30 min
}
```

### 4.6 Expense (sqflite, table: `expenses`)
```dart
class Expense {
  final String  id;          // TEXT PRIMARY KEY (uuid)
  final String  label;       // e.g. "Canteen lunch"
  final double  amount;      // positive = income, negative = expense
  final String  category;    // 'food' | 'transport' | 'stationery' | 'entertainment' | 'other'
  final DateTime date;
  final String? note;
}
```

### 4.7 KanbanTask (sqflite, table: `kanban_tasks`)
```dart
class KanbanTask {
  final String  id;
  final String  roomId;       // which group this belongs to
  final String  title;
  final String  description;
  final String  status;       // 'doing' | 'want' | 'done'
  final String  assignedTo;   // userId
  final int     position;     // sort order within column
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### 4.8 RagChunk (sqflite, table: `rag_chunks`)
```dart
class RagChunk {
  final String  id;
  final String  sourceFileName;
  final int     pageNumber;
  final String  chunkText;        // 300–500 token window
  final Uint8List embedding;      // BLOB — Float32List serialized to bytes
}
```

### 4.9 HeatmapEntry (sqflite, table: `heatmap_entries`)
```dart
class HeatmapEntry {
  final String   id;
  final DateTime date;
  final int      stressLevel;   // 0=low, 1=med, 2=high
  final String   source;        // 'gmail' | 'calendar'
  final String   label;         // e.g. "DAA Assignment Due"
}
```

---

## 5. Feature Implementation Contracts

### 5.1 Timetable OCR Parser

**Flow:**
1. User picks PDF or image via `file_picker`.
2. If PDF: render page 0 to bitmap using `pdfx` → `PdfPageImage`.
3. Pass `InputImage.fromFilePath(path)` to `TextRecognizer(script: TextRecognitionScript.latin)`.
4. Parse recognised text in `OcrParserService.parseTimetable(String rawText) → List<TimetableEntry>`.
5. Parsing strategy: look for time patterns `\d{1,2}:\d{2}` and subject name tokens. Map days from column headers (Mon/Tue/… or Monday/Tuesday/…). Room is optional — default to empty string if absent.
6. Save entries to Hive `timetableBox`.

**Do not** call any remote API for OCR. This is entirely on-device.

### 5.2 ContextSwitch + Cognitive Debt

**Android native bridge** (`android/app/src/main/kotlin/.../UsageStatsChannel.kt`):
- MethodChannel name: `com.lumina.sidekick/usage_stats`
- Method: `getUsageStats(int intervalSeconds)` → returns `List<Map>` with keys `packageName`, `appLabel`, `totalTimeForeground`, `lastTimeUsed`.
- Requires `PACKAGE_USAGE_STATS` permission — check and prompt via `permission_handler` before calling.

**Cognitive Debt Score formula** (in `cognitive_debt_service.dart`):
```
switches = number of distinct app switches in last 30 minutes
rawDebt  = switches * 8.5
decayedDebt = rawDebt * e^(-λ * minutesSinceLastSwitch)  where λ = 0.05
score = min(100.0, decayedDebt)
```
Score is computed every 5 minutes by `flutter_foreground_task`.

**Study Squads:** anonymised. Never send `packageName` or `appLabel` to the server. Send only `{ userId_hash, timestamp, switchCount, debtScore }` over Socket.io event `squad_debt_update`.

### 5.3 Group Discussion Hub — Socket.io

Server URL lives in `Env.socketServerUrl`. Never hardcode an IP address in source.

Connection init (call once per session in `SocketService`):
```dart
_socket = IO.io(
  Env.socketServerUrl,
  IO.OptionBuilder()
    .setTransports(['websocket'])
    .disableAutoConnect()
    .build(),
);
_socket.connect();
```

All events are typed. Define `SocketEvents` as string constants in `lib/features/group_hub/data/socket_events.dart`. Never use raw string literals for event names outside that file.

**Whiteboard sync:** send `PaintInfo` (from `flutter_painter_v2`) serialised to JSON on every stroke-end (`onDrawingEnded`). Do not stream individual points — only complete strokes. On receive: call `controller.addPaintInfo(paintInfo)`.

**Pasteboard:** pinned snippets are persisted in sqflite locally and broadcast via `paste_snippet`. Language detection is manual (user selects from dropdown). Supported languages: `dart`, `python`, `javascript`, `c`, `cpp`, `java`, `bash`, `json`.

### 5.4 Gmail + Calendar Heatmap

OAuth scopes required:
```dart
final scopes = [
  'https://www.googleapis.com/auth/gmail.readonly',
  'https://www.googleapis.com/auth/calendar.readonly',
];
```

**Gmail scan keywords** (defined as const List in `gmail_service.dart`):
```dart
const academicKeywords = [
  'assignment', 'submission', 'deadline', 'exam', 'test', 'quiz',
  'viva', 'practical', 'lab report', 'project', 'due', 'marks',
];
```
Scan subject lines only (`message.payload.headers` where `name == 'Subject'`). Do not fetch full email body — respect user privacy.

Heatmap stress level assignment:
- 0 keywords on a date → `stressLow`
- 1–2 keywords → `stressMed`
- 3+ keywords or any Calendar event with title matching keywords → `stressHigh`

### 5.5 Kanban Board

Uses `appflowy_board`. Three fixed columns: **Doing**, **Want to Do**, **Done**. Column IDs are constants:
```dart
const String kColumnDoing = 'col_doing';
const String kColumnWant  = 'col_want';
const String kColumnDone  = 'col_done';
```

Board state is synced to group via Socket.io event `kanban_update` with full `KanbanBoardModel` serialised to JSON. Last-write-wins. On reconnect, fetch latest board state from server's in-memory store.

### 5.6 Expense Logger

Rapid-entry screen has **only four inputs**: label (text), amount (number), category (chip selector), date (defaults to today). No confirmation dialog — tap "Add" and it saves immediately.

**Weekly Wrap** computes for Mon–Sun of current week:
- Total spent
- Total income
- Net balance
- Top spending category
- Day with highest spend

All computed from sqflite query — do not store these aggregates.

### 5.7 Local-First Second Brain (RAG)

**Pipeline:**
1. User picks PDF → ingest via `pdfx` page-by-page.
2. Extract text per page, chunk into 400-character windows with 50-char overlap.
3. Embed each chunk using `tflite_flutter` with the **MobileNet-based sentence encoder** model (model file at `assets/models/sentence_encoder.tflite`). Output: Float32List of 512 dimensions.
4. Store chunk + embedding (as `Uint8List`) in `rag_chunks` sqflite table.
5. On query: embed query string → cosine similarity against all stored embeddings → return top-5 chunks → pass chunks + query to a summarisation prompt (displayed locally, no remote LLM call).

**Cosine similarity** must be computed in Dart (not native), in `vector_store.dart`. No external vector DB library.

**This entire pipeline is offline.** Do not add any remote call inside `rag_service.dart`.

### 5.8 Smart Battery Guardian (Brownie)

Listen to `BatteryState` via `battery_plus` package (add it if not present — this is the one allowed exception).
- Below 15%: call `flutter_foreground_task` to pause RAG indexing (set a Hive flag `isRagPaused = true`).
- Simultaneously emit Socket.io `kanban_update` with current local board state.
- Show a `flutter_local_notifications` notification: "Lumina paused heavy tasks. Your Kanban is synced."

### 5.9 Overleaf/LaTeX Remote Preview (Brownie)

This is a **webview preview**, not a full Overleaf integration. Use `webview_flutter` (add to pubspec only if implementing this feature). The user pastes their Overleaf project's shareable PDF URL. Lumina fetches and renders it using `pdfx`. Refresh is manual (pull-to-refresh). No auth required — shareable link only.

---

## 6. Android Manifest — Required Declarations

The following must exist in `AndroidManifest.xml`. Do not remove them:

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.PACKAGE_USAGE_STATS"
    tools:ignore="ProtectedPermissions" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- Foreground service declaration -->
<service
    android:name="com.pravera.flutter_foreground_task.service.ForegroundTaskService"
    android:foregroundServiceType="dataSync"
    android:exported="false" />
```

---

## 7. Hive Box Names — Constants

All Hive box names are defined in `lib/core/constants/hive_boxes.dart`. Never use raw strings:

```dart
class HiveBoxes {
  static const String timetable = 'timetableBox';
  static const String attendance = 'attendanceBox';
  static const String appUsage   = 'usageBox';
  static const String cogDebt    = 'debtBox';
  static const String settings   = 'settingsBox';
}
```

Hive TypeAdapter typeIds are assigned sequentially and must never be reused:
| typeId | Class |
|---|---|
| 0 | TimetableEntry |
| 1 | AttendanceRecord |
| 2 | AppUsageLog |
| 3 | CognitiveDebtSnapshot |

---

## 8. sqflite Schema & Migrations

All table creation lives in `sqflite_service.dart`. Version starts at 1. Add a migration function for each schema change. Never drop and recreate tables.

```sql
-- v1
CREATE TABLE expenses (
  id TEXT PRIMARY KEY, label TEXT NOT NULL, amount REAL NOT NULL,
  category TEXT NOT NULL, date INTEGER NOT NULL, note TEXT
);

CREATE TABLE kanban_tasks (
  id TEXT PRIMARY KEY, room_id TEXT NOT NULL, title TEXT NOT NULL,
  description TEXT, status TEXT NOT NULL, assigned_to TEXT NOT NULL,
  position INTEGER NOT NULL, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
);

CREATE TABLE rag_chunks (
  id TEXT PRIMARY KEY, source_file_name TEXT NOT NULL, page_number INTEGER NOT NULL,
  chunk_text TEXT NOT NULL, embedding BLOB NOT NULL
);

CREATE TABLE heatmap_entries (
  id TEXT PRIMARY KEY, date INTEGER NOT NULL, stress_level INTEGER NOT NULL,
  source TEXT NOT NULL, label TEXT NOT NULL
);
```

`date` and `created_at` / `updated_at` are stored as Unix milliseconds (`DateTime.millisecondsSinceEpoch`).

---

## 9. BLoC Naming Convention

| BLoC | Events | States |
|---|---|---|
| `TimetableBloc` | `ParseTimetablePdf`, `LoadTimetable` | `TimetableInitial`, `TimetableLoading`, `TimetableLoaded`, `TimetableError` |
| `AttendanceBloc` | `MarkAttendance`, `LoadAttendance` | `AttendanceLoaded`, `AttendanceError` |
| `ContextSwitchBloc` | `StartMonitoring`, `StopMonitoring`, `UsageUpdated` | `MonitoringActive`, `DebtScoreUpdated` |
| `HeatmapBloc` | `SyncGmail`, `SyncCalendar`, `LoadHeatmap` | `HeatmapLoaded`, `HeatmapSyncing`, `HeatmapError` |
| `KanbanBloc` | `LoadBoard`, `MoveTask`, `AddTask`, `DeleteTask` | `KanbanLoaded`, `KanbanSyncing` |
| `ExpenseBloc` | `AddExpense`, `DeleteExpense`, `LoadExpenses` | `ExpensesLoaded` |
| `RagBloc` | `IngestPdf`, `QuerySecondBrain` | `RagIndexing`, `RagReady`, `RagResult` |

Events extend `Equatable`. States extend `Equatable`. Always override `props`.

---

## 10. What NOT to Do

- ❌ Do not call `setState` outside of trivial local UI widgets. Use BLoC.
- ❌ Do not use `FutureBuilder` or `StreamBuilder` at the screen level — use `BlocBuilder`.
- ❌ Do not store Google OAuth tokens in SharedPreferences — use `flutter_secure_storage` or let `googleapis_auth` manage the credential lifecycle.
- ❌ Do not make network calls from `presentation/` layer. All remote calls go through `data/` repositories.
- ❌ Do not add any analytics SDK, crash reporting SDK, or ad SDK.
- ❌ Do not create `StatefulWidget` for screens — all screens are `StatelessWidget` consuming BLoC state.
- ❌ Do not use `print()` for logging — use `debugPrint()` in debug mode only, wrapped in `assert`.

---

## 11. File Header Convention

Every `.dart` file must start with:
```dart
// lib/features/<feature>/<layer>/<file_name>.dart
// Lumina — <one-line description of this file's responsibility>
```

---

## 12. Quick Reference — Env Variables

Defined in `lib/core/constants/env.dart` (gitignored, not committed):

```dart
class Env {
  static const String socketServerUrl  = String.fromEnvironment('SOCKET_URL', defaultValue: 'http://10.0.2.2:3000');
  static const String googleClientId   = String.fromEnvironment('GOOGLE_CLIENT_ID');
}
```

Pass at build time:
```bash
flutter run --dart-define=SOCKET_URL=http://192.168.1.x:3000 --dart-define=GOOGLE_CLIENT_ID=xxxx.apps.googleusercontent.com
```

---

*Last updated for Lumina v1.0.0-hackathon. If you are an AI agent reading this: follow it exactly. Do not improvise.*