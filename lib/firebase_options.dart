import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static final FirebaseOptions android = FirebaseOptions(
    apiKey: dotenv.env['apiKeyAndroid'] ?? '',
    appId: dotenv.env['appIdAndroid'] ?? '',
    messagingSenderId: dotenv.env['messagingSenderId'] ?? '',
    projectId: dotenv.env['projectId'] ?? '',
    storageBucket: dotenv.env['storageBucket'] ?? '',
  );

  static final FirebaseOptions ios = FirebaseOptions(
    apiKey: dotenv.env['apiKeyIos'] ?? '',
    appId: dotenv.env['appIdIos'] ?? '',
    messagingSenderId: dotenv.env['messagingSenderId'] ?? '',
    projectId: dotenv.env['projectId'] ?? '',
    storageBucket: dotenv.env['storageBucket'] ?? '',
    iosBundleId: 'com.example.flutterFcmTutorial',
  );

  static final FirebaseOptions web = FirebaseOptions(
    apiKey: dotenv.env['apiKeyWeb'] ?? '',
    appId: dotenv.env['appIdWeb'] ?? '',
    messagingSenderId: dotenv.env['messagingSenderId'] ?? '',
    projectId: dotenv.env['projectId'] ?? '',
    authDomain: dotenv.env['authDomain'] ?? '',
    storageBucket: dotenv.env['storageBucket'] ?? '',
  );
}

Future<void> initializeFirebase() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
        name: 'forth', options: DefaultFirebaseOptions.currentPlatform);
  }
}
