// File: lib/screens/courses/quiz_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

import '../../providers/course_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';

import '../../models/course_models.dart';

class QuizScreen extends StatefulWidget {
  final String lessonTitle;
  final String lessonId;

  const QuizScreen({
    super.key,
    required this.lessonTitle,
    required this.lessonId,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {

  int _questionIndex = 0;

  int _score = 0;

  int? _selectedAnswerIndex;

  bool _isAnswered = false;

  bool _isFinishingQuiz = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {

      context
          .read<CourseProvider>()
          .loadFlashcards(widget.lessonId);
    });
  }

  // =========================
  // CHECK ANSWER
  // =========================

  void _checkAnswer(
    int index,
    int correctAnswerIndex,
    FlashcardModel currentQuiz,
    String topicId,
  ) {

    if (_isAnswered) return;

    setState(() {

      _selectedAnswerIndex = index;

      _isAnswered = true;
    });

    bool isCorrect =
        (index == correctAnswerIndex);

    if (isCorrect) {

      _score++;

    } else {

      // SAVE WRONG WORD

      try {

        context
            .read<UserProvider>()
            .saveWrongWord(
              currentQuiz.word,
              currentQuiz.meaning,
              currentQuiz.pronunciation,
            );

      } catch (e) {

        debugPrint(
            "Lỗi lưu từ sai: $e");
      }
    }

    _showResultBottomSheet(
      isCorrect,
      currentQuiz,
      topicId,
    );
  }

  // =========================
  // RESULT BOTTOM SHEET
  // =========================

  void _showResultBottomSheet(
    bool isCorrect,
    FlashcardModel currentQuiz,
    String topicId,
  ) {

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,

      builder: (context) => Container(

        padding: const EdgeInsets.all(24),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
              const BorderRadius.vertical(
            top: Radius.circular(24),
          ),

          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(0.1),

              blurRadius: 10,

              offset: const Offset(0, -5),
            )
          ],
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          crossAxisAlignment:
              CrossAxisAlignment.stretch,

          children: [

            Row(
              children: [

                Icon(
                  isCorrect
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,

                  color:
                      isCorrect
                          ? Colors.green
                          : Colors.red,

                  size: 32,
                ),

                const SizedBox(width: 12),

                Text(
                  isCorrect
                      ? 'Tuyệt vời!'
                      : 'Chưa chính xác!',

                  style: TextStyle(
                    fontSize: 22,

                    fontWeight: FontWeight.bold,

                    color:
                        isCorrect
                            ? Colors.green
                            : Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (!isCorrect) ...[

              Text(
                'Đáp án đúng là:',

                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                currentQuiz.options[
                    currentQuiz.correctAnswerIndex],

                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),

              const SizedBox(height: 16),
            ],

            ElevatedButton(

              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isCorrect
                        ? Colors.green
                        : Colors.red,

                padding:
                    const EdgeInsets.symmetric(
                  vertical: 16,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),

              onPressed: () {

                Navigator.pop(context);

                _nextQuestion();
              },

              child: const Text(
                'Tiếp tục',

                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // NEXT QUESTION
  // =========================

  void _nextQuestion() {

    final courseProvider =
        context.read<CourseProvider>();

    if (_questionIndex <
        courseProvider.currentFlashcards.length - 1) {

      setState(() {

        _questionIndex++;

        _isAnswered = false;

        _selectedAnswerIndex = null;
      });

    } else {

      _showFinalResult();
    }
  }

  // =========================
  // FINAL RESULT
  // =========================

  void _showFinalResult() {

    final courseProvider =
        context.read<CourseProvider>();

    final totalQuestions =
        courseProvider.currentFlashcards.length;

    bool isPassed =
        (_score == totalQuestions);

    showDialog(

      context: context,

      barrierDismissible: false,

      builder: (dialogContext) => AlertDialog(

        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(20),
        ),

        title: Icon(
          isPassed
              ? Icons.emoji_events_rounded
              : Icons.gpp_bad_rounded,

          color:
              isPassed
                  ? Colors.amber
                  : Colors.red,

          size: 60,
        ),

        content: Column(
          mainAxisSize: MainAxisSize.min,

          children: [

            Text(
              isPassed
                  ? 'XUẤT SẮC HOÀN THÀNH!'
                  : 'CHƯA ĐẠT YÊU CẦU',

              style: TextStyle(
                fontSize: 20,

                fontWeight: FontWeight.bold,

                color:
                    isPassed
                        ? Colors.green
                        : Colors.red,
              ),

              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              'Bạn làm đúng $_score / $totalQuestions câu.',

              textAlign: TextAlign.center,

              style: const TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              isPassed
                  ? 'Chúc mừng bạn nhận +50 XP và mở khóa bài mới!'
                  : 'Bạn phải đúng 100% để vượt qua.',

              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),

        actions: [

          SizedBox(
            width: double.infinity,

            child: ElevatedButton(

              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isPassed
                        ? Colors.blue
                        : Colors.orange,

                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),

                padding:
                    const EdgeInsets.symmetric(
                  vertical: 12,
                ),
              ),

              onPressed: () async {

                // CHỐNG DOUBLE CLICK
                if (_isFinishingQuiz) return;

                _isFinishingQuiz = true;

                try {

                  if (isPassed) {

                    final courseProvider =
                        context.read<CourseProvider>();

                    final userProvider =
                        context.read<UserProvider>();

                    // =====================
                    // GET TOPIC ID
                    // =====================

                    String topicId = '';

                    if (courseProvider
                        .currentLessons
                        .isNotEmpty) {

                      topicId = courseProvider
                          .currentLessons
                          .first
                          .topicId;
                    }

                    // =====================
                    // COMPLETE LESSON
                    // CHỈ MỞ KHÓA
                    // KHÔNG CỘNG XP
                    // =====================

                    await courseProvider
                        .completeLesson(
                      widget.lessonId,
                      topicId,
                      0,
                    );

                    // =====================
                    // XP + STREAK + MISSION
                    // =====================

                    await userProvider
                        .updateLessonCompletion(
                      lessonId: widget.lessonId,
                      totalWordsInLesson:
                          totalQuestions,
                    );

                    // =====================
                    // REFRESH USER DATA
                    // =====================

                    final uid = FirebaseAuth
                        .instance
                        .currentUser
                        ?.uid;

                    if (uid != null &&
                        mounted) {

                      await context
                          .read<AuthProvider>()
                          .fetchUserData(uid);
                    }
                  }

                  if (mounted) {

                    Navigator.pop(dialogContext);

                    Navigator.pop(context);
                  }

                } catch (e) {

                  debugPrint(
                      "Finish quiz error: $e");

                } finally {

                  _isFinishingQuiz = false;
                }
              },

              child: Text(
                isPassed
                    ? 'Tuyệt vời, quay về!'
                    : 'Học lại & Thử lại',

                style: const TextStyle(
                  color: Colors.white,

                  fontSize: 16,

                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          Colors.grey.shade50,

      appBar: AppBar(

        title: Text(
          widget.lessonTitle,

          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        backgroundColor: Colors.blue,

        foregroundColor: Colors.white,

        elevation: 0,
      ),

      body: Consumer<CourseProvider>(

        builder:
            (context, courseProvider, child) {

          if (courseProvider.isLoading) {

            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (courseProvider
              .currentFlashcards
              .isEmpty) {

            return const Center(
              child: Text(
                'Chưa có câu hỏi nào.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final currentQuiz =
              courseProvider
                  .currentFlashcards[
                      _questionIndex];

          String topicId = '';

          if (courseProvider
              .currentLessons
              .isNotEmpty) {

            topicId = courseProvider
                .currentLessons
                .first
                .topicId;
          }

          return Padding(

            padding:
                const EdgeInsets.all(20.0),

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.stretch,

              children: [

                LinearProgressIndicator(
                  value:
                      (_questionIndex + 1) /
                          courseProvider
                              .currentFlashcards
                              .length,

                  backgroundColor:
                      Colors.grey.shade300,

                  color: Colors.blue,

                  minHeight: 8,

                  borderRadius:
                      BorderRadius.circular(10),
                ),

                const SizedBox(height: 20),

                Text(
                  'Câu ${_questionIndex + 1} / ${courseProvider.currentFlashcards.length}',

                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),

                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                Container(

                  padding:
                      const EdgeInsets.all(30),

                  decoration: BoxDecoration(

                    color: Colors.white,

                    borderRadius:
                        BorderRadius.circular(20),

                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.grey.shade200,

                        blurRadius: 10,

                        spreadRadius: 2,
                      )
                    ],
                  ),

                  child: Column(
                    children: [

                      Text(
                        currentQuiz.word,

                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight:
                              FontWeight.bold,
                          color: Colors.blue,
                        ),

                        textAlign:
                            TextAlign.center,
                      ),

                      if (currentQuiz
                          .pronunciation
                          .isNotEmpty) ...[

                        const SizedBox(
                            height: 10),

                        Text(
                          '/${currentQuiz.pronunciation}/',

                          style: TextStyle(
                            fontSize: 18,
                            color:
                                Colors.grey.shade600,
                            fontStyle:
                                FontStyle.italic,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                Expanded(

                  child: ListView.builder(

                    itemCount:
                        currentQuiz.options.length,

                    itemBuilder:
                        (context, index) {

                      final optionText =
                          currentQuiz.options[index];

                      Color buttonColor =
                          Colors.white;

                      Color textColor =
                          Colors.black87;

                      Color borderColor =
                          Colors.grey.shade300;

                      if (_isAnswered) {

                        if (index ==
                            currentQuiz
                                .correctAnswerIndex) {

                          buttonColor =
                              Colors.green.shade50;

                          textColor =
                              Colors.green.shade700;

                          borderColor =
                              Colors.green;

                        } else if (index ==
                            _selectedAnswerIndex) {

                          buttonColor =
                              Colors.red.shade50;

                          textColor =
                              Colors.red.shade700;

                          borderColor =
                              Colors.red;
                        }
                      }

                      return Container(

                        margin:
                            const EdgeInsets.only(
                                bottom: 14),

                        height: 55,

                        child: ElevatedButton(

                          style:
                              ElevatedButton.styleFrom(

                            backgroundColor:
                                buttonColor,

                            foregroundColor:
                                textColor,

                            elevation:
                                _isAnswered ? 0 : 1,

                            shape:
                                RoundedRectangleBorder(

                              borderRadius:
                                  BorderRadius.circular(
                                      16),

                              side: BorderSide(
                                color: borderColor,
                                width: 2,
                              ),
                            ),
                          ),

                          onPressed: () =>
                              _checkAnswer(
                            index,
                            currentQuiz
                                .correctAnswerIndex,
                            currentQuiz,
                            topicId,
                          ),

                          child: Text(
                            optionText,

                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}