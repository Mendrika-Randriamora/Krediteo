# OCR Scanner Flutter

Scanner temps réel de numéros à 14 chiffres via Google ML Kit.

## Structure du projet

```
lib/
├── main.dart
├── models/
│   └── scan_state.dart          # États: idle / scanning / detected
├── screens/
│   └── scanner_screen.dart      # Écran principal, orchestration
├── services/
│   ├── camera_service.dart      # Init caméra, image stream, rotation
│   ├── ocr_service.dart         # ML Kit + regex 14 chiffres + throttling
│   └── call_service.dart        # url_launcher tel: + anti-spam
└── widgets/
    ├── camera_preview_widget.dart  # Flux caméra full screen
    ├── scan_overlay.dart           # Cadre animé, ligne de scan, état
    └── number_result_card.dart     # Carte résultat + bouton appel
```

## Prérequis

- Flutter 3.10+
- Android SDK 21+
- Un device Android physique (la caméra ne fonctionne pas sur émulateur)

## Installation

### 1. Dépendances
```bash
flutter pub get
```

### 2. Configuration Android

Dans `android/app/build.gradle`, vérifier :
```groovy
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

Dans `android/build.gradle` (projet root) :
```groovy
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
```

### 3. Lancer l'app
```bash
flutter run
```

## Fonctionnalités

| Feature | Détail |
|---|---|
| OCR temps réel | Google ML Kit Text Recognition |
| Regex de détection | `(?<!\d)(\d{14})(?!\d)` — exactement 14 chiffres isolés |
| Throttling OCR | 400ms entre chaque analyse (évite le lag) |
| Anti-spam appel | Cooldown 3s entre deux appels |
| Anti-spam détection | Gel 2.5s après chaque détection |
| Feedback haptique | Vibration 120ms à la détection |
| États visuels | idle / scanning / detected avec transitions animées |
| Copier numéro | Tap sur l'icône copie dans le presse-papier |

## Permissions requises (AndroidManifest.xml)

- `CAMERA` — accès caméra
- `CALL_PHONE` — lancer un appel direct
- `VIBRATE` — feedback haptique

## Personnalisation

### Changer le throttle OCR
Dans `lib/services/ocr_service.dart` :
```dart
static const int _throttleMs = 400; // réduire = plus réactif, plus de CPU
```

### Changer le regex de détection
```dart
static final RegExp _numberRegex = RegExp(r'(?<!\d)(\d{14})(?!\d)');
```

### Changer la résolution caméra
Dans `lib/services/camera_service.dart` :
```dart
ResolutionPreset.medium // low | medium | high | veryHigh | ultraHigh | max
```