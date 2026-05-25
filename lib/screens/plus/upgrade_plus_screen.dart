// File: lib/screens/plus/upgrade_plus_screen.dart

import 'dart:convert'; // Bắt buộc phải có để dùng base64Encode
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class UpgradePlusScreen extends StatefulWidget {
  const UpgradePlusScreen({super.key});

  @override
  State<UpgradePlusScreen> createState() => _UpgradePlusScreenState();
}

class _UpgradePlusScreenState extends State<UpgradePlusScreen> {
  File? _imageFile;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // Hàm chọn ảnh từ thư viện + TỰ ĐỘNG NÉN ẢNH DƯỚI 1MB
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 35, // 🔥 Nén chất lượng xuống 35% giúp dung lượng cực nhẹ
      maxWidth: 800,    // 🔥 Giới hạn chiều rộng tối đa 800px để không bị tràn dung lượng Firestore
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Hàm gửi yêu cầu lên Firestore (Không cần Storage nữa)
  Future<void> _submitRequest() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ảnh bill chuyển khoản!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = context.read<AuthProvider>().userModel;
      if (user == null) throw Exception("Chưa đăng nhập");

      // 1. Chuyển đổi file ảnh thành chuỗi chuỗi văn bản Base64
      List<int> imageBytes = await _imageFile!.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // 2. Lưu trực tiếp toàn bộ thông tin và chuỗi ảnh vào Firestore
      await FirebaseFirestore.instance.collection('payment_requests').add({
        'uid': user.uid,
        'email': user.email,
        'name': user.name,
        'imageBase64': base64Image, // 🔥 Lưu chuỗi văn bản ảnh vào đây
        'status': 'pending',       // Trạng thái: đang chờ duyệt
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gửi yêu cầu thành công! Vui lòng chờ Admin duyệt.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pop(context); // Quay về màn hình trước
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi xảy ra khi lưu Firestore: $e'), 
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme Dark sang trọng cho màn hình
    final upscaleTheme = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Colors.black,
      cardColor: Colors.grey.shade900,
    );

    return Theme(
      data: upscaleTheme,
      child: Scaffold(
        backgroundColor: upscaleTheme.scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Custom Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Nâng Cấp PLUS',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Thẻ thông tin gói Premium
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), 
                    side: const BorderSide(color: Colors.amber, width: 0.5),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [Colors.grey.shade900, Colors.black], 
                        begin: Alignment.topLeft, 
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.workspace_premium, size: 28, color: Colors.amber),
                            SizedBox(width: 10),
                            Text(
                              'PREMIUM PLUS',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.amber, thickness: 0.2),
                        const SizedBox(height: 16),
                        const Column(
                          children: [
                            _FeatureItem(icon: Icons.lock_open, text: 'Mở khóa toàn bộ bài học & Khoá học cao cấp'),
                            _FeatureItem(icon: Icons.visibility_off, text: 'Trải nghiệm không quảng cáo'),
                            _FeatureItem(icon: Icons.access_time_filled, text: 'Quyền học 1 năm'),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          '199.000 VNĐ',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amber, letterSpacing: 1),
                        ),
                        const SizedBox(height: 4),
                        Text('1 năm', style: TextStyle(color: Colors.amber.shade200, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Thẻ thông tin chuyển khoản và QR Code của bạn
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'THÔNG TIN THANH TOÁN',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                  ),
                ),
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.grey.shade900,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const _PaymentDetailItem(icon: Icons.business, label: 'Ngân hàng', value: 'MBBANK'),
                        const _PaymentDetailItem(icon: Icons.person, label: 'Tên người nhận', value: 'Gwen Lại Lập Trình'),
                        const _PaymentDetailItem(icon: Icons.account_balance, label: 'Số tài khoản', value: '0898600612'),
                        const _PaymentDetailItem(icon: Icons.currency_exchange, label: 'Số tiền', value: '199.000 VNĐ'),
                        
                        const SizedBox(height: 20),
                        const Divider(color: Colors.white10, thickness: 1),
                        const SizedBox(height: 20),

                        // Ô hiển thị ảnh QR tràn viền
                        Center(
                          child: Container(
                            width: 170, 
                            height: 170,
                            decoration: BoxDecoration(
                              color: Colors.white, 
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.amber, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14), 
                              child: Image.asset(
                                'assets/images/pay_qr.png', 
                                fit: BoxFit.cover, 
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade900,
                                    child: const Icon(
                                      Icons.qr_code_2_rounded,
                                      size: 100,
                                      color: Colors.amber,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Quét mã QR để tự động điền thông tin',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Thẻ upload bill xác nhận chuyển khoản
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'XÁC NHẬN CHUYỂN KHOẢN',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                  ),
                ),
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.grey.shade900,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image, size: 20),
                            label: const Text('Chọn ảnh Bill Chuyển Khoản'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade700,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: const StadiumBorder(),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        if (_imageFile != null) ...[
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade600, width: 0.5),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(_imageFile!, height: 300, fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        SizedBox(
                          height: 50,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              gradient: const LinearGradient(colors: [Colors.orange, Colors.amber]),
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitRequest,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: const StadiumBorder(),
                              ),
                              child: _isLoading 
                                ? const CircularProgressIndicator(color: Colors.black)
                                : const Text('GỬI YÊU CẦU CHO ADMIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isAlert;

  const _PaymentDetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.amber.shade300),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isAlert ? Colors.amber : Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (!isAlert) Icon(Icons.copy, size: 16, color: Colors.amber.shade200),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}