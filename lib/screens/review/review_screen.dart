import 'package:flutter/material.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ôn tập thông minh')),
      body: const Center(
        child: Text('Tính năng Spaced Repetition sẽ nằm ở đây!'),
      ),
    );
  }
}