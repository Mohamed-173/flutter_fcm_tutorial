import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'package:http/http.dart' as http;

void main() async {
  await dotenv.load(
    fileName: '.env.product',
  );
  WidgetsFlutterBinding.ensureInitialized();
  // Check if Firebase is already initialized
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
      name: 'secondary',
    );
  }
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  // Configure platform-specific notification setup
  await configureNotifications();

  // Request permissions after initializing Firebase
  await requestNotificationPermissions();

  // Subscribe to a topic, e.g., "news"
  _subscribeToTopic("news");
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      name: 'tertiary',
    );
  }

  debugPrint("Handling a background message: ${message.messageId}");
}

Future<void> configureNotifications() async {
  if (Platform.isIOS) {
    // For iOS, request permissions with provisional (silent notifications allowed)
    final settings = await FirebaseMessaging.instance.requestPermission(
      provisional: true,
    );
    myDebugPrint("iOS authorization status: ${settings.authorizationStatus}");

    // Retrieve APNs token for iOS
    final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    if (apnsToken != null) {
      myDebugPrint("APNs token for iOS: $apnsToken");
    }
  } else if (kIsWeb) {
    // For Web, use VAPID key for retrieving FCM token
    final fcmToken = await FirebaseMessaging.instance.getToken(
      vapidKey: "Your-VAPID-Key-Here",
    );
    myDebugPrint("FCM token for Web: $fcmToken");
  } else {
    // For Android, retrieve FCM token without VAPID key
    final fcmToken = await FirebaseMessaging.instance.getToken();
    debugPrint("FCM token for Android: $fcmToken");
  }
}

Future<void> requestNotificationPermissions() async {
  // Get Firebase Messaging instance
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permissions on iOS or check settings on Android
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: true,
    sound: true,
  );

  myDebugPrint(
      'Notification permission status: ${settings.authorizationStatus}');
}

Future<void> _subscribeToTopic(String topic) async {
  await FirebaseMessaging.instance.subscribeToTopic(topic);
  myDebugPrint("Subscribed to topic: $topic");
}

// Debug printing function for development mode
void myDebugPrint(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

Future<void> _sendNotificationToTopic(BuildContext context) async {
  const String serverKey =
      "YOUR_SERVER_KEY"; // Replace with your FCM server key
  const String topic = "news"; // The topic to send the notification to

  final url = Uri.parse("https://fcm.googleapis.com/fcm/send");
  final headers = {
    "Content-Type": "application/json",
    "Authorization": "key=$serverKey",
  };

  final notificationData = {
    "to": "/topics/$topic",
    "notification": {
      "title": "News Update",
      "body": "Here’s the latest news!",
    },
    "data": {
      "type": "details",
      "info": "More information about the news...",
    },
  };

  try {
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(notificationData),
    );

    if (response.statusCode == 200) {
      myDebugPrint("Notification sent to topic $topic");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Notification sent successfully!")),
      );
    } else {
      myDebugPrint("Failed to send notification: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send notification.")),
      );
    }
  } catch (e) {
    myDebugPrint("Error sending notification: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Error sending notification.")),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notification Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Home Page'),
      routes: {
        '/chat': (context) => ChatScreen(),
        '/details': (context) => DetailsScreen(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    setupInteractedMessage();
    _listenToForegroundMessages();
  }

  // Sets up handling for notification interactions
  Future<void> setupInteractedMessage() async {
    // Handle notifications that opened the app from a terminated state
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Handle notifications that open the app while it’s in the background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  // Listens for messages while app is in the foreground
  void _listenToForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      myDebugPrint(
          'Foreground message received: ${message.notification?.title}');
      // Display a UI notification if desired, e.g., using a snackbar
      if (message.notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(message.notification!.body ?? 'New Notification')),
        );
      }
    });
  }

  // Navigates based on notification type
  void _handleMessage(RemoteMessage message) {
    if (message.data['type'] == 'chat') {
      Navigator.pushNamed(context, '/chat', arguments: message.data);
    } else if (message.data['type'] == 'details') {
      Navigator.pushNamed(context, '/details', arguments: message.data);
    } else {
      myDebugPrint("Unknown notification type");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
          child: Column(
        children: [
          const Text("Home Screen"),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _sendNotificationToTopic(context),
            child: const Text("Send Notification to News Topic"),
          ),
        ],
      )),
    );
  }
}

// Screen for handling "chat" type notifications
class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = ModalRoute.of(context)?.settings.arguments as Map?;
    return Scaffold(
      appBar: AppBar(title: const Text("Chat Screen")),
      body: Center(child: Text("Chat details: ${data?['message']}")),
    );
  }
}

// Screen for handling "details" type notifications
class DetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = ModalRoute.of(context)?.settings.arguments as Map?;
    return Scaffold(
      appBar: AppBar(title: const Text("Details Screen")),
      body: Center(child: Text("Details: ${data?['info']}")),
    );
  }
}
