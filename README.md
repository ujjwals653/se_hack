# 🌟 Lumina — The Proactive Engineering Sidekick

> Built for engineering students who are tired of chasing their own schedule.

Lumina is a Flutter-based, local-first mobile assistant that combines AI-powered scheduling, deep focus tracking, real-time collaboration, and smart budgeting into a single offline-capable app.

---

## 📱 UI Design Language

- **Primary palette:** Deep navy (`#1A1A2E`) with amber/gold accents (`#F5A623`) for energy and urgency cues
- **Secondary palette:** Soft purple (`#6C63FF`) for collaboration and community surfaces
- **Card style:** Rounded corners (16px), subtle elevation, dark-mode-first
- **Typography:** Inter / Poppins — bold headers, light body text
- **Stress states:** Green (`#4CAF50`) = relaxed, Amber (`#FF9800`) = moderate, Red (`#F44336`) = deadline collision

---

## 🗂️ Project Structure

```
lumina/
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml          # USAGE_STATS + FOREGROUND_SERVICE permissions declared here
│       └── kotlin/.../MainActivity.kt   # MethodChannel bridge for UsageStatsManager
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart                     # MaterialApp root, theme, router
│   │   └── router.dart                  # go_router route definitions
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_strings.dart
│   │   │   └── hive_boxes.dart          # Box name constants for Hive
│   │   ├── services/
│   │   │   ├── hive_service.dart        # Hive init + adapter registration
│   │   │   ├── sqflite_service.dart     # DB init + migration runner
│   │   │   └── notification_service.dart
│   │   └── utils/
│   │       ├── attendance_calculator.dart
│   │       └── cognitive_debt_calculator.dart
│   ├── features/
│   │   ├── timetable/
│   │   │   ├── data/
│   │   │   │   ├── timetable_repository.dart
│   │   │   │   └── models/
│   │   │   │       ├── timetable_entry.dart   # Hive TypeAdapter
│   │   │   │       └── attendance_record.dart # Hive TypeAdapter
│   │   │   ├── domain/
│   │   │   │   ├── ocr_parser_service.dart    # google_mlkit_text_recognition
│   │   │   │   └── bunk_analytics_service.dart
│   │   │   └── presentation/
│   │   │       ├── timetable_screen.dart
│   │   │       ├── attendance_screen.dart
│   │   │       └── bunk_analytics_screen.dart
│   │   ├── context_switch/
│   │   │   ├── data/
│   │   │   │   └── app_usage_repository.dart  # MethodChannel → UsageStatsManager
│   │   │   ├── domain/
│   │   │   │   └── cognitive_debt_service.dart
│   │   │   └── presentation/
│   │   │       ├── focus_screen.dart
│   │   │       └── study_squad_screen.dart
│   │   ├── group_hub/
│   │   │   ├── data/
│   │   │   │   └── socket_service.dart        # socket_io_client
│   │   │   └── presentation/
│   │   │       ├── hub_screen.dart
│   │   │       ├── whiteboard_screen.dart     # flutter_painter_v2
│   │   │       └── pasteboard_screen.dart     # flutter_code_editor
│   │   ├── heatmap/
│   │   │   ├── data/
│   │   │   │   ├── gmail_service.dart         # googleapis Dart
│   │   │   │   └── calendar_service.dart      # googleapis Dart
│   │   │   └── presentation/
│   │   │       └── heatmap_screen.dart
│   │   ├── kanban/
│   │   │   ├── data/
│   │   │   │   └── kanban_repository.dart     # sqflite
│   │   │   └── presentation/
│   │   │       └── kanban_screen.dart         # appflowy_board
│   │   ├── expense/
│   │   │   ├── data/
│   │   │   │   └── expense_repository.dart    # sqflite
│   │   │   └── presentation/
│   │   │       ├── expense_home_screen.dart
│   │   │       └── weekly_wrap_screen.dart
│   │   ├── second_brain/
│   │   │   ├── data/
│   │   │   │   ├── pdf_ingestion_service.dart # pdfx + dart_pdf
│   │   │   │   └── vector_store.dart          # local embedding store (sqflite)
│   │   │   ├── domain/
│   │   │   │   └── rag_service.dart           # tflite_flutter embeddings
│   │   │   └── presentation/
│   │   │       └── second_brain_screen.dart
│   │   └── auth/
│   │       └── google_auth_service.dart       # google_sign_in
│   └── widgets/
│       ├── lumina_app_bar.dart
│       ├── stress_indicator.dart
│       └── bunk_chip.dart
├── pubspec.yaml
└── INSTRUCTIONS.md
```

---

## 🔧 Tech Stack

