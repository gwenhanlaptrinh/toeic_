import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'providers/dictionary_provider.dart';
import 'providers/library_provider.dart';
import 'providers/course_provider.dart';
import 'providers/user_provider.dart';
import 'services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Khởi tạo kết nối hệ sinh thái Firebase backend
  await NotificationService().initNotification();
  // BẬT CHẾ ĐỘ OFFLINE CHO FIRESTORE
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true, // Kích hoạt lưu trữ cục bộ
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // Không giới hạn dung lượng cache (hoặc set 10485760 cho 10MB)
  );
  runApp(
    MultiProvider(
      providers: [
        // Bơm AuthProvider vào gốc cây widget để mọi view con đều đọc được trạng thái đăng nhập
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DictionaryProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TOEIC Learning App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SplashScreen(), // Điểm khởi đầu kiểm soát định tuyến thông minh
    );
  }
}