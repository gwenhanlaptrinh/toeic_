// File: lib/providers/course_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/course_models.dart';

class CourseProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<TopicModel> _topics = [];
  List<LessonModel> _currentLessons = [];
  List<FlashcardModel> _currentFlashcards = [];
  bool _isLoading = false;

  List<TopicModel> get topics => _topics;
  List<LessonModel> get currentLessons => _currentLessons;
  List<FlashcardModel> get currentFlashcards => _currentFlashcards;
  bool get isLoading => _isLoading;

  // 1. Tải danh sách Chủ đề + Tính % Tiến Độ Thật
  Future<void> loadTopics() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _auth.currentUser?.uid;
      final topicSnapshot = await _firestore.collection('topics').get();
      
      List<String> completedLessonIds = [];
      if (userId != null) {
        final progressSnapshot = await _firestore
            .collection('user_progress')
            .where('uid', isEqualTo: userId)
            .get();
        
        // Lọc bằng Dart để tránh lỗi Index Firebase
        completedLessonIds = progressSnapshot.docs
            .where((doc) => doc.data()['isCompleted'] == true)
            .map((doc) => doc.data()['lessonId'].toString())
            .toList();
      }

      List<TopicModel> tempTopics = [];

      for (var doc in topicSnapshot.docs) {
        final data = doc.data();
        final topicId = doc.id;

        final lessonsSnapshot = await _firestore
            .collection('lessons')
            .where('topicId', isEqualTo: topicId)
            .get();
        
        int totalLessons = lessonsSnapshot.docs.length;
        int completedLessons = 0;

        for (var lDoc in lessonsSnapshot.docs) {
          if (completedLessonIds.contains(lDoc.id)) {
            completedLessons++;
          }
        }

        double calcProgress = totalLessons > 0 ? (completedLessons / totalLessons) : 0.0;

        tempTopics.add(TopicModel(
          id: topicId,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          icon: data['icon'] ?? 'school',
          progress: calcProgress,
        ));
      }

      _topics = tempTopics;
    } catch (e) {
      debugPrint("Lỗi tải Topics: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. Tải danh sách bài học
  Future<void> loadLessons(String topicId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _auth.currentUser?.uid;
      final lessonSnapshot = await _firestore
          .collection('lessons')
          .where('topicId', isEqualTo: topicId)
          .get();

      List<String> completedLessonIds = [];
      if (userId != null) {
        final progressSnapshot = await _firestore
            .collection('user_progress')
            .where('uid', isEqualTo: userId)
            .get();
            
        completedLessonIds = progressSnapshot.docs
            .where((doc) => doc.data()['isCompleted'] == true)
            .map((doc) => doc.data()['lessonId'].toString())
            .toList();
      }

      _currentLessons = lessonSnapshot.docs.map((doc) {
        final data = doc.data();
        return LessonModel(
          id: doc.id,
          topicId: data['topicId'] ?? '',
          title: data['title'] ?? '',
          order: data['order'] ?? 0,
          isCompleted: completedLessonIds.contains(doc.id),
        );
      }).toList();

      // Sắp xếp thứ tự bài học tăng dần theo trường 'order'
      _currentLessons.sort((a, b) => a.order.compareTo(b.order));
    } catch (e) {
      debugPrint("Lỗi tải Lessons: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 3. Tải danh sách Flashcards
  Future<void> loadFlashcards(String lessonId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('flashcards')
          .where('lessonId', isEqualTo: lessonId)
          .get();

      _currentFlashcards = snapshot.docs.map((doc) {
        final data = doc.data();
        return FlashcardModel(
          id: doc.id,
          word: data['word'] ?? '',
          meaning: data['meaning'] ?? '',
          pronunciation: data['pronunciation'] ?? '',
          example: data['example'] ?? 'No example provided.', // Áp dụng trường mới
          options: List<String>.from(data['options'] ?? []),
          correctAnswerIndex: data['correctAnswerIndex'] ?? 0,
        );
      }).toList();
    } catch (e) {
      debugPrint("Lỗi tải Flashcards: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 4. XỬ LÝ HOÀN THÀNH BÀI HỌC (Yêu cầu 1 + 2)
  Future<void> completeLesson(String lessonId, String topicId, int xpReward) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Bước A: Lưu/Cập nhật bảng user_progress thành công
      final progressQuery = await _firestore
          .collection('user_progress')
          .where('uid', isEqualTo: userId)
          .where('lessonId', isEqualTo: lessonId)
          .get();

      if (progressQuery.docs.isEmpty) {
        await _firestore.collection('user_progress').add({
          'uid': userId,
          'lessonId': lessonId,
          'isCompleted': true,
          'completedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore
            .collection('user_progress')
            .doc(progressQuery.docs.first.id)
            .update({'isCompleted': true});
      }

      // Bước B: Cộng điểm kinh nghiệm XP vào thông tin User để hiển thị BXH
      final userDoc = _firestore.collection('users').doc(userId);
      final userSnapshot = await userDoc.get();
      if (userSnapshot.exists) {
        await userDoc.update({
          'xp': FieldValue.increment(xpReward),
        });
      } else {
        // Tạo nếu chưa có tài khoản user trong bảng users
        await userDoc.set({
          'uid': userId,
          'name': _auth.currentUser?.displayName ?? 'Học viên ẩn danh',
          'email': _auth.currentUser?.email ?? '',
          'avatar': _auth.currentUser?.photoURL ?? '',
          'xp': xpReward,
        });
      }

      // Bước C: Tự động tải lại dữ liệu tức thì để cập nhật thanh tiến độ % hiển thị ở Topic Screen
      await loadLessons(topicId);
      await loadTopics();
    } catch (e) {
      debugPrint("Lỗi đồng bộ completeLesson: $e");
    }
  }
}