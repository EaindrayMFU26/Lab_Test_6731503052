# Smart Class Check-in and Learning Reflection App

This repository contains a Flutter MVP for a university class attendance and reflection system.

Students can:
- Check in before class with GPS and QR code.
- Submit pre-class reflection (previous topic, expected topic, mood).
- Finish class with GPS and QR code again.
- Submit post-class reflection (what they learned, feedback).

Data is saved locally for MVP requirements, with Firebase Firestore integration for cloud backup.

## Project Structure

- [smart_class_app](smart_class_app)
- [smart_class_app/lib](smart_class_app/lib)
- [smart_class_app/lib/models/class_session.dart](smart_class_app/lib/models/class_session.dart)
- [smart_class_app/lib/screens/home_screen.dart](smart_class_app/lib/screens/home_screen.dart)
- [smart_class_app/lib/screens/check_in_screen.dart](smart_class_app/lib/screens/check_in_screen.dart)
- [smart_class_app/lib/screens/finish_class_screen.dart](smart_class_app/lib/screens/finish_class_screen.dart)
- [smart_class_app/lib/services/storage_service.dart](smart_class_app/lib/services/storage_service.dart)
- [smart_class_app/lib/services/firestore_service.dart](smart_class_app/lib/services/firestore_service.dart)

## Setup Instructions

1. Install Flutter SDK.
2. Verify toolchain:
	- `flutter --version`
	- `flutter doctor`
3. Open project folder:
	- `cd /workspaces/Lab_Test_6731503052/smart_class_app`
4. Install dependencies:
	- `flutter pub get`

## How to Run the App

### Run on local device or emulator

1. List devices:
	- `flutter devices`
2. Run app:
	- `flutter run`

### Run web build locally

1. Start web target:
	- `flutter run -d chrome`

### Build production web output

1. Build:
	- `flutter build web --release`
2. Output folder:
	- [smart_class_app/build/web](smart_class_app/build/web)

## Firebase Configuration Notes

This project uses:
- `firebase_core`
- `cloud_firestore`

Main setup files:
- [smart_class_app/lib/main.dart](smart_class_app/lib/main.dart)
- [smart_class_app/lib/firebase_options.dart](smart_class_app/lib/firebase_options.dart)
- [smart_class_app/firebase.json](smart_class_app/firebase.json)

### Configure Firebase for your own environment

1. Login:
	- `firebase login --no-localhost`
2. Install FlutterFire CLI:
	- `dart pub global activate flutterfire_cli`
3. Configure app:
	- `flutterfire configure --project <your-project-id>`
4. Ensure Firestore is enabled in Firebase Console.

### Deploy to Firebase Hosting

1. Build web:
	- `flutter build web --release`
2. Deploy:
	- `firebase deploy --only hosting --project <your-project-id>`

Current deployed URL used during lab implementation:
- https://smartclass-e607d.web.app

## Notes for Evaluation

- MVP local storage requirement is implemented through SharedPreferences.
- Finish flow updates the latest open session (`checkedIn` to `completed`).
- Firebase sync is best-effort and non-blocking, so local save remains fast.