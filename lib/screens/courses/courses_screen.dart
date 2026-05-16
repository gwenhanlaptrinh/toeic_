import 'package:flutter/material.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Khóa học')),
      body: const Center(
        child: Text('Danh sách khóa học sẽ nằm ở đây!'),
      ),
    );
  }
}