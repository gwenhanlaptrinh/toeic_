import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Thêm để dùng Provider giống ô tìm kiếm
import 'package:flutter_tts/flutter_tts.dart';
import '../services/word_of_day_service.dart';
import '../providers/library_provider.dart'; // Import để lưu chung vào một kho thư viện
import '../models/vocabulary_model.dart';   // Import model đồng bộ dữ liệu

class WordOfDayCard extends StatefulWidget {
  const WordOfDayCard({super.key});

  @override
  State<WordOfDayCard> createState() => _WordOfDayCardState();
}

class _WordOfDayCardState extends State<WordOfDayCard> {
  final _wordService = WordOfDayService();
  final FlutterTts _tts = FlutterTts();
  bool _showExample = false;
  late Map<String, dynamic> _word;

  @override
  void initState() {
    super.initState();
    _word = _wordService.getWordOfDay();
    _setupTts();
  }

  void _setupTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
  }

  void _speak() async {
    await _tts.speak(_word['word']);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A1B9A).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('📆', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 6),
                  Text(
                    'Từ của ngày hôm nay',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              // NÚT LƯU THÔNG MINH BẮT CHƯỚC TỪ ĐIỂN TÌM KIẾM
              StreamBuilder<List<String>>(
                stream: context.read<LibraryProvider>().savedWordNamesStream,
                builder: (context, snapshot) {
                  final savedWords = snapshot.data ?? [];
                  // Kiểm tra xem từ của ngày hiện tại đã nằm trong thư viện chung chưa
                  final isSaved = savedWords.contains(_word['word']);

                  return GestureDetector(
                    onTap: () async {
                      // Ép dữ liệu từ Map sang Model để LibraryProvider tiếp nhận chuẩn xác
                      final vocabularyWord = VocabularyModel(
                        word: _word['word'] ?? '',
                        pronunciation: _word['phonetic'] ?? '',
                        meaning: _word['meaning'] ?? '',
                        example: _word['example'] ?? '',
                        audioUrl: '',
                      );

                      if (isSaved) {
                        // Nếu đã lưu -> Bấm để HỦY LƯU (XÓA) khỏi thư viện chung
                        await context.read<LibraryProvider>().deleteWord(vocabularyWord.word);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã hủy lưu từ "${vocabularyWord.word}"!'),
                              backgroundColor: Colors.orange,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      } else {
                        // Nếu chưa lưu -> Bấm để LƯU vào thư viện chung
                        await context.read<LibraryProvider>().saveWord(vocabularyWord);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã lưu "${vocabularyWord.word}" vào thư viện!'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      }
                    },
                    child: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Từ + phát âm
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _word['word'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _word['phonetic'],
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _word['type'],
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Nút phát âm âm thanh bằng giọng đọc
              GestureDetector(
                onTap: _speak,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.volume_up, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Nghĩa tiếng việt
          Text(
            _word['meaning'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Nút xem ví dụ dụ ẩn hiện
          GestureDetector(
            onTap: () => setState(() => _showExample = !_showExample),
            child: Row(
              children: [
                Text(
                  _showExample ? 'Ẩn ví dụ' : 'Xem ví dụ',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white70,
                  ),
                ),
                Icon(
                  _showExample ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white70,
                  size: 18,
                ),
              ],
            ),
          ),

          // Khối ví dụ (ẩn/hiện)
          if (_showExample) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🇬🇧 ${_word['example']}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '🇻🇳 ${_word['exampleVi']}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}