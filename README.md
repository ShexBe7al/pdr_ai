# PDR AI v1.0

Flutter mobile prototype for vehicle dent detection with Roboflow.

## First run

```bash
flutter clean
flutter pub get
flutter run
```

On first launch, open **Settings** and paste the Roboflow API key. The default model ID is already filled in.

## Main features

- Start Scan opens the camera directly
- Capture and AI scan in one flow
- Gallery image scanning
- Correctly scaled dent bounding boxes
- Dent count, confidence, and inference time
- Scan history
- PDF report export and sharing
- Android APK and unsigned iOS IPA workflows

## GitHub Actions

- `Flutter CI`: analyzes the project, builds Android APK, and creates an unsigned IPA.
- `Build iOS IPA`: manual iOS-only workflow.

The iOS artifact is named `pdr-ai-unsigned-ipa`. It must be signed with an Apple ID/certificate using a tool such as Sideloadly before installation.

## Security

Do not commit the Roboflow API key to GitHub. It is stored locally on the device through SharedPreferences.
