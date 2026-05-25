import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageLessonContentDialog extends StatefulWidget {
  final String lessonId;
  final String lessonTitle;
  const ManageLessonContentDialog({super.key, required this.lessonId, required this.lessonTitle});

  @override
  State<ManageLessonContentDialog> createState() => _ManageLessonContentDialogState();
}

class _ManageLessonContentDialogState extends State<ManageLessonContentDialog> {
  final _wordCtrl = TextEditingController();
  final _pronCtrl = TextEditingController();
  final _meanCtrl = TextEditingController();
  final _examCtrl = TextEditingController();
  
  final _optACtrl = TextEditingController();
  final _optBCtrl = TextEditingController();
  final _optCCtrl = TextEditingController();
  final _optDCtrl = TextEditingController();
  int _correctIdx = 0; 

  @override
  void dispose() {
    _wordCtrl.dispose();
    _pronCtrl.dispose();
    _meanCtrl.dispose();
    _examCtrl.dispose();
    _optACtrl.dispose();
    _optBCtrl.dispose();
    _optCCtrl.dispose();
    _optDCtrl.dispose();
    super.dispose();
  }

  void _clearForm() {
    _wordCtrl.clear();
    _pronCtrl.clear();
    _meanCtrl.clear();
    _examCtrl.clear();
    _optACtrl.clear();
    _optBCtrl.clear();
    _optCCtrl.clear();
    _optDCtrl.clear();
    setState(() {
      _correctIdx = 0;
    });
  }

  // Tiện ích tạo ô nhập liệu đẹp mắt
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: iconColor ?? Colors.blue.shade700),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container( // 👑 ĐÃ ĐỔI: Thay Scaffold bằng Container để tránh bắt SnackBar hiển thị trong Dialog
          color: Colors.grey.shade100,
          child: Column(
            children: [
              // Thanh tiêu đề tùy biến thay thế cho AppBar
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.blue.shade800,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.lessonTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Nửa trên: Form nhập liệu xịn sò
              Expanded(
                flex: 6,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionHeader('1. Thông tin Từ vựng (Flashcard)', Icons.style, Colors.purple.shade700),
                      _buildTextField(_wordCtrl, 'Từ tiếng Anh *', Icons.abc, iconColor: Colors.purple),
                      _buildTextField(_pronCtrl, 'Phiên âm', Icons.record_voice_over, iconColor: Colors.purple),
                      _buildTextField(_meanCtrl, 'Nghĩa tiếng Việt *', Icons.translate, iconColor: Colors.purple),
                      _buildTextField(_examCtrl, 'Ví dụ minh họa', Icons.text_snippet, iconColor: Colors.purple),
                      
                      const Divider(height: 32, thickness: 1),
                      
                      _buildSectionHeader('2. Phương án bài tập (Quiz)', Icons.quiz, Colors.orange.shade800),
                      _buildTextField(_optACtrl, 'Lựa chọn A *', Icons.looks_one, iconColor: Colors.orange),
                      _buildTextField(_optBCtrl, 'Lựa chọn B *', Icons.looks_two, iconColor: Colors.orange),
                      _buildTextField(_optCCtrl, 'Lựa chọn C', Icons.looks_3, iconColor: Colors.orange),
                      _buildTextField(_optDCtrl, 'Lựa chọn D', Icons.looks_4, iconColor: Colors.orange),
                      
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: DropdownButtonFormField<int>(
                          value: _correctIdx,
                          decoration: InputDecoration(
                            labelText: 'Vị trí đáp án đúng nhất',
                            prefixIcon: const Icon(Icons.check_circle, color: Colors.green),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: const [
                            DropdownMenuItem(value: 0, child: Text('Đáp án A (Lựa chọn 1)')),
                            DropdownMenuItem(value: 1, child: Text('Đáp án B (Lựa chọn 2)')),
                            DropdownMenuItem(value: 2, child: Text('Đáp án C (Lựa chọn 3)')),
                            DropdownMenuItem(value: 3, child: Text('Đáp án D (Lựa chọn 4)')),
                          ],
                          onChanged: (v) => setState(() => _correctIdx = v ?? 0),
                        ),
                      ),
                      
                      // Sử dụng Builder để có rootContext bên ngoài Dialog
                      Builder(
                        builder: (buttonContext) {
                          return SizedBox(
                            height: 55,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade800, 
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                              ),
                              icon: const Icon(Icons.add_task),
                              label: const Text('LƯU VÀO BÀI HỌC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              onPressed: () async {
                                if (_wordCtrl.text.trim().isEmpty || _meanCtrl.text.trim().isEmpty || _optACtrl.text.trim().isEmpty || _optBCtrl.text.trim().isEmpty) {
                                  // Hiển thị ra toàn màn hình bên ngoài
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Vui lòng nhập đầy đủ các trường có dấu * (Bắt buộc)'))
                                  );
                                  return;
                                }
                                
                                List<String> options = [_optACtrl.text.trim(), _optBCtrl.text.trim()];
                                if (_optCCtrl.text.trim().isNotEmpty) options.add(_optCCtrl.text.trim());
                                if (_optDCtrl.text.trim().isNotEmpty) options.add(_optDCtrl.text.trim());

                                final Map<String, dynamic> flashcardData = {
                                  'lessonId': widget.lessonId,
                                  'word': _wordCtrl.text.trim(),
                                  'meaning': _meanCtrl.text.trim(),
                                  'pronunciation': _pronCtrl.text.trim(),
                                  'example': _examCtrl.text.trim().isEmpty ? 'No example provided.' : _examCtrl.text.trim(),
                                  'options': options,
                                  'correctAnswerIndex': _correctIdx,
                                };

                                await FirebaseFirestore.instance.collection('flashcards').add(flashcardData);
                                _clearForm();
                                
                                if (context.mounted) {
                                  // Hiển thị ra toàn màn hình bên ngoài đáy ứng dụng
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã nạp nội dung mới thành công!'), 
                                      backgroundColor: Colors.green
                                    )
                                  );
                                }
                              },
                            ),
                          );
                        }
                      )
                    ],
                  ),
                ),
              ),
              
              const Divider(height: 1, thickness: 2),
              
              // Nửa dưới: Danh sách xem lại (Review)
              Expanded(
                flex: 4,
                child: Container(
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        color: Colors.blue.shade50,
                        child: const Text('📚 Danh sách nội dung hiện có:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      ),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('flashcards').where('lessonId', isEqualTo: widget.lessonId).snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                            final items = snapshot.data!.docs;
                            if (items.isEmpty) return const Center(child: Text('Bài này chưa có nội dung, hãy nhập ở trên.', style: TextStyle(color: Colors.grey, fontSize: 13)));
                            
                            return ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: items.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final itemDoc = items[idx];
                                final iData = itemDoc.data() as Map<String, dynamic>;
                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.purple.shade100,
                                    child: const Icon(Icons.style, color: Colors.purple, size: 20),
                                  ),
                                  title: Text('${iData['word']} -> ${iData['meaning']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Trắc nghiệm có ${(iData['options'] as List?)?.length ?? 0} đáp án'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => FirebaseFirestore.instance.collection('flashcards').doc(itemDoc.id).delete(),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}