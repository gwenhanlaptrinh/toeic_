import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/vocabulary_model.dart';

class LibraryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream lắng nghe danh sách từ đã lưu của người dùng hiện tại theo thời gian thực
  Stream<List<String>> get savedWordNamesStream {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('saved_words')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  // Hàm lưu từ vựng vào Firebase
  Future<void> saveWord(VocabularyModel word) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved_words')
          .doc(word.word)
          .set({
        'word': word.word,
        'pronunciation': word.pronunciation,
        'meaning': word.meaning,
        'example': word.example,
        'audioUrl': word.audioUrl,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Lỗi khi lưu từ: $e");
    }
  }

  // Hàm XÓA từ vựng khỏi Firebase (Hủy lưu)
  Future<void> deleteWord(String wordName) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved_words')
          .doc(wordName)
          .delete();
    } catch (e) {
      debugPrint("Lỗi khi xóa từ: $e");
    }
  }
}