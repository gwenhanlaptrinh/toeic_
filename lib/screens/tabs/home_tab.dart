import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Map<String, dynamic>? userData;
  final _searchController = TextEditingController();
  String _searchResult = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    try {
      final uid = AuthService().currentUser?.uid;
      if (uid == null) return;
      final data = await AuthService().getUserData(uid);
      if (mounted) {
        setState(() => userData = data ?? {});
      }
    } catch (e) {
      print('Lỗi load user: $e');
      if (mounted) setState(() => userData = {});
    }
  }

  // Tra từ đơn giản (sau này tích hợp API)
  void _searchWord() {
    setState(() => _isSearching = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _searchResult = _searchController.text.isEmpty
            ? ''
            : 'Kết quả cho: "${_searchController.text}"';
        _isSearching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xin chào, ${userData?['name'] ?? ''}! 👋',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Học gì hôm nay?',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                CircleAvatar(
                  backgroundColor: const Color(0xFF1565C0),
                  child: Text(
                    userData?['name']?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Streak card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${userData?['streak'] ?? 0} ngày liên tiếp!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Tiếp tục duy trì nhé!',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Dictionary Search
            const Text(
              '🔍 Tra từ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onSubmitted: (_) => _searchWord(),
              decoration: InputDecoration(
                hintText: 'Nhập từ tiếng Anh...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _searchWord,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_searchResult.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_searchResult),
              ),
            const SizedBox(height: 24),

            // Quick stats
            const Text(
              '📊 Thống kê',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statCard(
                  'Từ đã học',
                  '${userData?['totalWordsLearned'] ?? 0}',
                  Icons.abc,
                ),
                const SizedBox(width: 12),
                _statCard(
                  'Tổng điểm',
                  '${userData?['totalScore'] ?? 0}',
                  Icons.star,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Leaderboard shortcut
            InkWell(
              onTap: () {}, // Sau này navigate đến Leaderboard
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber),
                ),
                child: const Row(
                  children: [
                    Text('🏆', style: TextStyle(fontSize: 28)),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bảng xếp hạng',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Xem bạn đang đứng hạng mấy?',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    Spacer(),
                    Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF1565C0), size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
