# myfschool

A Flutter school-management app powered by Firebase (Authentication + Firestore) and Riverpod for state management.

---

## 🚀 Quick Start — Temporary / Shared Environment

The easiest way to code and debug **on any PC without installing anything locally** is to use a **Dev Container** — either through [GitHub Codespaces](https://github.com/features/codespaces) (runs entirely in the browser) or [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers) (runs locally in Docker).

### Option A — GitHub Codespaces (zero local setup)

1. Click **Code → Codespaces → Create codespace on `main`** (or your branch) on the GitHub repository page.
2. Wait ~2 minutes while the container builds and `flutter pub get` runs automatically.
3. You now have a full Flutter + Dart environment with all VS Code extensions pre-installed.
4. Run the app in **web mode** from the integrated terminal:

   ```bash
   flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0
   ```

   Codespaces will prompt you to open the forwarded port 8080 in your browser.

### Option B — VS Code Dev Containers (local Docker)

**Prerequisites:** [Docker Desktop](https://www.docker.com/products/docker-desktop/) + [VS Code](https://code.visualstudio.com/) + the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).

1. Clone the repo:
   ```bash
   git clone https://github.com/vqtung2k4/myfschool.git
   cd myfschool
   ```
2. Open the folder in VS Code, then accept the **"Reopen in Container"** prompt (or run **Dev Containers: Reopen in Container** from the Command Palette).
3. The container will build and `flutter pub get` will run automatically.
4. Run the app:
   ```bash
   # Web (accessible in your browser on localhost:8080)
   flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0

   # Linux desktop (inside the container)
   flutter run -d linux
   ```

---

## 💻 Local Setup (without Docker)

If you prefer a native installation:

1. **Install Flutter** — follow the official guide: <https://docs.flutter.dev/get-started/install>
   - Minimum required Dart SDK: `^3.10.4`

2. **Clone & install dependencies**:
   ```bash
   git clone https://github.com/vqtung2k4/myfschool.git
   cd myfschool
   flutter pub get
   ```

3. **Connect a device or emulator** (Android / iOS / Chrome / desktop).

4. **Run the app**:
   ```bash
   flutter run
   ```

5. **Analyze & format**:
   ```bash
   flutter analyze   # lint
   flutter format .  # auto-format
   ```

6. **Run tests**:
   ```bash
   flutter test
   ```

---

## 🔥 Firebase Configuration

This project uses Firebase (Authentication + Firestore). To connect to a Firebase project you need to add the platform-specific `google-services.json` / `GoogleService-Info.plist` files (these are **not** committed to the repository for security reasons).

1. Create or open your project in the [Firebase Console](https://console.firebase.google.com/).
2. Follow the [FlutterFire setup guide](https://firebase.flutter.dev/docs/overview) to generate and place the config files:
   - **Android**: `android/app/google-services.json`
   - **iOS/macOS**: `ios/Runner/GoogleService-Info.plist`
   - **Web**: update `web/index.html` with your Firebase config snippet
3. Enable **Email/Password** authentication and **Cloud Firestore** in the Firebase Console.

---

## 📁 Project Structure

```
lib/
├── main.dart          # Entry point
├── app.dart           # App widget & router setup
└── features/
    └── auth/          # Authentication feature
```

---

## 🛠 Useful Commands

| Command | Description |
|---|---|
| `flutter pub get` | Install / update dependencies |
| `flutter run` | Run on a connected device |
| `flutter run -d chrome` | Run in Chrome |
| `flutter build apk` | Build Android APK |
| `flutter build web` | Build for web |
| `flutter analyze` | Run linter |
| `flutter test` | Run tests |
| `flutter clean` | Clear build cache |
