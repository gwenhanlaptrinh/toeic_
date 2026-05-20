import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool obscureText; // Đổi từ isPassword thành obscureText cho chuẩn Flutter
  final Widget? suffixIcon; // Thêm widget này để chứa nút con mắt ẩn/hiện mật khẩu

  const CustomTextField({
    super.key,
    required this.hint,
    required this.icon,
    required this.controller,
    this.obscureText = false, // Mặc định là hiện chữ (phù hợp cho Email)
    this.suffixIcon, // Không bắt buộc truyền vào
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText, // Sử dụng biến ở đây
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue),
        suffixIcon: suffixIcon, // Đưa suffixIcon vào trong cấu hình hiển thị
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
      ),
    );
  }
}