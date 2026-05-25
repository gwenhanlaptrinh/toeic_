import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WordMatchGame extends StatefulWidget {
  const WordMatchGame({super.key});

  @override
  State<WordMatchGame> createState() => _WordMatchGameState();
}

class _WordMatchGameState extends State<WordMatchGame> {
  final List<Map<String, String>> _allPairs = [
    {'en': 'Meeting', 'vi': 'Cuộc họp'},
    {'en': 'Invoice', 'vi': 'Hóa đơn'},
    {'en': 'Budget', 'vi': 'Ngân sách'},
    {'en': 'Contract', 'vi': 'Hợp đồng'},
    {'en': 'Deadline', 'vi': 'Hạn chót'},
    {'en': 'Manager', 'vi': 'Quản lý'},
    {'en': 'Report', 'vi': 'Báo cáo'},
    {'en': 'Schedule', 'vi': 'Lịch trình'},
  ];

  late List<Map<String, String>> _currentPairs;
  late List<String> _enWords;
  late List<String> _viWords;
  String? _selectedEn;
  Map<String, String> _matched = {};
  Map<String, bool> _wrongPairs = {};
  int _score = 0;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _loadRound();
  }

  void _loadRound() {
    _allPairs.shuffle();
    _currentPairs = _allPairs.take(4).toList();
    _enWords = _currentPairs.map((e) => e['en']!).toList()..shuffle();
    _viWords = _currentPairs.map((e) => e['vi']!).toList()..shuffle();
    _matched = {};
    _wrongPairs = {};
    _selectedEn = null;
  }

  void _onSelectEn(String word) {
    if (_matched.containsKey(word)) return;
    setState(() => _selectedEn = word);
  }

  void _onSelectVi(String meaning) {
    if (_selectedEn == null) return;
    final correctPair = _currentPairs.firstWhere(
      (p) => p['en'] == _selectedEn,
      orElse: () => {},
    );

    if (correctPair['vi'] == meaning) {
      setState(() {
        _matched[_selectedEn!] = meaning;
        _score += 10;
        _selectedEn = null;
      });
      if (_matched.length == _currentPairs.length) {
        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() => _isFinished = true);
          _saveScore();
        });
      }
    } else {
      setState(() {
        _wrongPairs[_selectedEn!] = true;
        _selectedEn = null;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        setState(() => _wrongPairs.clear());
      });
    }
  }

  void _saveScore() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;
    final percent = _score / (_currentPairs.length * 10);
    if (percent >= 0.7) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
            'xp': FieldValue.increment(50),             // Cộng vào tổng XP gộp
            'dailyXpEarned': FieldValue.increment(50),  // Cộng vào XP tiến trình ngày
          });
    }
  }

  Color _getEnColor(String word) {
    if (_matched.containsKey(word)) return Colors.green;
    if (_wrongPairs.containsKey(word)) return Colors.red;
    if (_selectedEn == word) return const Color(0xFF1565C0);
    return Colors.grey[200]!;
  }

  Color _getViColor(String meaning) {
    if (_matched.containsValue(meaning)) return Colors.green;
    return Colors.grey[200]!;
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) return _buildResult();
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎯 Word Match'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Nối từ với nghĩa đúng!  •  Điểm: $_score',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Chọn từ tiếng Anh trước, rồi chọn nghĩa',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Row(
                children: [
                  // Cột tiếng Anh
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _enWords.map((word) {
                        final color = _getEnColor(word);
                        return GestureDetector(
                          onTap: () => _onSelectEn(word),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(12),
                              border: _selectedEn == word
                                  ? Border.all(
                                      color: const Color(0xFF1565C0), width: 2)
                                  : null,
                            ),
                            child: Text(
                              word,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color == Colors.grey[200]
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Cột tiếng Việt
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _viWords.map((meaning) {
                        final color = _getViColor(meaning);
                        return GestureDetector(
                          onTap: () => _onSelectVi(meaning),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              meaning,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: color == Colors.grey[200]
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 16),
            const Text('Hoàn thành! +50 XP',
                style:
                    TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
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
    );
  }
}