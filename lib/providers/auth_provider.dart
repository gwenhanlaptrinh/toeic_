import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _userModel;
  bool _isLoading = false;

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;

  AuthProvider() {
    // Lắng nghe trạng thái đăng nhập/đăng xuất của Firebase theo thời gian thực
    _authService.userStream.listen((User? user) async {
      if (user != null) {
        await fetchUserData(user.uid);
      } else {
        _userModel = null;
        notifyListeners();
      }
    });
  }

  // Đồng bộ dữ liệu người dùng từ Firestore về Model trong Flutter
  Future<void> fetchUserData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        _userModel = UserModel.fromMap(doc.data()!, doc.id);
      }
      notifyListeners();
    } catch (e) {
      print('Lỗi đồng bộ dữ liệu User: $e');
    }
  }

  // Xử lý logic Đăng nhập
  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.signIn(email, password);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Xử lý logic Đăng ký
  Future<void> signUp(String email, String password, String name) async {
    _setLoading(true);
    try {
      await _authService.signUp(email, password, name);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Xử lý logic Đăng xuất
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _userModel = null;
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}