| Layer | Package | Purpose |
|---|---|---|
| PDF render | `pdfx`, `native_pdf_renderer` | Render timetable PDFs to bitmaps |
| PDF creation | `dart_pdf` | Generate expense/attendance exports |
| OCR | `google_mlkit_text_recognition` | On-device timetable parsing |
| Real-time | `socket_io_client` | Group Hub chat + whiteboard sync |
| Auth | `google_sign_in` | OAuth2 for Gmail/Calendar |
| Gmail + Calendar | `googleapis` (Dart) | Heatmap keyword scanning |
| App tracking | `UsageStatsManager` (Android) via MethodChannel | ContextSwitch foreground tracking |
| Background | `flutter_foreground_task` | Persistent Cognitive Debt scoring |
| Whiteboard | `flutter_painter_v2` | Freehand + shape drawing |
| Code Pasteboard | `flutter_code_editor`, `flutter_highlight` | Syntax-highlighted snippets |
| Kanban | `appflowy_board`, `flutter_draggable` | Drag-and-drop task board |
| Local DB (relational) | `sqflite` | Expenses, Kanban tasks, attendance records |
| Local DB (object) | `Hive` | Timetable entries, app usage logs, RAG chunks |
| Embeddings | `tflite_flutter` | Local semantic search for Second Brain |
| State | `flutter_bloc` + `equatable` | Feature-level state management |
| Navigation | `go_router` | Declarative routing |

---

## 🚀 Getting Started

### Prerequisites
- Flutter 3.22+ (stable channel)
- Android SDK 33+ (UsageStatsManager requires API 21+, full usage access API 28+)
- A Firebase project (for google_sign_in SHA-1 registration)
- A running Socket.io server (see `/server/` directory)

### Setup

```bash
git clone https://github.com/your-org/lumina.git
cd lumina
flutter pub get
```

#### Android Permissions
The following must be granted manually by the user (cannot be auto-granted):
- **Usage Access** (`PACKAGE_USAGE_STATS`) — Settings → Special App Access → Usage Access
- **Accessibility Service** — for foreground app label reading

These are declared in `AndroidManifest.xml` and the app guides the user through the grant flow on first launch via `permission_handler` + deep link to settings.

#### Environment Config
Create `lib/core/constants/env.dart` (gitignored):
```dart
class Env {
  static const String socketServerUrl = 'http://YOUR_LOCAL_IP:3000';
  static const String googleClientId   = 'YOUR_OAUTH_CLIENT_ID.apps.googleusercontent.com';
}
```

### Run
```bash
flutter run --debug
```

---

## 🏗️ Architecture

Lumina follows **Feature-First Clean Architecture**:
- `data/` — repositories, remote/local data sources, model classes
- `domain/` — pure business logic services (no Flutter imports)
- `presentation/` — BLoC/Cubit + Screens + Widgets

State flows: `UI Event → BLoC → Domain Service → Repository → Data Source → Hive / sqflite / Socket / API`

### Storage Strategy
| Data type | Store | Why |
|---|---|---|
| Timetable, schedule entries | Hive | Fast object read, TypeAdapter codegen |
| Attendance records | Hive | Same box as timetable for locality |
| Expenses, Kanban tasks | sqflite | Relational queries (sum by date, filter by status) |
| RAG text chunks + embeddings | sqflite (BLOB) | Portable, no extra native lib |
| App usage logs (ContextSwitch) | Hive | Append-only time-series |

---

## 🌐 Socket.io Server (Group Hub)

Minimal Node.js server lives in `/server/`:

```
server/
├── index.js
├── package.json
└── rooms/
    └── roomManager.js
```

Events contract:
| Event | Direction | Payload |
|---|---|---|
| `join_room` | client → server | `{ roomId, userId, displayName }` |
| `message` | bidirectional | `{ roomId, userId, text, timestamp }` |
| `whiteboard_stroke` | bidirectional | `{ roomId, stroke: StrokeModel }` |
| `paste_snippet` | bidirectional | `{ roomId, language, code, pinnedBy }` |
| `kanban_update` | bidirectional | `{ roomId, boardState: KanbanBoardModel }` |

---

## ✅ Feature Status

| Feature | Status |
|---|---|
| Timetable OCR Parser | 🔲 Not started |
| Attendance + Bunk Analytics | 🔲 Not started |
| ContextSwitch + Cognitive Debt | 🔲 Not started |
| Study Squads | 🔲 Not started |
| Group Hub (Chat) | 🔲 Not started |
| Whiteboard | 🔲 Not started |
| Code Pasteboard | 🔲 Not started |
| Gmail/Calendar Heatmap | 🔲 Not started |
| Kanban Board | 🔲 Not started |
| Expense Logger + Weekly Wrap | 🔲 Not started |
| Second Brain (RAG) | 🔲 Not started |
| Overleaf Preview (Brownie) | 🔲 Not started |
| Smart Battery Guardian (Brownie) | 🔲 Not started |

---

## 👥 Team

| Name | Role |
|---|---|
| — | Flutter Lead |
| — | Backend / Socket.io |
| — | AI / RAG Pipeline |
| — | UI/UX |