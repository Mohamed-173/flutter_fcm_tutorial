# Flutter FCM Tutorial

## Flutter Firebase Cloud Messaging Tutorial
This guide will walk you through setting up Firebase Cloud Messaging (FCM) in a Flutter app. We’ll cover configuration and initialization, with detailed explanations for each important line.

`Tip: It's just a beta version of Readme we are working on it.`

### Prerequisites
- **Flutter SDK**: Ensure Flutter is installed.
- **Firebase Project**: Create a Firebase project at the [Firebase Console](https://console.firebase.google.com/).
- **Environment Setup**: For better security, sensitive data is stored using `dotenv`.

### 1. Install Necessary Packages
Add these dependencies to `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: latest_version
  firebase_messaging: latest_version
  flutter_dotenv: latest_version
```

Run `flutter pub get` to install packages.

### 2. Set Up Environment Variables
To protect sensitive information, we’ll use `flutter_dotenv` to load environment variables.

- Create an `.env` file in the root of your project.
- In `.env`, add placeholders for any keys you may use:

```env
FIREBASE_API_KEY=your_firebase_api_key
```

### 3. Initialize Firebase and Configure FCM
In `main.dart`, initialize Firebase and configure FCM:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(); // Loads environment variables securely
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  await _initializeNotifications();

  runApp(MyApp());
}

Future<void> _initializeNotifications() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permissions (essential for iOS)
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Get FCM token (useful for identifying devices for notifications)
  final fcmToken = await messaging.getToken();
  print("FCM Token: $fcmToken");

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(); // Re-initialize Firebase in background
  print("Handling background message: ${message.messageId}");
}
```

#### Explanation of Key Lines
- `dotenv.load()`: Loads sensitive environment variables securely.
- `Firebase.initializeApp()`: Initializes Firebase; necessary before using Firebase services.
- `messaging.requestPermission()`: Requests notification permissions (important for iOS).
- `messaging.getToken()`: Retrieves the device’s unique FCM token, allowing targeted notifications.
- `onBackgroundMessage`: Registers a handler to process notifications received while the app is in the background or terminated.

### 4. Configure Notification Permissions for Android
Add these permissions in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

#### Explanation
These permissions allow the app to connect to the internet, receive notifications, wake the device for alerts, and display notifications.

### 5. Configure Foreground Notification Handling
Add this to the `MyApp` widget’s state class to display notifications when the app is in the foreground:

```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  print('Message received in foreground: ${message.notification?.title}');
});
```

This step ensures notifications are processed even when the app is open.
