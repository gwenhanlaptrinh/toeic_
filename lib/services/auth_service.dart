import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Đăng kí → lưu thêm vào Firestore
  Future<UserCredential?> register(
    String email,
    String password,
    String name,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Lưu thông tin user vào Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email,
        'createdAt': Timestamp.now(),
        'totalScore': 0, 
        'streak': 0, 
        'lastLoginDate': Timestamp.now(),
        'totalWordsLearned': 0, 
        'level': 'beginner',
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Đăng kí thất bại';
    }
  }

  // Đăng nhập
  Future<UserCredential?> login(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Đăng nhập thất bại';
    }
  }

  // Lấy thông tin user từ Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
  try {
    DocumentSnapshot doc =
        await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>?;
    }
    return null;
  } catch (e) {
    print('Lỗi getUserData: $e');
    return null;
  }
}

  // Đăng xuất
  Future<void> logout() async => await _auth.signOut();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
