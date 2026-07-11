# PDR AI v1.0

Flutter application for AI-assisted vehicle dent detection.

## Run

```bash
flutter clean
flutter pub get
flutter run
```

For a private Roboflow key, run with:

```bash
flutter run --dart-define=ROBOFLOW_API_KEY=YOUR_KEY --dart-define=ROBOFLOW_MODEL_ID=YOUR_MODEL
```

## iOS
An IPA must be built and signed on macOS with Xcode. Camera and photo permissions are included in `ios/Runner/Info.plist`.

## Important
AI output is an estimate and should be verified by a qualified PDR technician.
