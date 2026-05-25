// File: lib/services/notification_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final String _notificationPrefKey = "is_daily_reminder_on";

  /// 1. KHỞI TẠO HỆ THỐNG THÔNG BÁO (Đã xóa sạch đống Timezone phức tạp)
  Future<void> initNotification() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );

      // Khởi tạo plugin
      await _localNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint("Người dùng đã bấm vào thông báo!");
        },
      );
      
      // Xin quyền sau khi khởi tạo xong
      await requestPermissions();
    } catch (e) {
      debugPrint("Lỗi khởi tạo thông báo: $e");
    }
  }

  /// 2. HÀM XIN QUYỀN THÔNG BÁO
  Future<void> requestPermissions() async {
    // Xin quyền Android
    final androidImplementation = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    // Xin quyền iOS
    final iosImplementation = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosImplementation != null) {
      try {
        await iosImplementation.requestPermissions(alert: true, badge: true, sound: true);
      } catch (e) {
        debugPrint("Bỏ qua xin quyền iOS trên thiết bị này: $e");
      }
    }
  }

  /// 3. ĐỌC / GHI TRẠNG THÁI BẬT TẮT XUỐNG MÁY (LOCAL SHREDPREFERENCES)
  Future<bool> isNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationPrefKey) ?? true; // Mặc định mở app lên là bật
  }

  Future<void> setNotificationStatus(bool turnOn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationPrefKey, turnOn);
    debugPrint("Trạng thái công tắc tổng được đổi thành: $turnOn");
  }

  /// 4. HÀM BẮN THÔNG BÁO CHÀO MỪNG (Duy nhất được sử dụng)
  Future<void> showWelcomeNotification(String userName) async {
    try {
      // Kiểm tra xem công tắc trong Profile có đang BẬT không
      bool isOn = await isNotificationEnabled();
      if (!isOn) {
        debugPrint("🚫 Công tắc thông báo đang TẮT, chặn hoàn toàn thông báo chào mừng.");
        return;
      }

      // Khai báo cấu hình hiển thị (Đúng đoạn code bạn giữ lại)
      const AndroidNotificationDetails androidDetailsImmediate = AndroidNotificationDetails(
        'welcome_channel', 
        'Chào mừng trở lại',          
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      );
      
      // Tiến hành nổ thông báo lên màn hình điện thoại ngay lập tức
      await _localNotificationsPlugin.show(
        999, 
        'Chào mừng trở lại! 🎉', 
        'Chào $userName, cùng nhau học tập chăm chỉ và tích lũy XP hôm nay nhé! 📚', 
        const NotificationDetails(android: androidDetailsImmediate),
      );
    } catch (e) {
      debugPrint("Lỗi bắn thông báo chào mừng: $e");
    }
  }
}