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

  // Gọi hàm này khi người dùng nhấn nút "Hoàn thành" bài học ở màn hình Quiz
  bool _isCompletingLesson = false;

Future<void> updateLessonCompletion({
  required String lessonId,
  required int totalWordsInLesson,
}) async {
  // CHỐNG GỌI HÀM 2 LẦN
  if (_isCompletingLesson) return;
  _isCompletingLesson = true;

  final user = _auth.currentUser;

  if (user == null) {
    _isCompletingLesson = false;
    return;
  }

  try {
    final userDocRef = _firestore.collection('users').doc(user.uid);

    final doc = await userDocRef.get();

    if (!doc.exists) {
      _isCompletingLesson = false;
      return;
    }

    final data = doc.data()!;

    List<dynamic> completedLessons =
        List<dynamic>.from(data['completedLessons'] ?? []);

    int wordsLearnedCount = data['wordsLearnedCount'] ?? 0;
    int xp = data['xp'] ?? 0;
    int dailyXpEarned = data['dailyXpEarned'] ?? 0;
    int dailyLessonsCompleted = data['dailyLessonsCompleted'] ?? 0;

    bool reward1Claimed =
        data['rewardMission1Claimed'] ?? false;

    bool reward2Claimed =
        data['rewardMission2Claimed'] ?? false;

    Map<String, dynamic> weeklyXp =
        Map<String, dynamic>.from(data['weeklyXp'] ?? {});

    // KHÔNG CHO HOÀN THÀNH LẠI BÀI ĐÃ HỌC
    if (completedLessons.contains(lessonId)) {
      debugPrint("Lesson already completed");
      _isCompletingLesson = false;
      return;
    }

    // =========================
    // CỘNG XP BÀI HỌC
    // =========================

    const int lessonXp = 50;

    xp += lessonXp;
    dailyXpEarned += lessonXp;
    dailyLessonsCompleted += 1;

    completedLessons.add(lessonId);

    wordsLearnedCount += totalWordsInLesson;

    // =========================
    // MISSION 1
    // Chỉ đánh dấu hoàn thành
    // KHÔNG cộng thêm XP
    // =========================

    if (dailyLessonsCompleted >= 1 &&
        !reward1Claimed) {
      reward1Claimed = true;
    }

    // =========================
    // MISSION 2
    // ĐỦ 200 XP -> +100 XP
    // =========================

    if (dailyXpEarned >= 200 &&
        !reward2Claimed) {
      xp += 100;
      reward2Claimed = true;

      debugPrint("MISSION 2 +100 XP");
    }

    // =========================
    // UPDATE BIỂU ĐỒ TUẦN
    // =========================

    List<String> weekdays = [
      "",
      "T2",
      "T3",
      "T4",
      "T5",
      "T6",
      "T7",
      "CN"
    ];

    String currentWeekday =
        weekdays[DateTime.now().weekday];

    weeklyXp[currentWeekday] =
        (weeklyXp[currentWeekday] ?? 0) + lessonXp;

    // Nếu mission 2 được nhận thì cộng thêm 100 vào biểu đồ
    if (dailyXpEarned >= 200 && reward2Claimed) {
      weeklyXp[currentWeekday] += 100;
    }

    // =========================
    // UPDATE FIRESTORE
    // =========================

    await userDocRef.update({
      'xp': xp,
      'dailyXpEarned': dailyXpEarned,
      'dailyLessonsCompleted': dailyLessonsCompleted,
      'completedLessons': completedLessons,
      'wordsLearnedCount': wordsLearnedCount,
      'rewardMission1Claimed': reward1Claimed,
      'rewardMission2Claimed': reward2Claimed,
      'weeklyXp': weeklyXp,
    });

    debugPrint("Lesson completed successfully");

    notifyListeners();
  } catch (e) {
    debugPrint("Lỗi cập nhật hoàn thành bài học: $e");
  } finally {
    _isCompletingLesson = false;
  }
}
}