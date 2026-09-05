# AGENTS.md

Krediteo is a Flutter (Dart) OCR scanner for Android. It uses Google ML Kit
(`google_mlkit_text_recognition`) to detect exact 14-digit numbers from a live
camera stream and launch USSD calls.

## Commands

```bash
flutter pub get       # install deps
flutter run           # run in debug (needs a device, see below)
flutter analyze       # static analysis (lint)
flutter test          # runs test/widget_test.dart (smoke test only)
flutter build apk --release  # needs signing, see below
```

- No CI, no pre-commit, no task runner, no `opencode.json`/editor config are
  configured. `flutter analyze` is the de-facto lint check.
- **Tests**: only one smoke test exists (`test/widget_test.dart`). It pumps
  `OcrScannerApp` without a camera, so new widget tests must not assume a
  live camera/permissions are available.

## Critical runtime constraints

- **Camera + OCR do NOT work on emulators.** You must test on a **physical
  Android device**. The UI error path (`ScannerScreen` init error view) is what
  you hit on emulators.
- Release builds require **`android/key.properties`** (gitignored; a signing
  keystore). Building `--release` without it fails. `applicationId`/`namespace`
  are still the Flutter template `com.example.krediteo` (there's a TODO).
- App forces **portrait** and **immersiveSticky** mode (`main.dart`,
  `scanner_screen.dart`).

## Architecture

Service-oriented layout under `lib/`:
- `main.dart` — entrypoint; initializes Hive (`Hive.initFlutter()`), forces
  portrait, `home: ScannerScreen`.
- `services/` — `ocr_service.dart` (ML Kit + detection),
  `camera_service.dart`, `call_service.dart`, `persistence_service.dart`
  (operator selection via `shared_preferences`).
- `screens/scanner_screen.dart` — orchestrates camera stream, OCR, state
  machine, and the result card.
- `widgets/` — camera preview, scan overlay (visual frame), operator selector,
  number result card.
- `models/` — `operator.dart`, `scan_state.dart`.
- `features/ussd_shortcuts/` — newer feature (models/services/pages/widgets) for
  saved USSD shortcuts, persisted in a Hive box `ussd_shortcuts`. This
  directory is **not** documented in `README.md` and is **not** in the README
  project tree — it was added after the README was written.

### Wiring that isn't obvious from filenames

- The USSD shortcuts feature is **reachable from the scanner**: the bolt icon in
  `lib/widgets/operator_selector.dart:3` imports and pushes
  `UssdShortcutsPage`. `UssdService.init()` lazily opens the Hive box.
- `Operator` enum (`lib/models/operator.dart`) has only **two** values: `yas`
  and `orange` — NOT three. `README.md`/`GEMINI.md` mention Telma/Airtel which
  are stale. `default` operator is `yas`.
- USSD URIs: `#` must be `%23` in `tel:` URIs (`Operator.formatUri`).

## OCR detection logic (touch these carefully)

Primary logic in `ocr_service.dart`:
- Strict regex: `(?<!\d)(\d{14})(?!\d)` — exactly 14 digits, no neighbors.
- **Scan zone ratios** (`_zoneTopRatio` … `_zoneRightRatio`) restrict which part
  of the frame is accepted. These are tuned to **match the visual frame drawn in
  `scan_overlay.dart`** — if you change the overlay frame, update these ratios
  together.
- OCR throttled to once per **400ms** (`_throttleMs`).
- `scanner_screen.dart`: **2.5s cooldown** (`_detectionCooldownMs`) after a new
  number to avoid duplicate scans, and keeps a detected result visible **3s**
  after it leaves frame.

## Style / conventions

- Code comments and user-facing strings are **written in French** (service
  comments, SnackBar texts, dialog labels). Keep new strings/comments in French
  to match.
- Dark Material 3 theme, accent `Color(0xFF38BDF8)`, `Colors.black` scaffold
  background, accent used on FABs/icons.
- `flutter_launcher_icons` generates **Android only** (`android: true`,
  `ios: false`) from `assets/logo/1.2.0.png`.
- Uses default `package:flutter_lints/flutter.yaml` (no custom rules in
  `analysis_options.yaml`).

## Stale docs

`README.md` project tree is out of date (missing `features/ussd_shortcuts/`,
and lists Telma/Orange/Airtel operators that no longer match the two-value
`Operator` enum). Prefer the code and this file over README/GEMINI.md.
