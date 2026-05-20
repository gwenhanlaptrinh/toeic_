import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/course_provider.dart';
import 'lessons_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadTopics();
    });
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'forum_rounded': return Icons.forum_rounded;
      case 'business_center_rounded': return Icons.business_center_rounded;
      case 'flight_takeoff_rounded': return Icons.flight_takeoff_rounded;
      case 'computer_rounded': return Icons.computer_rounded;
      default: return Icons.school_rounded;
    }
  }

  final List<Gradient> _cardGradients = [
    const LinearGradient(colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    const LinearGradient(colors: [Color(0xFF43E97B), Color(0xFF38F9D7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    const LinearGradient(colors: [Color(0xFFFA709A), Color(0xFFFEE741)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  ];

  @override
  Widget build(BuildContext context) {
    final courseProvider = context.watch<CourseProvider>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text('Lộ Trình Học Tập', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF1E3C72), Color(0xFF2A5298)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
              ),
            ),
          ),
          courseProvider.isLoading
              ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.only(top: 100), child: CircularProgressIndicator())))
              : courseProvider.topics.isEmpty
                  ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.only(top: 100), child: Text('Chưa có dữ liệu khóa học.'))))
                  : SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final topic = courseProvider.topics[index];
                            final gradient = _cardGradients[index % _cardGradients.length];
                            // BIẾN TIẾN ĐỘ THẬT ĐỌC TỪ DATABASE
                            final displayPercent = (topic.progress * 100).toInt();

                            return Container(
                              decoration: BoxDecoration(
                                gradient: gradient,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [BoxShadow(color: gradient.colors.first.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(24),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => LessonsScreen(topicId: topic.id, topicTitle: topic.title)),
                                    ).then((_) {
                                      // Khi quay về, tự làm mới lại để cập nhật % tiến độ mới nhất
                                      context.read<CourseProvider>().loadTopics();
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                                          child: Icon(_getIconData(topic.icon), color: Colors.white, size: 26),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(topic.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 4),
                                            Text(topic.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: LinearProgressIndicator(
                                                value: topic.progress,
                                                backgroundColor: Colors.white.withOpacity(0.3),
                                                color: Colors.white,
                                                minHeight: 5,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text('Tiến độ: $displayPercent%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: courseProvider.topics.length,
                        ),
                      ),
                    ),
        ],
      ),
    );
  }
}