// File: lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream lắng nghe trạng thái đăng nhập
  Stream<User?> get userStream => _auth.authStateChanges();

  // Đăng ký tài khoản + Tạo Document trên Firestore
  Future<UserCredential> signUp(String email, String password, String name) async {
    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email, 
      password: password
    );

    // ĐÃ SỬA: Đổi 'totalScore' thành 'xp' để đồng bộ hệ thống điểm mới
    await _db.collection('users').doc(cred.user!.uid).set({
      'email': email,
      'name': name,
      'streak': 0,
      'xp': 0, 
      'isPlus': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return cred;
  }

  // Đăng nhập
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Đăng xuất
  Future<void> signOut() async => await _auth.signOut();
}