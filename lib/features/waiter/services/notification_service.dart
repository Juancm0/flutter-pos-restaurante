import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sistema_eve/features/waiter/data/models/order_model.dart';

/// Servicio para manejar notificaciones locales
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Inicializar notificaciones
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
  }

  /// Solicitar permisos (Android 13+)
  Future<bool> requestPermissions() async {
    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      return granted ?? false;
    }

    final iosImpl = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  /// Mostrar notificación de orden lista
  Future<void> showOrderReadyNotification(OrderModel order) async {
    const androidDetails = AndroidNotificationDetails(
      'orders_ready',
      'Órdenes Listas',
      channelDescription: 'Notificaciones cuando una orden está lista',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = order.orderType == OrderType.takeout
        ? '🛍️ Orden Para Llevar Lista'
        : '🍽️ Orden de Mesa Lista';

    final body = order.orderType == OrderType.takeout
        ? 'Orden #${order.orderNumber}${order.customerName != null ? " - ${order.customerName}" : ""} está lista para entregar'
        : 'Orden #${order.orderNumber} de Mesa ${order.tableNumber} lista para servir';

    await _notifications.show(order.orderNumber.hashCode, title, body, details);
  }
}
