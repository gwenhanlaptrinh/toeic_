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

  // ==========================================
  // 1. HÀM KIỂM TRA VÀ RESET NGÀY/TUẦN (TỔNG TƯ LỆNH)
  // ==========================================
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

      // ------------ LOGIC RESET NGÀY ------------
      if (lastActiveDate.isNotEmpty) {
        DateTime lastDate = DateTime.parse(lastActiveDate);
        DateTime cleanLastDate = DateTime(lastDate.year, lastDate.month, lastDate.day);
        int difference = todayDate.difference(cleanLastDate).inDays;

        if (difference >= 1) {
          // Thực sự qua ngày mới -> Reset sạch tiến độ nhiệm vụ ngày
          updates['dailyXpEarned'] = 0;
          updates['dailyLessonsCompleted'] = 0;
          updates['rewardMission1Claimed'] = false;
          updates['rewardMission2Claimed'] = false;

          // Nếu bỏ học QUÁ 1 NGÀY (difference > 1) -> Reset chuỗi streak về 0
          if (difference > 1) {
            updates['streak'] = 0;
          }

          // ✨ QUAN TRỌNG NHẤT: Đóng dấu ngày hôm nay để không bị reset trùng lặp nữa
          updates['lastActiveDate'] = today;
        }
      } else {
        // Tài khoản mới tinh lần đầu mở app
        updates['lastActiveDate'] = today;
        updates['streak'] = 0;
      }

      // ------------ LOGIC RESET TUẦN ------------
      bool shouldResetWeekly = false;
      if (lastWeeklyResetDate.isNotEmpty) {
        DateTime lastReset = DateTime.parse(lastWeeklyResetDate);
        DateTime cleanResetDate = DateTime(lastReset.year, lastReset.month, lastReset.day);
        int diffWeekly = todayDate.difference(cleanResetDate).inDays;
        if (diffWeekly >= 7) {
          shouldResetWeekly = true;
        }
      } else {
        shouldResetWeekly = true;
      }

      if (shouldResetWeekly) {
        updates['weeklyXp'] = {'T2': 0, 'T3': 0, 'T4': 0, 'T5': 0, 'T6': 0, 'T7': 0, 'CN': 0};
        updates['lastWeeklyResetDate'] = today;
      }

      // Nếu có bất kỳ thay đổi nào thì mới update lên Firestore
      if (updates.isNotEmpty) {
        await userDocRef.update(updates);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("checkDailyReset error: $e");
    }
  }

  // ==========================================
  // 2. HÀM CẬP NHẬT KHI HOÀN THÀNH BÀI HỌC
  // ==========================================
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

      // ✨ BƯỚC THẦN THÁNH: Gọi checkDailyReset trước để dọn dẹp ngày mới (nếu có)
      // Giúp giải quyết triệt để trường hợp học xuyên đêm qua khung 12h đêm
      await checkDailyReset();

      final userDocRef = _firestore.collection('users').doc(user.uid);
      final doc = await userDocRef.get();
      if (!doc.exists) return;

      final data = doc.data()!;
      List<String> completedLessons = List<String>.from(data['completedLessons'] ?? []);

      // CHỐNG HỌC LẠI BÀI CŨ
      if (completedLessons.contains(lessonId)) {
        debugPrint("Lesson already completed");
        return;
      }

      // Lấy dữ liệu mới nhất (đã được dọn dẹp sạch sẽ từ hàm check trên)
      int wordsLearnedCount = data['wordsLearnedCount'] ?? 0;
      int xp = data['xp'] ?? 0;
      int dailyXpEarned = data['dailyXpEarned'] ?? 0;
      int dailyLessonsCompleted = data['dailyLessonsCompleted'] ?? 0;
      bool rewardMission1Claimed = data['rewardMission1Claimed'] ?? false;
      bool rewardMission2Claimed = data['rewardMission2Claimed'] ?? false;
      int streak = data['streak'] ?? 0;
      Map<String, dynamic> weeklyXp = Map<String, dynamic>.from(data['weeklyXp'] ?? {});

      // ✨ TĂNG STREAK: Nếu hôm nay chưa học bài nào (dailyLessonsCompleted == 0) thì tăng chuỗi lên 1
      if (dailyLessonsCompleted == 0) {
        streak += 1;
      }

      // CỘNG THÀNH TÍCH BÀI HỌC VỪA XONG
      completedLessons.add(lessonId);
      const int lessonXp = 50;

      xp += lessonXp;
      dailyXpEarned += lessonXp;
      dailyLessonsCompleted += 1;
      wordsLearnedCount += totalWordsInLesson;

      // Kiểm tra Nhiệm vụ 1 (Hoàn thành 1 bài học)
      if (!rewardMission1Claimed && dailyLessonsCompleted >= 1) {
        xp += 50;
        rewardMission1Claimed = true;
      }

      // Kiểm tra Nhiệm vụ 2 (Tích lũy đủ 200 XP)
      if (!rewardMission2Claimed && dailyXpEarned >= 200) {
        xp += 100;
        rewardMission2Claimed = true;
      }

      // Cập nhật biểu đồ Weekly XP tuần
      DateTime now = DateTime.now();
      List<String> weekdays = ["", "T2", "T3", "T4", "T5", "T6", "T7", "CN"];
      String currentWeekday = weekdays[now.weekday];
      weeklyXp[currentWeekday] = (weeklyXp[currentWeekday] ?? 0) + lessonXp;

      // Tạo chuỗi ngày hôm nay để đồng bộ DB
      DateTime todayDate = DateTime(now.year, now.month, now.day);
      String today = "${todayDate.year.toString().padLeft(4, '0')}-"
          "${todayDate.month.toString().padLeft(2, '0')}-"
          "${todayDate.day.toString().padLeft(2, '0')}";

      // UPDATE TO FIRESTORE
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
}