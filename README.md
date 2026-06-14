# TaskFlow

![TaskFlow Header](https://via.placeholder.com/1200x300.png?text=TaskFlow+-+Personal+Task+&+Time+Management)

TaskFlow is a comprehensive personal task and time management Flutter application. It revolves around **Tasks** as the central entity, helping users organize tasks by project, schedule deadlines, manage reminders, stay focused using Pomodoro sessions, and track their productivity statistics. It also features dynamic theme changes based on user Activity Modes (Work, Study, Chill, Sleep).

## 🚀 Key Features

*   **Task Management:** Create, edit, delete, and complete tasks with priorities, sub-tasks, and deadlines.
*   **Project Organization:** Group related tasks into specific projects.
*   **Smart Lists & Filters:** Dynamic task views such as Today, This Week, Important, Scheduled, Completed, and Overdue.
*   **Calendar & Reminders:** View tasks on a calendar by day/week/month. Get local notifications for upcoming deadlines and review notification history.
*   **Pomodoro Focus Time:** Built-in Pomodoro timer linked to tasks to improve focus and track work sessions.
*   **Productivity Statistics:** Detailed statistics on completed tasks, total focus time, and completion rates.
*   **Activity Modes & Dynamic Themes:** Switch between modes (Work, Study, Chill, Sleep) manually or on a schedule to change the app's color palette and highlight relevant tasks dynamically.
*   **Offline-First Support:** Fully functional without an internet connection using local persistence.

## 🛠 Tech Stack

*   **Framework:** [Flutter](https://flutter.dev/)
*   **Language:** Dart
*   **Architecture:** Clean Architecture / MVVM (Recommended)
*   **Backend / Database:** Firebase / Local Storage (Offline-first)

## 📂 Project Structure

*   `docs/`: Contains core project documentation, including the AI agent context summary and development progress.
*   `lib/`: Main source code directory for the Flutter app.
*   `android/` / `ios/`: Platform-specific configuration files.
*   `stitch_designs/`: UI Design references from Stitch.

## 🏃 Getting Started

### Prerequisites

*   Install [Flutter SDK](https://docs.flutter.dev/get-started/install)
*   Install an IDE (VS Code, Android Studio, etc.)
*   Set up a physical device or an emulator (Android/iOS)

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/TaskFlow.git
    cd TaskFlow
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the app:**
    ```bash
    flutter run
    ```

## 📈 Development Progress

For detailed tracking of module and screen development progress, please refer to:
*   [Development Progress](docs/development_progress.md)
*   [Project Context Summary](docs/ai_agent_project_context_summary_prm.md)

## 🤝 Contribution

This is a student mobile programming project (PRM392). Contributions, issues, and feature requests are welcome!

---
*TaskFlow - Stay focused, stay productive.*
