import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;

class FcmService {
  static const String apiUrl =
      "https://vc2lgmylyi.execute-api.us-east-1.amazonaws.com/prod/tokens";

  /// -------------------------
  /// DEVICE ID (Android + iOS)
  /// -------------------------
  static Future<String> _deviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    try {
      final android = await deviceInfo.androidInfo;
      return android.id ?? "unknown_android";
    } catch (_) {}

    try {
      final ios = await deviceInfo.iosInfo;
      return ios.identifierForVendor ?? "unknown_ios";
    } catch (_) {}

    return "unknown_device";
  }

  /// -------------------------
  /// REGISTER FCM TOKEN
  /// -------------------------
  static Future<void> registerToken({
    required String accountId,
    required bool isAdmin,
  }) async {
    final token = await FirebaseMessaging.instance.getToken();
    final deviceId = await _deviceId();

    if (token == null) {
      print("❌ FCM token null — cannot register");
      return;
    }

    final body = {
      "accountId": accountId,
      "isAdmin": isAdmin,
      "fcmToken": token,
      "deviceId": deviceId,
      "platform": "android"
    };

    try {
      await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      print("🔥 Token registered on backend: $body");
    } catch (e) {
      print("❌ Failed to register token: $e");
    }
  }

  /// -------------------------
  /// REMOVE TOKEN (FIXED)
  /// -------------------------
  static Future<void> removeToken({
    required String accountId,
    required bool isAdmin,
  }) async {
    final deviceId = await _deviceId();

    final uri = Uri.parse(apiUrl).replace(queryParameters: {
      "accountId": accountId,
      "deviceId": deviceId,
      "isAdmin": isAdmin.toString(),
    });

    try {
      await http.delete(uri);

      print(" Token removed from backend");
    } catch (e) {
      print(" Error removing token: $e");
    }
  }
}
