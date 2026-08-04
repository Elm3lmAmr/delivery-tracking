# Edara Delivery Tracking - Mobile App

Flutter app for drivers (self-onboard, deliver) and guards (scan, verify, admit).

## Setup

Requires Flutter 3.19+.

```bash
cd mobile
flutter pub get
flutter run
```

For Android emulator, the app calls the backend at `http://10.0.2.2:4000` (which is the host machine's localhost from the emulator).
For iOS simulator, use `http://localhost:4000`.
For physical devices, use your machine's LAN IP or a deployed URL — pass it in at build time:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:4000/api/v1
```

## Native permissions required

**Android (`android/app/src/main/AndroidManifest.xml`):**
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

**iOS (`ios/Runner/Info.plist`):**
```xml
<key>NSCameraUsageDescription</key>
<string>Take photos of your ID and license for driver verification.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Track your delivery route inside the compound.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Continue tracking your delivery even when app is in background.</string>
```

## Google Maps

Add your API key:
- **Android:** `android/app/src/main/AndroidManifest.xml` inside `<application>`:
  ```xml
  <meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_KEY"/>
  ```
- **iOS:** `ios/Runner/AppDelegate.swift`:
  ```swift
  GMSServices.provideAPIKey("YOUR_KEY")
  ```

## Firebase (push notifications)

Run `flutterfire configure` after creating a Firebase project. This generates `firebase_options.dart`.
Then in `main.dart` add:
```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

## Structure

- `lib/main.dart` - entry point
- `lib/app.dart` - MaterialApp with router
- `lib/router.dart` - GoRouter routes
- `lib/theme.dart` - Edara navy palette
- `lib/api/` - Dio-based API client + endpoint wrappers
- `lib/screens/onboarding/` - 6 driver signup screens (phone, OTP, ID, license, plate, selfie, verifying)
- `lib/screens/driver/` - driver home, new delivery, QR display
- `lib/screens/guard/` - guard scanner, verify
- `lib/services/location_service.dart` - GPS pinging during active delivery

## What's included

Complete UI skeleton for all 13 screens (7 onboarding + 3 driver + 2 guard + splash). Wired routing, theme, API client structure, camera capture, QR display, QR scanning, GPS pinging service.

## What's TODO before shipping

1. Wire the `// TODO:` comments in each screen to actual API calls
2. Add Riverpod providers for auth state and current delivery
3. Handle offline queue for pings (store in Hive, drain on reconnect)
4. Add proper error snackbars
5. Add EN/AR localization (Flutter `intl` package)
6. Add app icon and splash screen assets
7. Sign for release: `flutter build apk --release` / `flutter build ipa --release`
