import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _leaderboard = [];
  List<Map<String, dynamic>> _wrongWords = []; 
  bool _isLoading = false;

  List<Map<String, dynamic>> get leaderboard => _leaderboard;
  List<Map<String, dynamic>> get wrongWords => _wrongWords;
  bool get isLoading => _isLoading;

  Future<void> addXP(int amount) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDoc);
        if (!snapshot.exists) return;
        
        int currentXp = snapshot.data()?['xp'] ?? 0;
        transaction.update(userDoc, {
          'xp': currentXp + amount, 
        });
      });
    } catch (e) {
      debugPrint("Lỗi cộng XP: $e");
    }
  }

  Future<void> loadLeaderboard() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('xp', descending: true) 
          .limit(10)
          .get();
          
      _leaderboard = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'name': data['name'] ?? 'Học viên ẩn danh',
          'xp': data['xp'] ?? 0,
        };
      }).toList();
    } catch (e) {
      debugPrint("Lỗi tải BXH: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadWrongWords() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wrong_words')
          .orderBy('addedAt', descending: true)
          .get();
      _wrongWords = snapshot.docs.map((doc) => doc.data()).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Lỗi tải từ vựng sai: $e");
    }
  }

  Future<void> saveWrongWord(String word, String meaning, String pronunciation) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final wordData = {
        'word': word,
        'meaning': meaning,
        'pronunciation': pronunciation,
        'addedAt': Timestamp.now(),
      };
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wrong_words')
          .doc(word)
          .set(wordData);
      
      _wrongWords.removeWhere((element) => element['word'] == word);
      _wrongWords.insert(0, wordData);
      notifyListeners();
    } catch (e) {
      debugPrint("Lỗi lưu từ sai: $e");
    }
  }

  Future<void> removeWrongWord(String word) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wrong_words')
          .doc(word)
          .delete();
      _wrongWords.removeWhere((element) => element['word'] == word);
      notifyListeners();
    } catch (e) {
      debugPrint("Lỗi xóa từ sai: $e");
    }
  }

  bool _isCompletingLesson = false;

String? _lastCompletedLessonId;

