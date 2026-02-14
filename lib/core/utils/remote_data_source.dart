import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_logger.dart';

class RemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DateTime> getServerTime(String uid) async {
    try {
      final docRef = _firestore.collection('server_time').doc(uid);
      await docRef.set({'t': FieldValue.serverTimestamp()});
      final snap = await docRef.get();
      return (snap.data()?['t'] as Timestamp).toDate();
    } catch (e) {
      return DateTime.now(); 
    }
  }

  Future<void> syncStudentData({
    required String uid,
    required String name,
    required String group,
  }) async {
    try {
      final docRef = _firestore.collection('students').doc(uid);
      final docSnap = await docRef.get();
      final Map<String, dynamic> data = {
        'displayName': name,
        'group': group,
        'status': 'active',
        'uid': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (!docSnap.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }
      await docRef.set(data, SetOptions(merge: true));
    } catch (e) { AppLogger.e("Sync Student failed", e); }
  }

  // Protokol Baru: ID Dokumen = ${sessionId}_${studentId}
  Future<void> startActiveExam({
    required String studentId,
    required String studentName,
    required String studentGroup,
    required String examId,
    required String sessionId,
    required int totalQuestions,
  }) async {
    try {
      final docId = "${sessionId}_$studentId";
      await _firestore.collection('active_exams').doc(docId).set({
        'student_id': studentId,
        'student_name': studentName,
        'student_group': studentGroup,
        'session_id': sessionId,
        'exam_id': examId,
        'status': 'active',
        'current_index': 0,
        'max_seen_index': 0,
        'total_questions': totalQuestions,
        'violation_count': 0,
        'last_heartbeat': FieldValue.serverTimestamp(),
        'started_at': FieldValue.serverTimestamp(),
        'temp_answers': {},
      });
    } catch (e) { AppLogger.e("Start Monitoring failed", e); }
  }

  Future<void> updateProgress({
    required String studentId,
    required String sessionId,
    required int currentIndex,
    required int maxSeenIndex,
    required int violationCount,
    required Map<int, dynamic> answers,
    String? violation,
  }) async {
    try {
      final docId = "${sessionId}_$studentId";
      final Map<String, dynamic> formattedAnswers = {};
      answers.forEach((key, value) => formattedAnswers[key.toString()] = value);

      final data = {
        'current_index': currentIndex,
        'max_seen_index': maxSeenIndex,
        'violation_count': violationCount,
        'temp_answers': formattedAnswers,
        'last_heartbeat': FieldValue.serverTimestamp(),
      };
      if (violation != null) {
        data['last_violation'] = violation;
      }
      
      await _firestore.collection('active_exams').doc(docId).set(data, SetOptions(merge: true));
    } catch (e) {
      // Silent error: Heartbeat failure should not interrupt exam
    }
  }

  Future<void> submitResultToCloud({
    required String studentId,
    required String studentName,
    required String studentGroup,
    required String examId,
    required String sessionId,
    required Map<int, dynamic> answers,
    required int score,
    required int violationCount,
    required int finalIndex,
    String? violationReason,
    String? sessionName,
  }) async {
    try {
      final docId = "${sessionId}_$studentId";
      final Map<String, dynamic> formattedAnswers = {};
      answers.forEach((key, value) => formattedAnswers[key.toString()] = value);

      // 1. Simpan ke koleksi global Results
      await _firestore.collection('results').add({
        'student_id': studentId,
        'student_name': studentName,
        'student_group': studentGroup,
        'exam_id': examId,
        'session_id': sessionId,
        'session_name': sessionName,
        'answers': formattedAnswers,
        'score': score,
        'violation_count': violationCount,
        'violation_reason': violationReason,
        'submitted_at': FieldValue.serverTimestamp(),
      });

      // 2. Tandai Monitoring sebagai Selesai
      await _firestore.collection('active_exams').doc(docId).update({
        'status': 'finished',
        'finished_at': FieldValue.serverTimestamp(),
        'temp_answers': formattedAnswers,
        'current_index': finalIndex,
        'last_heartbeat': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.e("Submit Result failed", e);
      rethrow;
    }
  }
}
