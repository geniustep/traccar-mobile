/// FCM integration stub.
///
/// To activate:
///   1. Add `firebase_core` and `firebase_messaging` to pubspec.yaml
///   2. Configure google-services.json (Android) and GoogleService-Info.plist (iOS)
///   3. Initialize Firebase in main() before runApp()
///   4. Uncomment the implementation below and remove the stub
///
/// The repository layer (NotificationsRepositoryImpl.registerFcmToken) is
/// already wired to send the token to the backend once obtained.
class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();

  /// Call after successful login to register push token with backend.
  Future<void> initialize({
    required Future<void> Function(String token) onTokenObtained,
    required void Function(Map<String, dynamic> data) onMessage,
    required void Function(Map<String, dynamic> data) onMessageOpenedApp,
  }) async {
    // TODO: Uncomment when Firebase is configured
    //
    // await Firebase.initializeApp();
    // final messaging = FirebaseMessaging.instance;
    //
    // await messaging.requestPermission(
    //   alert: true, badge: true, sound: true,
    // );
    //
    // final token = await messaging.getToken();
    // if (token != null) await onTokenObtained(token);
    //
    // messaging.onTokenRefresh.listen(onTokenObtained);
    //
    // FirebaseMessaging.onMessage.listen((msg) {
    //   onMessage(msg.data);
    // });
    //
    // FirebaseMessaging.onMessageOpenedApp.listen((msg) {
    //   onMessageOpenedApp(msg.data);
    // });
  }
}
