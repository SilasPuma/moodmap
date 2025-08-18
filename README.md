# MoodMap AI

A polished Flutter app to track moods, view a calendar with emoji, and see AI insights.

---

## ✨ Features
- Log Tab: pick emoji, add optional journal, saved locally; AI service infers mood/topics.
- Calendar Tab: month view, average mood emoji per day, daily AI summary.
- Stats Tab: weekly bar chart with fl_chart, top topics and weekly AI summary.

---

## 🖼 Screenshots
*(Coming soon — add them silas)*

---

## Tech
- Flutter with Provider
- Hive + Hive Flutter for local storage
- fl_chart, table_calendar, lottie (optional)

---

## Getting Started (Windows)
1) Install Flutter and add it to PATH: https://docs.flutter.dev/get-started/install/windows
2) From the repo root in PowerShell:
   - flutter create .
   - flutter pub get
   - flutter run

If no device is found, start an Android emulator or run "flutter devices".

---

## Notes
- AIService is mocked; connect your backend or OpenAI in `lib/services/ai_service.dart`.
- Lottie assets folder created at `assets/lottie/` for optional animations.