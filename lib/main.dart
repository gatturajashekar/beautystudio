import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Screens
import 'app_shell.dart';
import 'screens/authentication.dart';
import 'screens/admin/adminhome.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Local notifications
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _notificationChannel =
    AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);

/// ===============================
/// FCM BACKGROUND HANDLER
/// ===============================
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    debugPrint("🔥 Background message: ${message.notification?.title}");
  } catch (_) {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_notificationChannel);

  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  runApp(const MyApp());
}

/// ===============================
/// ROOT APP
/// ===============================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MadhuBeautyStudio',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: const Color(0xFFF5DEB3),
      ),
      home: const AppBootstrap(),
    );
  }
}

/// ===============================
/// BOOTSTRAP LOGIC
/// ===============================
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  bool checking = true;
  Widget? startScreen;

  @override
  void initState() {
    super.initState();
    _initFCM();
    _setupForegroundNotifications();
    _decideStartScreen();
  }

  /// ==========================
  /// FCM PERMISSION SETUP
  /// ==========================
  Future<void> _initFCM() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// ==========================
  /// FOREGROUND NOTIFICATIONS
  /// ==========================
  void _setupForegroundNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _notificationChannel.id,
              _notificationChannel.name,
              channelDescription: _notificationChannel.description,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });
  }

  /// ==========================
  /// AUTH DECISION (FIXED)
  /// ==========================
  Future<void> _decideStartScreen() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();

    final isAdmin = prefs.getBool("isAdmin") ?? false;
    final adminToken = prefs.getString("adminToken");
    final adminLoginAt = prefs.getInt("adminLoginAt");

    // ⏱️ Admin session valid for 12 hours
    final isValidAdminSession =
        isAdmin &&
        adminToken != null &&
        adminToken.isNotEmpty &&
        adminLoginAt != null &&
        DateTime.now().millisecondsSinceEpoch - adminLoginAt <
            12 * 60 * 60 * 1000;

    if (isValidAdminSession) {
      startScreen = const AdminHome();
    } else if (firebaseUser != null) {
      startScreen = AppShell();
    } else {
      startScreen = const AuthScreen();
    }

    setState(() => checking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return startScreen!;
  }
}
