import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../api/api_client.dart';

class PushNotificationService {
  final ApiClient apiClient;

  PushNotificationService(this.apiClient);

  Future<void> initialize() async {
    // 1. Request permissions for iOS/Android 13+
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // 2. Get initial token and send to backend
    String? token = await messaging.getToken();
    if (token != null) {
      await _sendTokenToBackend(token);
    }

    // 3. Listen to token refreshes
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _sendTokenToBackend(newToken);
    }).onError((err) {
      debugPrint("Error listening to token refresh: $err");
    });

    // 4. Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification?.title}');
      }
    });
  }

  Future<void> _sendTokenToBackend(String token) async {
    if (!apiClient.hasToken) {
      // User is not logged in yet, we can't associate the token.
      // The token should ideally be sent again after successful login.
      return;
    }

    try {
      await apiClient.dio.put('/auth/fcm-token', data: {'token': token});
      debugPrint('Successfully registered FCM token with backend.');
    } catch (e) {
      debugPrint('Failed to register FCM token with backend: $e');
    }
  }
}
