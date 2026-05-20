// File: lib/services/course_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_models.dart';

class CourseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Lấy danh sách Chủ đề
  Future<List<TopicModel>> getTopics() async {
    try {
      final snapshot = await _firestore.collection('topics').get();

      return snapshot.docs
          .map((doc) => TopicModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi tải danh sách chủ đề: $e');
    }
  }

  // 2. Lấy danh sách Bài học
  Future<List<LessonModel>> getLessonsByTopic(String topicId) async {
    try {
      final snapshot = await _firestore
          .collection('lessons')
          .where('topicId', isEqualTo: topicId)
          .get();

      List<LessonModel> lessons = snapshot.docs
          .map((doc) => LessonModel.fromMap(
                doc.data(), 
                doc.id, 
                topicId: topicId, // SỬA LỖI TẠI ĐÂY: Dùng named parameter 'topicId:' thay vì truyền thẳng
              ))
          .toList();

      lessons.sort((a, b) => a.order.compareTo(b.order));
      return lessons;
    } catch (e) {
      throw Exception('Lỗi khi tải danh sách bài học: $e');
    }
  }

  // 3. Lấy danh sách Flashcards
  Future<List<FlashcardModel>> getFlashcardsByLesson(String lessonId) async {
    try {
      final snapshot = await _firestore
          .collection('flashcards')
          .where('lessonId', isEqualTo: lessonId)
          .get();

      return snapshot.docs
          .map((doc) => FlashcardModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi tải danh sách từ vựng: $e');
    }
  }
}