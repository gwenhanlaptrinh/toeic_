import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WordScrambleGame extends StatefulWidget {
  const WordScrambleGame({super.key});

  @override
  State<WordScrambleGame> createState() => _WordScrambleGameState();
}

class _WordScrambleGameState extends State<WordScrambleGame> {
  final List<Map<String, String>> _questions = [
    {'word': 'ECONOMY', 'hint': 'Nền kinh tế'},
    {'word': 'MEETING', 'hint': 'Cuộc họp'},
    {'word': 'BUDGET', 'hint': 'Ngân sách'},
    {'word': 'REPORT', 'hint': 'Báo cáo'},
    {'word': 'INVOICE', 'hint': 'Hóa đơn'},
    {'word': 'MANAGER', 'hint': 'Người quản lý'},
    {'word': 'CONTRACT', 'hint': 'Hợp đồng'},
    {'word': 'SCHEDULE', 'hint': 'Lịch trình'},
    {'word': 'CUSTOMER', 'hint': 'Khách hàng'},
    {'word': 'DEADLINE', 'hint': 'Hạn chót'},
  ];

  int _currentIndex = 0;
  int _score = 0;
  int _correctCount = 0;
  bool _isFinished = false;
  final _answerController = TextEditingController();
  String _scrambled = '';
  String? _feedback;
  bool? _isCorrect;

  @override
  void initState() {
    super.initState();
    _scrambleWord();
  }

  void _scrambleWord() {
    final word = _questions[_currentIndex]['word']!;
    final chars = word.split('');
    chars.shuffle(Random());
    // Đảm bảo scrambled khác word gốc
    while (chars.join() == word) {
      chars.shuffle(Random());
    }
    setState(() {
      _scrambled = chars.join();
      _feedback = null;
      _isCorrect = null;
      _answerController.clear();
    });
  }

  void _checkAnswer() {
    final answer = _answerController.text.trim().toUpperCase();
    final correct = _questions[_currentIndex]['word']!;
    final isRight = answer == correct;

    setState(() {
      _isCorrect = isRight;
      _feedback = isRight ? '✅ Chính xác!' : '❌ Sai rồi! Đáp án: $correct';
      if (isRight) {
        _score += 10;
        _correctCount++;
      }
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (_currentIndex < _questions.length - 1) {
        setState(() => _currentIndex++);
        _scrambleWord();
      } else {
        setState(() => _isFinished = true);
        _saveScore();
      }
    });
  }

  // SỬA HÀM _SAVESCORE THÀNH NHƯ SAU:
  void _saveScore() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;
    final passed = _correctCount >= (_questions.length * 0.7);
    if (passed) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
            'xp': FieldValue.increment(50),            
            'dailyXpEarned': FieldValue.increment(50), 
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) return _buildResult();
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔤 Word Scramble'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Progress
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: Colors.grey[200],
              color: const Color(0xFF1565C0),
            ),
            const SizedBox(height: 8),
            Text(
              'Câu ${_currentIndex + 1}/${_questions.length}  •  Điểm: $_score',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // Hint
            Text(
              '💡 ${_questions[_currentIndex]['hint']}',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Scrambled word
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _scrambled,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: Color(0xFF1565C0),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Input
            TextField(
              controller: _answerController,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, letterSpacing: 4),
              decoration: InputDecoration(
                hintText: 'Nhập đáp án...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _checkAnswer(),
            ),
            const SizedBox(height: 16),

            // Feedback
            if (_feedback != null)
              Text(
                _feedback!,
                style: TextStyle(
                  fontSize: 16,
                  color: _isCorrect == true ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const Spacer(),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _checkAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Xác nhận',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final passed = _correctCount >= (_questions.length * 0.7);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(passed ? '🎉' : '😢', style: const TextStyle(fontSize: 80)),
              const SizedBox(height: 16),
              Text(
                passed ? 'Xuất sắc! +50 XP' : 'Cố gắng hơn nhé!',
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Đúng $_correctCount/${_questions.length} câu',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Về trang chủ',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}