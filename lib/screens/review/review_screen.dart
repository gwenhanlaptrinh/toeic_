import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../providers/user_provider.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {

  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadWrongWords();
    });

    _initTTS();
  }

  Future<void> _initTTS() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
  }

  Future<void> _speak(String text) async {
    if (text.trim().isEmpty) return;

    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final userProvider = context.watch<UserProvider>();
    final wrongWords = userProvider.wrongWords;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      appBar: AppBar(
        title: const Text(
          'Kho Ôn Tập',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        centerTitle: true,
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: wrongWords.isEmpty

          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [

                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 90,
                      color: Colors.green.shade400,
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Sạch bóng từ sai!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Bạn đã thuộc toàn bộ từ vựng hoặc chưa làm sai câu nào.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )

          : ListView.builder(
              padding: const EdgeInsets.all(16),

              itemCount: wrongWords.length,

              itemBuilder: (context, index) {

                final item = wrongWords[index];

                final String word =
                    item['word'] ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),

                  elevation: 2,

                  child: Padding(
                    padding: const EdgeInsets.all(20.0),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,

                          children: [

                            Expanded(
                              child: Text(
                                word,

                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ),

                            IconButton(
                              icon: const Icon(
                                Icons.volume_up,
                                color: Colors.blue,
                                size: 28,
                              ),

                              onPressed: () async {
                                await _speak(word);
                              },
                            ),
                          ],
                        ),

                        Text(
                          item['pronunciation'] ?? '',

                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Container(
                          width: double.infinity,

                          padding: const EdgeInsets.all(12),

                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius:
                                BorderRadius.circular(10),
                          ),

                          child: Text(
                            'Nghĩa: ${item['meaning'] ?? ""}',

                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 45,

                          child: ElevatedButton.icon(

                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,

                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                            ),

                            icon: const Icon(Icons.check),

                            label: const Text(
                              'Đã thuộc từ này',

                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            onPressed: () async {

                              await context
                                  .read<UserProvider>()
                                  .removeWrongWord(word);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(

                                  SnackBar(
                                    content: Text(
                                      'Đã xóa "$word" khỏi danh sách ôn tập',
                                    ),

                                    backgroundColor:
                                        Colors.green,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}