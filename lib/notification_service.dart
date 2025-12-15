import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Để dùng kIsWeb

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    try {
      // Cố gắng set múi giờ VN, nếu lỗi thì bỏ qua
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    } catch (e) {
      debugPrint('Lỗi set múi giờ: $e');
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notificationsPlugin.initialize(settings);

    if (!kIsWeb) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  // --- HÀM HẸN GIỜ THÔNG BÁO CỤ THỂ ---
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (kIsWeb) return; // Web không hỗ trợ hẹn giờ

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'calendar_channel', // ID kênh riêng cho lịch
          'Lịch nhắc nhở',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      //uiLocalNotificationDateInterpretation:
      //    UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
  
  // Hàm hủy thông báo theo ID (nếu cần xóa giao dịch thì xóa luôn thông báo)
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}