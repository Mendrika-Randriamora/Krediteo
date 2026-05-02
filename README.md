# Krediteo - OCR Scanner

<p align="center">
  <img src="assets/logo/icon.png" alt="Krediteo Logo" width="200"/>
</p>

Krediteo is a real-time OCR (Optical Character Recognition) application built with Flutter. It is specifically designed to detect exactly 14-digit numbers from a live camera stream and provide immediate actions, such as launching USSD calls.

## Overview

Krediteo leverages Google ML Kit to provide high-performance text recognition on mobile devices. The app is optimized for speed, accuracy, and a seamless user experience, making it ideal for tasks like scanning top-up cards or identification numbers.

## Core Features

- **Real-time OCR:** High-speed text recognition using Google ML Kit.
- **Pattern Matching:** Strictly detects 14-digit numbers using advanced regex.
- **Instant Actions:** Quick launch of USSD calls (`#321*<number>#`) and clipboard copying.
- **Performance Optimized:** Throttled processing (400ms) to ensure smooth UI performance.
- **Robust Detection:** Includes cooldown periods to prevent duplicate scans and persistence logic for better visibility.
- **Haptic Feedback:** Physical confirmation upon detection and user interaction.
- **Immersive UI:** A dark-themed, Material 3 design with animated overlays and state transitions.

## Project Structure

```text
lib/
├── main.dart
├── models/
│   ├── operator.dart            # Operator definitions (Telma, Orange, Airtel)
│   └── scan_state.dart          # State management (idle, scanning, detected)
├── screens/
│   └── scanner_screen.dart      # Main screen and logic orchestration
├── services/
│   ├── camera_service.dart      # Camera initialization and stream management
│   ├── ocr_service.dart         # ML Kit integration and detection logic
│   ├── call_service.dart        # Telephony and USSD call handling
│   └── persistence_service.dart # Local storage and settings
└── widgets/
    ├── camera_preview_widget.dart  # Full-screen camera stream
    ├── scan_overlay.dart           # Animated scanning UI and frame
    ├── operator_selector.dart      # Operator selection interface
    └── number_result_card.dart     # Actionable detection results
```

## Getting Started

### Prerequisites

- Flutter SDK 3.10.4 or higher
- Android SDK 21+ (Minimum) / 34 (Target)
- Physical Android device (Camera stream and OCR are not supported on most emulators)

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/krediteo.git
    cd krediteo
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the application:**
    ```bash
    flutter run
    ```

## Permissions

The application requires the following permissions:
- **Camera:** To capture live video for OCR processing.
- **Call Phone:** To initiate USSD calls directly from the app.
- **Vibrate:** For haptic feedback during detection.

## Configuration

- **OCR Throttle:** Adjust `_throttleMs` in `lib/services/ocr_service.dart` to balance responsiveness and CPU usage.
- **Detection Regex:** Modify the pattern in `ocr_service.dart` to detect different numeric formats.
- **Camera Resolution:** Update `ResolutionPreset` in `lib/services/camera_service.dart`.

## License

This project is licensed under the terms of the [LICENSE](LICENCE) file.
