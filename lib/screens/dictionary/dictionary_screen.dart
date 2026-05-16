import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../providers/dictionary_provider.dart';
import '../../providers/library_provider.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();

    _setupTts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DictionaryProvider>().clearSearch();
      }
    });
  }

  // Cấu hình giọng đọc tiếng Anh
  Future<void> _setupTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5); // Tốc độ đọc vừa phải
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  // Hàm phát âm
  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _flutterTts.stop(); // Dừng phát âm khi thoát màn hình
    super.dispose();
  }

  void _handleSearch() {
    // Ẩn bàn phím khi bấm tìm kiếm
    FocusScope.of(context).unfocus(); 
    // Gọi hàm search từ Provider
    context.read<DictionaryProvider>().search(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe dữ liệu từ Provider
    final dictionaryProvider = context.watch<DictionaryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Từ điển TOEIC'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. Ô TÌM KIẾM
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _handleSearch(), // Tìm kiếm khi nhấn phím Enter trên bàn phím
              decoration: InputDecoration(
                hintText: 'Nhập từ tiếng Anh cần tra...',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    context.read<DictionaryProvider>().clearSearch();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 2. HIỂN THỊ KẾT QUẢ HOẶC LỖI
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildBody(dictionaryProvider),
            ),
          ),
        ],
      ),
    );
  }

  // Hàm xử lý logic hiển thị nội dung bên dưới
  Widget _buildBody(DictionaryProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage!,
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final word = provider.searchedWord;
    if (word == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Tra cứu từ vựng để hiển thị kết quả', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

// 3. KHỐI HIỂN THỊ KẾT QUẢ TỪ VỰNG
    return ListView(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        word.word,
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                    
                    // 1. NÚT PHÁT ÂM ÂM THANH (ĐÃ ĐƯỢC KHÔI PHỤC)
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded, size: 32, color: Colors.blue),
                      onPressed: () => _speak(word.word),
                    ),
                    
                    // 2. NÚT TRÁI TIM THÔNG MINH
                    StreamBuilder<List<String>>(
                      stream: context.read<LibraryProvider>().savedWordNamesStream,
                      builder: (context, snapshot) {
                        final savedWords = snapshot.data ?? [];
                        // Kiểm tra xem từ hiện tại đã có trong DB chưa
                        final isSaved = savedWords.contains(word.word);

                        return IconButton(
                          icon: Icon(
                            isSaved ? Icons.favorite : Icons.favorite_border,
                            size: 32,
                            color: isSaved ? Colors.red : Colors.grey,
                          ),
                          onPressed: () async {
                            if (isSaved) {
                              // Nếu đã lưu -> Bấm vào để HOÀN TÁC (XÓA)
                              await context.read<LibraryProvider>().deleteWord(word.word);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).clearSnackBars(); // Xóa nhanh snackbar cũ
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Đã hủy lưu từ "${word.word}"!'),
                                    backgroundColor: Colors.orange,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            } else {
                              // Nếu chưa lưu -> Bấm vào để LƯU
                              await context.read<LibraryProvider>().saveWord(word);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Đã lưu từ "${word.word}" vào thư viện!'),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
                if (word.pronunciation.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    word.pronunciation,
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                  ),
                ],
                const Divider(height: 30, thickness: 1),
                const Text(
                  'Định nghĩa:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  word.meaning,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Ví dụ:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Text(
                    word.example,
                    style: TextStyle(fontSize: 16, color: Colors.blue.shade900, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}