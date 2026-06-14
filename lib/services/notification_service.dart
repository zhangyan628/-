import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/question.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  
  static Future<void> initialize() async {
    if (_initialized) return;
    
    // 初始化时区数据
    tz_data.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    await _notifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
    
    _initialized = true;
  }
  
  static Future<void> scheduleReminder(Question question) async {
    if (question.reminderAt == null) return;
    
    final androidDetails = AndroidNotificationDetails(
      'question_reminders',
      '问题提醒',
      channelDescription: '提醒您处理待办问题',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    
    final scheduledDate = tz.TZDateTime.from(question.reminderAt!, tz.local);
    
    // 如果提醒时间已过，不设置
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;
    
    await _notifications.zonedSchedule(
      question.id.hashCode,
      '问题提醒',
      question.content,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: _getRepeatMode(question.reminderRepeat),
    );
  }
  
  static Future<void> cancelReminder(String questionId) async {
    await _notifications.cancel(questionId.hashCode);
  }
  
  static Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }
  
  static DateTimeComponents? _getRepeatMode(String? repeat) {
    switch (repeat) {
      case 'daily':
        return DateTimeComponents.time;
      case 'weekly':
        return DateTimeComponents.dayOfWeekAndTime;
      case 'monthly':
        return DateTimeComponents.dayOfMonthAndTime;
      default:
        return null;
    }
  }
  
  // 请求权限（iOS需要）
  static Future<bool> requestPermissions() async {
    final result = await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    return result ?? true;
  }
}
