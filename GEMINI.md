# Krediteo - OCR Scanner

Krediteo is a Flutter-based mobile application designed for real-time OCR (Optical Character Recognition) scanning of 14-digit numbers. It leverages Google ML Kit for text recognition and provides a streamlined user experience for detecting and acting upon specific numeric patterns.

## Project Overview

- **Core Purpose:** Detect exactly 14-digit numbers from a live camera stream and launch a USSD call format: `#321*<number>#`.
- **Primary Technologies:**
  - **Framework:** Flutter (Dart)
  - **OCR Engine:** `google_mlkit_text_recognition`
  - **Camera:** `camera`
  - **Interactions:** `url_launcher` (USSD calls via `%23321*...%23`), `permission_handler`, `HapticFeedback`.
- **Architecture:** Follows a service-oriented architecture with a clear separation of concerns:
  - `lib/models/`: State management objects (e.g., `ScanState`).
  - `lib/services/`: Core logic for Camera, OCR processing, and Telephony.
  - `lib/screens/`: High-level UI orchestration.
  - `lib/widgets/`: Modular UI components (Overlays, Cards, Previews).

## Building and Running

### Prerequisites
- Flutter SDK 3.10.4 or higher.
- Android SDK 21+ (Min) / 34 (Target/Compile).
- Physical Android device (OCR and Camera stream are not supported on most emulators).

### Key Commands
- **Install Dependencies:** `flutter pub get`
- **Run the App:** `flutter run`
- **Build APK:** `flutter build apk`
- **Analyze Code:** `flutter analyze`

## Development Conventions

### Detection Logic
- **Regex:** The app strictly looks for 14-digit numbers using `(?<!\d)(\d{14})(?!\d)`.
- **Throttling:** OCR processing is throttled to once every 400ms to maintain UI performance and reduce CPU usage.
- **Cooldown:** After a successful detection, there is a 2.5s "freeze" period to prevent duplicate scans of the same number.
- **Display Duration:** The detected number remains visible for 3 seconds after disappearing from the camera view.

### UI & Styling
- **Theme:** Material 3 with a dark-themed, immersive aesthetic (Slate/Black/Cyan palette).
- **Orientation:** Fixed to Portrait mode (`SystemChrome.setPreferredOrientations`).
- **Feedback:** Uses `HapticFeedback` (medium/heavy impact) for detection and user actions.

### Implementation Details
- **Camera Stream:** Uses `startImageStream` to pass frames directly to `OcrService`.
- **Image Conversion:** Manually converts `CameraImage` planes to `InputImage` bytes for ML Kit consumption.
- **Service Pattern:** Services are stateless where possible or managed via the `ScannerScreen` state.

## Key Files
- `lib/services/ocr_service.dart`: Contains the ML Kit integration and detection regex.
- `lib/services/camera_service.dart`: Manages camera initialization and stream configuration.
- `lib/screens/scanner_screen.dart`: The main coordination point for state, camera, and OCR logic.
- `lib/widgets/scan_overlay.dart`: Custom painter/animator for the scanning UI.
