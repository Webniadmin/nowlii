# NOWLII 🌿

> **Your Personal Wellness Companion**

NOWLII is a modern, gamified wellness Flutter application designed to help users track their progress, complete health-related quests, and interact with an AI companion to maintain a healthy and productive lifestyle.

## 🚀 Features

* **Gamified Quests:** Complete daily wellness tasks and track your progress over time.
* **AI Companion:** Interact seamlessly using Voice-to-Text and AI calling features.
* **Progress Tracking:** Detailed monthly overviews and visual insights using interactive charts.
* **Customizable Profile:** Personalize your avatar and profile settings.
* **Multilingual Support:** Dynamic language settings for a personalized user experience.
* **Smart Reminders:** Get timely push notifications to keep you on track.
* **Modern UI:** Built with clean architecture, responsive design, and smooth animations.

## 🛠 Tech Stack

* **Framework:** [Flutter](https://flutter.dev/)
* **Routing:** `go_router` for structured, deep-linkable navigation.
* **State Management:** `get` (GetX) for efficient reactivity and dependency injection.
* **UI/UX:** `flutter_screenutil` for responsiveness, `google_fonts` for typography.
* **Visuals:** `fl_chart` for data representation, `flutter_svg` for scalable vector icons.
* **Voice & AI:** `speech_to_text`, `flutter_tts`.

## 📦 Getting Started

### Prerequisites
Make sure you have the following installed:
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (Version 3.19.0 or higher recommended)
* Dart SDK
* Xcode (for iOS) & Android Studio (for Android)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository_url>
   cd nowlii
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Assets (if using flutter_gen)**
   ```bash
   dart run build_runner build -d
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 📂 Project Structure

```text
lib/
├── api/             # API services and auth controllers
├── core/            # Global components, themes, routing, and constants
├── screen/          # Feature-based UI modules (Home, Profile, Quests, AI Call, etc.)
├── widget/          # Reusable UI components
└── main.dart        # Entry point of the application
```

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the issues page.

---
*Built with ❤️ for a healthier tomorrow.*
