# Eyra — Assistive Vision (Flutter UI + mock state)

Eyra is a companion app UI for an assistive smart-glasses system for
visually impaired users. **This project implements only the Flutter UI
and local/mock state.** There is no real camera access, computer-vision
inference, ESP32 communication, text-to-speech engine, cloud service, or
database anywhere in the codebase — every "connected" or "detected"
state you see is a static/local mock value.

## Requirements

- Flutter SDK (stable channel), Dart SDK `>=3.5.0`
- Android SDK / Android Studio command-line tools, or an Android device /
  emulator
- VS Code with the Flutter & Dart extensions (recommended)

## Getting started

```bash
flutter pub get
flutter run
```

Other useful commands:

```bash
flutter analyze   # static analysis
flutter test      # runs test/widget_test.dart
```

> **Note:** `android/local.properties` is intentionally **not** included
> in this project (it is machine-specific). Flutter tooling (or the VS
> Code / Android Studio Flutter plugin) generates it automatically the
> first time you run `flutter pub get` in this project.

## Project structure

```
lib/
  app/                 # MaterialApp, route table, route generator
  core/
    theme/             # Centralized colors, spacing, radius, typography, ThemeData
    widgets/           # Reusable Eyra design-system components
    models/            # Mock data models (Obstacle, ConnectionStatus, ...)
    state/             # ChangeNotifier controllers (settings, auth, devices)
    l10n/              # Lightweight English/Arabic string table
  features/
    auth/              # Splash, Login, Sign Up, Forgot Password
    onboarding/        # Welcome, Pair Glasses, Connect Audio, Test Camera, Ready
    home/               # Home screen + bottom-nav MainShell
    assistance/        # Live Assistance
    devices/           # Devices
    settings/          # Settings (incl. language + accessibility toggles)
    about/             # About
    developer/         # Developer Monitor (mock telemetry)
```

## Design system

All colors, spacing, radii, and type styles are centralized under
`lib/core/theme/`. Screens and feature widgets never hard-code raw hex
colors or magic-number paddings — everything reads from `AppColors`,
`AppSpacing`, `AppRadius`, and the shared `TextTheme`.

## Accessibility

- Large, high-contrast type by default; "Large Text" and "High Contrast"
  settings scale/boost this further.
- Minimum 48dp touch targets on all interactive controls.
- Every status indicator pairs an icon with a text label — no
  color-only signaling.
- Semantic labels on logos, buttons, toggles, and status rows for
  screen-reader users.
- Full Arabic (RTL) support: switching language in Settings flips the
  entire app's `Directionality` immediately, and the choice is persisted
  locally via `shared_preferences`.

## Known limitations

- This was produced in a sandboxed environment without the Flutter SDK
  installed, so `flutter pub get`, `flutter analyze`, `flutter test`,
  and `flutter run` could **not** be executed here. All Dart source was
  written and manually reviewed for import/reference correctness, but
  you should run the commands above yourself before relying on this
  build.
- `android/local.properties` and Gradle build caches are not included —
  they are generated locally by the Flutter/Gradle tooling.
- Only the Android platform is included, per the original request (no
  `ios/`, `web/`, `windows/`, `macos/`, or `linux/` folders).
