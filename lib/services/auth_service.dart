import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  // =========================
  // AUTH STREAM
  // =========================

  Stream<User?> get userStream =>
      _auth.authStateChanges();

  // =========================
  // SIGN UP
  // =========================

  Future<UserCredential> signUp(
    String email,
    String password,
    String name,
  ) async {

    UserCredential cred =
        await _auth
            .createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user;

    if (user != null) {

      await _db
          .collection('users')
          .doc(user.uid)
          .set({

        // BASIC
        'email': email,
        'name': name,
        'isPlus': false,

        // XP
        'xp': 0,

        // WEEKLY XP
        'weeklyXp': {
          'T2': 0,
          'T3': 0,
          'T4': 0,
          'T5': 0,
          'T6': 0,
          'T7': 0,
          'CN': 0,
        },

        // STREAK
        'streak': 0,

        'lastActiveDate': '',

        // WEEK RESET
        'lastWeeklyResetDate': '',

        // DAILY
        'dailyLessonsCompleted': 0,

        'dailyXpEarned': 0,

        'wordsLearnedCount': 0,

        // LESSONS
        'completedLessons': [],

        // MISSIONS
        'rewardMission1Claimed': false,

        'rewardMission2Claimed': false,

        // CREATED
        'createdAt':
            FieldValue.serverTimestamp(),
      });
    }

    return cred;
  }

  // =========================
  // SIGN IN
  // =========================

  Future<UserCredential> signIn(
    String email,
    String password,
  ) async {

    return await _auth
        .signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // =========================
  // SIGN OUT
  // =========================

  Future<void> signOut() async {

    await _auth.signOut();
  }
}