import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:lucasbeatsfederacao/services/api_service.dart'; 
import 'dart:async';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final ApiService _apiService;

  final _onNotificationReceived = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onNotificationReceived => _onNotificationReceived.stream;

  // Tornando o construtor privado e usando um singleton para garantir uma única instância.
  NotificationService._privateConstructor(this._apiService);
  static final NotificationService _instance = NotificationService._privateConstructor(ApiService());

  factory NotificationService() {
    return _instance;
  }

  Future<void> initFirebaseMessaging() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
    }

    String? fcmToken = await _firebaseMessaging.getToken();
    print("FCM Token: $fcmToken");
    await sendFcmTokenToBackend(fcmToken);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');
      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
      _onNotificationReceived.add(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      // TODO: Implementar navegação ou lógica específica ao abrir a notificação
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('Handling a background message: ${message.messageId}');
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }

  Future<void> sendGlobalNotification(String title, String body) async {
    try {
      await _apiService.post('/api/notifications/global', {
        'title': title,
        'body': body,
      }, requireAuth: true);
      print('Notificação global enviada com sucesso para o backend.');
    } catch (e) {
      print('Erro ao enviar notificação global: $e');
      rethrow;
    }
  }

  // ==================== INÍCIO DA MODIFICAÇÃO ====================

  /// Envia uma notificação para todos os membros de um clã específico.
  Future<void> sendClanNotification(String clanId, String title, String body) async {
    try {
      await _apiService.post('/api/notifications/clan/$clanId', {
        'title': title,
        'body': body,
      }, requireAuth: true);
      print('Notificação para o clã $clanId enviada com sucesso para o backend.');
    } catch (e) {
      print('Erro ao enviar notificação para o clã $clanId: $e');
      rethrow;
    }
  }

  /// Envia uma notificação para todos os membros de uma federação específica.
  Future<void> sendFederationNotification(String federationId, String title, String body) async {
    try {
      await _apiService.post('/api/notifications/federation/$federationId', {
        'title': title,
        'body': body,
      }, requireAuth: true);
      print('Notificação para a federação $federationId enviada com sucesso para o backend.');
    } catch (e) {
      print('Erro ao enviar notificação para a federação $federationId: $e');
      rethrow;
    }
  }

  // ===================== FIM DA MODIFICAÇÃO ======================

  Future<void> sendInviteNotification(String userId, String clanId) async {
    try {
      await _apiService.post('/api/notifications/invite', {
        'targetUserId': userId, // Corrigido para 'targetUserId' conforme a rota
        'clanId': clanId,
      }, requireAuth: true);
      print('Convite de clã enviado com sucesso para o backend.');
    } catch (e) {
      print('Erro ao enviar convite de clã: $e');
      rethrow;
    }
  }

  Future<void> sendFcmTokenToBackend(String? fcmToken) async {
    if (fcmToken == null) return;
    try {
      await _apiService.post(
        '/api/users/fcm-token',
        {'fcmToken': fcmToken},
        requireAuth: true, // Adicionado para consistência
      );
      print('FCM Token enviado para o backend com sucesso.');
    } catch (e) {
      print('Erro ao enviar FCM Token para o backend: $e');
    }
  }

  void dispose() {
    _onNotificationReceived.close();
  }
}
