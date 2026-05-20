// File: lib/screens/courses/flashcard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Đừng quên cài package này
import '../../providers/course_provider.dart';
import 'quiz_screen.dart';

class FlashcardScreen extends StatefulWidget {
  final String lessonTitle;
  final String lessonId;

  const FlashcardScreen({
    super.key,
    required this.lessonTitle,
    required this.lessonId,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  int _currentIndex = 0;
  bool _showMeaning = false;
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTTS();
  }

  void _initTTS() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.45); // Tốc độ vừa phải dễ nghe
  }

  void _speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.lessonTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<CourseProvider>(
        builder: (context, courseProvider, child) {
          if (courseProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (courseProvider.currentFlashcards.isEmpty) {
            return const Center(child: Text('Chưa có từ vựng nào.'));
          }

          final currentCard = courseProvider.currentFlashcards[_currentIndex];
          final totalCards = courseProvider.currentFlashcards.length;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (_currentIndex + 1) / totalCards,
                  backgroundColor: Colors.grey.shade300,
                  color: Colors.blue,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(height: 12),
                Text('Từ ${_currentIndex + 1} / $totalCards', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 20),

                // Thẻ lật từ vựng
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showMeaning = !_showMeaning;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _showMeaning ? Colors.blue.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.blue.shade200, width: 2),
                        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, spreadRadius: 2)],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!_showMeaning) ...[
                            // MẶT TRƯỚC
                            Text(currentCard.word, style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.blue)),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('/${currentCard.pronunciation}/', style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.volume_up_rounded, color: Colors.blue, size: 28),
                                  onPressed: () => _speak(currentCard.word), // Phát âm giọng đọc Mỹ
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            Text('💡 Chạm để lật xem nghĩa & ví dụ', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                          ] else ...[
                            // MẶT SAU (Yêu cầu 4): Nghĩa + Câu ví dụ
                            const Text('Ý NGHĨA', style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            const SizedBox(height: 8),
                            Text(currentCard.meaning, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 30),
                            const Divider(color: Colors.blue, thickness: 1, indent: 40, endIndent: 40),
                            const SizedBox(height: 16),
                            const Text('VÍ DỤ (EXAMPLE)', style: TextStyle(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                currentCard.example,
                                style: TextStyle(fontSize: 16, color: Colors.grey.shade800, fontStyle: FontStyle.italic),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 30),
                            Text('✨ Chạm để quay lại mặt chữ', style: TextStyle(color: Colors.blue.shade300, fontSize: 13)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Điều hướng
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton.filledTonal(
                      onPressed: _currentIndex > 0 ? () => setState(() { _currentIndex--; _showMeaning = false; }) : null,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    if (_currentIndex == totalCards - 1)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuizScreen(lessonTitle: widget.lessonTitle, lessonId: widget.lessonId),
                            ),
                          );
                        },
                        icon: const Icon(Icons.quiz_rounded, color: Colors.white),
                        label: const Text('Làm Bài Kiểm Tra', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )
                    else
                      const Text('Lướt xem hết từ để mở khóa bài test', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    IconButton.filledTonal(
                      onPressed: _currentIndex < totalCards - 1 ? () => setState(() { _currentIndex++; _showMeaning = false; }) : null,
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}