Future<void> updateLessonCompletion({
  required String lessonId,
  required int totalWordsInLesson,
}) async {
  if (_isCompletingLesson) return;
  if (_lastCompletedLessonId == lessonId) return;

  _isCompletingLesson = true;
  _lastCompletedLessonId = lessonId;

  try {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDocRef = _firestore.collection('users').doc(user.uid);
    final doc = await userDocRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;

    // =====================
    // GET DATA
    // =====================
    List<String> completedLessons = List<String>.from(data['completedLessons'] ?? []);
    int wordsLearnedCount = data['wordsLearnedCount'] ?? 0;
    int xp = data['xp'] ?? 0;
    int dailyXpEarned = data['dailyXpEarned'] ?? 0;
    int dailyLessonsCompleted = data['dailyLessonsCompleted'] ?? 0;
    bool rewardMission1Claimed = data['rewardMission1Claimed'] ?? false;
    bool rewardMission2Claimed = data['rewardMission2Claimed'] ?? false;
    int streak = data['streak'] ?? 0;
    String lastActiveDate = data['lastActiveDate'] ?? '';
    String lastWeeklyResetDate = data['lastWeeklyResetDate'] ?? '';
    Map<String, dynamic> weeklyXp = Map<String, dynamic>.from(data['weeklyXp'] ?? {});

    // =====================
    // CHỐNG HỌC LẠI
    // =====================
    if (completedLessons.contains(lessonId)) {
      debugPrint("Lesson already completed");
      return;
    }

    // =====================
    // GENERATE TODAY STRING
    // =====================
    DateTime now = DateTime.now();
    DateTime todayDate = DateTime(now.year, now.month, now.day);
    String today = "${todayDate.year.toString().padLeft(4, '0')}-"
        "${todayDate.month.toString().padLeft(2, '0')}-"
        "${todayDate.day.toString().padLeft(2, '0')}";

    // =====================
    // LOGIC WEEKLY RESET (KHI ĐANG HỌC)
    // =====================
    bool shouldResetWeekly = false;
    if (lastWeeklyResetDate.isNotEmpty) {
      DateTime lastWeeklyDate = DateTime.parse(lastWeeklyResetDate);
      DateTime cleanWeeklyDate = DateTime(lastWeeklyDate.year, lastWeeklyDate.month, lastWeeklyDate.day);
      int diffWeekly = todayDate.difference(cleanWeeklyDate).inDays;
      if (diffWeekly >= 7) {
        shouldResetWeekly = true;
      }
    } else {
      shouldResetWeekly = true;
    }

    if (shouldResetWeekly) {
      weeklyXp = {'T2': 0, 'T3': 0, 'T4': 0, 'T5': 0, 'T6': 0, 'T7': 0, 'CN': 0};
      lastWeeklyResetDate = today; // CẬP NHẬT Ở ĐÂY: Chỉ cập nhật khi THỰC SỰ reset tuần
    }

    // =====================
    // LOGIC STREAK + DAILY RESET (KHI ĐANG HỌC)
    // =====================
    if (lastActiveDate.isNotEmpty) {
      DateTime parsedDate = DateTime.parse(lastActiveDate);
      DateTime cleanLastDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
      int difference = todayDate.difference(cleanLastDate).inDays;

      if (difference == 1) {
        // Học liên tiếp sang ngày hôm sau -> Tăng streak
        streak += 1;
        dailyXpEarned = 0;
        dailyLessonsCompleted = 0;
        rewardMission1Claimed = false;
        rewardMission2Claimed = false;
      } else if (difference > 1) {
        // Bỏ học nhiều ngày rồi mới quay lại -> Reset chuỗi về 1
        streak = 1;
        dailyXpEarned = 0;
        dailyLessonsCompleted = 0;
        rewardMission1Claimed = false;
        rewardMission2Claimed = false;
      }
      // Nếu difference == 0 (học tiếp bài thứ n trong ngày): Giữ nguyên streak và daily cũ
    } else {
      // Tài khoản mới tinh học bài đầu tiên
      streak = 1;
    }

    // =====================
    // CỘNG THÀNH TÍCH BÀI HỌC
    // =====================
    completedLessons.add(lessonId);
    const int lessonXp = 50;

    xp += lessonXp;
    dailyXpEarned += lessonXp;
    dailyLessonsCompleted += 1;
    wordsLearnedCount += totalWordsInLesson;

    // Daily Mission 1
    if (!rewardMission1Claimed && dailyLessonsCompleted >= 1) {
      xp += 50;
      rewardMission1Claimed = true;
    }

    // Daily Mission 2
    if (!rewardMission2Claimed && dailyXpEarned >= 200) {
      xp += 100;
      rewardMission2Claimed = true;
    }

    // Cập nhật Weekly XP
    List<String> weekdays = ["", "T2", "T3", "T4", "T5", "T6", "T7", "CN"];
    String currentWeekday = weekdays[now.weekday];
    weeklyXp[currentWeekday] = (weeklyXp[currentWeekday] ?? 0) + lessonXp;

    // =====================
    // UPDATE TO FIRESTORE
    // =====================
    await userDocRef.update({
      'xp': xp,
      'dailyXpEarned': dailyXpEarned,
      'dailyLessonsCompleted': dailyLessonsCompleted,
      'completedLessons': completedLessons,
      'wordsLearnedCount': wordsLearnedCount,
      'rewardMission1Claimed': rewardMission1Claimed,
      'rewardMission2Claimed': rewardMission2Claimed,
      'weeklyXp': weeklyXp,
      'streak': streak,
      'lastActiveDate': today,
      'lastWeeklyResetDate': lastWeeklyResetDate, // Đã sửa: không bị đè vô lý nữa
    });

    notifyListeners();
  } catch (e) {
    debugPrint("Update lesson error: $e");
  } finally {
    _isCompletingLesson = false;
    Future.delayed(const Duration(seconds: 2), () {
      _lastCompletedLessonId = null;
    });
  }
}

  Future<void> checkDailyReset() async {
  final uid = _auth.currentUser?.uid;
  if (uid == null) return;

  final userDoc = await _firestore.collection('users').doc(uid).get();
  if (!userDoc.exists) return;

  final data = userDoc.data() as Map<String, dynamic>;
  final lastActiveTimestamp = data['lastActive'] as Timestamp?;
  
  final now = DateTime.now();
  
  if (lastActiveTimestamp != null) {
    final lastActive = lastActiveTimestamp.toDate();
    
    // 1. KIỂM TRA RESET NGÀY (Cũ)
    final isDifferentDay = now.day != lastActive.day ||
                           now.month != lastActive.month ||
                           now.year != lastActive.year;

    if (isDifferentDay) {
      await _firestore.collection('users').doc(uid).update({
        'dailyXpEarned': 0,
        'lastActive': FieldValue.serverTimestamp(), // Cập nhật ngày hoạt động mới nhất
      });
    }

    // 2. LOGIC FIX LỖI: KIỂM TRA RESET TUẦN MỚI
    // Tìm ngày Thứ 2 của tuần trước và Thứ 2 của tuần này để so sánh
    DateTime lastMonday = lastActive.subtract(Duration(days: lastActive.weekday - 1));
    DateTime currentMonday = now.subtract(Duration(days: now.weekday - 1));
    
    // Đưa về mốc 00:00:00 giờ để so sánh chính xác ngày
    lastMonday = DateTime(lastMonday.year, lastMonday.month, lastMonday.day);
    currentMonday = DateTime(currentMonday.year, currentMonday.month, currentMonday.day);

    // Nếu Thứ 2 tuần này lớn hơn Thứ 2 của lần cuối online -> Đã sang tuần mới!
    if (currentMonday.isAfter(lastMonday)) {
      await _firestore.collection('users').doc(uid).update({
        'weeklyXp': {
          'T2': 0,
          'T3': 0,
          'T4': 0,
          'T5': 0,
          'T6': 0,
          'T7': 0,
          'CN': 0,
        }
      });
    }
  } else {
    // Nếu tài khoản mới tinh chưa có lastActive
    await _firestore.collection('users').doc(uid).update({
      'lastActive': FieldValue.serverTimestamp(),
    });
  }
}
  }