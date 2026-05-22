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
  try {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDocRef = _firestore.collection('users').doc(user.uid);
    final doc = await userDocRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    String lastActiveDate = data['lastActiveDate'] ?? '';
    String lastWeeklyResetDate = data['lastWeeklyResetDate'] ?? '';

    DateTime now = DateTime.now();
    DateTime todayDate = DateTime(now.year, now.month, now.day);
    String today = "${todayDate.year.toString().padLeft(4, '0')}-"
        "${todayDate.month.toString().padLeft(2, '0')}-"
        "${todayDate.day.toString().padLeft(2, '0')}";

    Map<String, dynamic> updates = {};

    // =====================
    // DAILY RESET & STREAK CHECK
    // =====================
    if (lastActiveDate.isNotEmpty) {
      DateTime lastDate = DateTime.parse(lastActiveDate);
      DateTime cleanLastDate = DateTime(lastDate.year, lastDate.month, lastDate.day);
      int difference = todayDate.difference(cleanLastDate).inDays;

      // Hễ cứ qua ngày mới (>= 1) là reset tiến trình nhiệm vụ ngày
      if (difference >= 1) {
        updates['dailyXpEarned'] = 0;
        updates['dailyLessonsCompleted'] = 0;
        updates['rewardMission1Claimed'] = false;
        updates['rewardMission2Claimed'] = false;
      }

      // NẾU BỎ QUÁ 1 NGÀY: Reset chuỗi streak về 0 ngay trên màn hình chính
      if (difference > 1) {
        updates['streak'] = 0;
      }
    }

    // =====================
    // WEEKLY RESET
    // =====================
    bool shouldResetWeekly = false;
    if (lastWeeklyResetDate.isNotEmpty) {
      DateTime lastReset = DateTime.parse(lastWeeklyResetDate);
      DateTime cleanResetDate = DateTime(lastReset.year, lastReset.month, lastReset.day);
      int difference = todayDate.difference(cleanResetDate).inDays;

      if (difference >= 7) {
        shouldResetWeekly = true;
      }
    } else {
      shouldResetWeekly = true;
    }

    if (shouldResetWeekly) {
      updates['weeklyXp'] = {'T2': 0, 'T3': 0, 'T4': 0, 'T5': 0, 'T6': 0, 'T7': 0, 'CN': 0};
      updates['lastWeeklyResetDate'] = today;
    }

    // =====================
    // UPDATE FIRESTORE
    // =====================
    if (updates.isNotEmpty) {
      await userDocRef.update(updates);
      notifyListeners();
    }
  } catch (e) {
    debugPrint("checkDailyReset error: $e");
  }
}
  }