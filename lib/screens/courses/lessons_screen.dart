// File: lib/screens/courses/lessons_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/course_provider.dart';
import 'flashcard_screen.dart';

class LessonsScreen extends StatefulWidget {
  final String topicTitle;
  final String topicId;

  const LessonsScreen({
    super.key,
    required this.topicTitle,
    required this.topicId,
  });

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadLessons(widget.topicId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.topicTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<CourseProvider>(
        builder: (context, courseProvider, child) {
          if (courseProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (courseProvider.currentLessons.isEmpty) {
            return const Center(
              child: Text('Chưa có bài học nào.', style: TextStyle(fontSize: 16)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courseProvider.currentLessons.length,
            itemBuilder: (context, index) {
              final lesson = courseProvider.currentLessons[index];

              // LOGIC MỞ KHÓA (Yêu cầu 3): Câu đầu tiên mở, hoặc câu trước đó đã hoàn thành
              bool isUnlocked = index == 0 || courseProvider.currentLessons[index - 1].isCompleted;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: isUnlocked ? 2 : 0,
                color: isUnlocked ? Colors.white : Colors.grey.shade200, // Đổi màu nền nếu bị khóa
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: !isUnlocked
                        ? Colors.grey.shade300
                        : (lesson.isCompleted ? Colors.green.shade100 : Colors.blue.shade50),
                    child: Icon(
                      !isUnlocked 
                          ? Icons.lock_rounded // Icon Khóa
                          : (lesson.isCompleted ? Icons.check_circle_rounded : Icons.play_lesson_rounded),
                      color: !isUnlocked ? Colors.grey : (lesson.isCompleted ? Colors.green : Colors.blue),
                    ),
                  ),
                  title: Text(
                    lesson.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? Colors.black87 : Colors.grey, // Làm mờ chữ nếu khóa
                    ),
                  ),
                  subtitle: Text(
                    !isUnlocked 
                        ? 'Bị khóa (Hãy hoàn thành bài trước)' 
                        : (lesson.isCompleted ? 'Đã hoàn thành' : 'Sẵn sàng học'),
                    style: TextStyle(
                      color: !isUnlocked ? Colors.grey : (lesson.isCompleted ? Colors.green : Colors.blue.shade700),
                      fontSize: 13,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: isUnlocked ? Colors.grey : Colors.transparent,
                  ),
                  onTap: isUnlocked
                      ? () async {
                          final navigator = Navigator.of(context);
                          await context.read<CourseProvider>().loadFlashcards(lesson.id);
                          navigator.push(
                            MaterialPageRoute(
                              builder: (context) => FlashcardScreen(
                                lessonTitle: lesson.title,
                                lessonId: lesson.id,
                              ),
                            ),
                          );
                        }
                      : null, // Không cho click bấm nếu chưa mở khóa
                ),
              );
            },
          );
        },
      ),
    );
  }
}