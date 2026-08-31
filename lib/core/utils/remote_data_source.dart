import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_logger.dart';

class RemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Zero-write Server Time Probe
  Future<DateTime> getServerTime(String uid) async {
    try {
      final docSnap = await _firestore.collection('system').doc('time').get();
      if (docSnap.exists && docSnap.data()?['serverTime'] != null) {
        return (docSnap.data()?['serverTime'] as Timestamp).toDate();
      }
      return DateTime.now();
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

  // 2. Start Active Exam
  Future<void> startActiveExam({
    required String studentId,
    required String studentName,
    required String studentGroup,
    required String examId,
    required String sessionId,
    required int totalQuestions,
    required String activeToken,
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
        'started_at': FieldValue.serverTimestamp(),
        'temp_answers': {},
        // Token-gated write: matches firestore.rules active_exams create (L143)
        'token': activeToken,
      });
    } catch (e) { AppLogger.e("Start Monitoring failed", e); }
  }

  // 3. Event-Driven Sync (Throttled 60s for normal heartbeat/progress, Immediate for violations)
    // OPTIMIZATION FOR SPARK FREE TIER: Throttle at 60s to unify with mobile heartbeat
    // Reduces max progress writes per student from 120 down to 60 over a 60min exam.
    DateTime? _lastSyncTime;
    // Dead letter queue for failed writes
    final List<Map<String, dynamic>> _failedWriteQueue = [];

    Future<void> updateProgress({
        required String studentId,
        required String sessionId,
        required int currentIndex,
        required int maxSeenIndex,
        required int violationCount,
        required Map<int, dynamic> answers,
        required String activeToken,
        String? violation,
        bool forceImmediate = false,
      }) async {
        final now = DateTime.now();
        // Throttle progress syncs to at most once every 90s unless forceImmediate is true (Spark Plan optimization)
        if (!forceImmediate && _lastSyncTime != null && now.difference(_lastSyncTime!).inSeconds < 90) {
          return;
        }
        _lastSyncTime = now;

        // Prepare formatted answers before try/catch so it's available in catch block
        final Map<String, dynamic> formattedAnswers = {};
        answers.forEach((key, value) => formattedAnswers[key.toString()] = value);

        try {
          final docId = "${sessionId}_$studentId";

          final data = {
            'student_id': studentId,
            'current_index': currentIndex,
            'max_seen_index': maxSeenIndex,
            'violation_count': violationCount,
            'temp_answers': formattedAnswers,
            'last_activity': FieldValue.serverTimestamp(),
            'token': activeToken,
          };
          if (violation != null) {
            data['last_violation'] = violation;
          }

          await _firestore.collection('active_exams').doc(docId).set(data, SetOptions(merge: true));
      
          // On success, flush any queued failed writes
          _flushFailedWrites(studentId, sessionId);
        } catch (e) {
          // Queue failed write for retry with exponential backoff
          _queueFailedWrite(studentId, sessionId, currentIndex, maxSeenIndex, violationCount, formattedAnswers, violation);
        }
      }

    void _queueFailedWrite(String studentId, String sessionId, int currentIndex, int maxSeenIndex, int violationCount, Map<String, dynamic> formattedAnswers, String? violation) {
      _failedWriteQueue.add({
        'studentId': studentId,
        'sessionId': sessionId,
        'currentIndex': currentIndex,
        'maxSeenIndex': maxSeenIndex,
        'violationCount': violationCount,
        'formattedAnswers': formattedAnswers,
        'violation': violation,
        'timestamp': DateTime.now(),
        'retryCount': 0,
      });
      // Cap queue at 10 entries to prevent memory bloat
      if (_failedWriteQueue.length > 10) {
        _failedWriteQueue.removeAt(0);
      }
    }

    Future<void> _flushFailedWrites(String studentId, String sessionId) async {
      if (_failedWriteQueue.isEmpty) return;
    
      final toRetry = List<Map<String, dynamic>>.from(_failedWriteQueue);
      _failedWriteQueue.clear();
    
      for (final write in toRetry) {
        if (write['studentId'] != studentId || write['sessionId'] != sessionId) {
          // Re-queue for different student/session
          _failedWriteQueue.add(write);
          continue;
        }
      
        try {
          final docId = "${write['sessionId']}_${write['studentId']}";
          final data = {
            'current_index': write['currentIndex'],
            'max_seen_index': write['maxSeenIndex'],
            'violation_count': write['violationCount'],
            'temp_answers': write['formattedAnswers'],
            'last_activity': FieldValue.serverTimestamp(),
          };
          if (write['violation'] != null) {
            data['last_violation'] = write['violation'];
          }
        
          await _firestore.collection('active_exams').doc(docId).set(data, SetOptions(merge: true));
        } catch (e) {
          // Re-queue with incremented retry count
          write['retryCount'] = (write['retryCount'] as int) + 1;
          if ((write['retryCount'] as int) < 5) {
            _failedWriteQueue.add(write);
          } else {
            AppLogger.e("Failed write dropped after 5 retries", e, StackTrace.current);
          }
        }
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
    required String activeToken,
    String? violationReason,
    String? sessionName,
  }) async {
    final docId = "${sessionId}_$studentId";
    final Map<String, dynamic> formattedAnswers = {};
    answers.forEach((key, value) => formattedAnswers[key.toString()] = value);

    // 1. UTAMA: Simpan ke koleksi global Results (Blocking & Idempotent via deterministic doc ID)
    try {
      final resultDocId = "${sessionId}_$studentId";
      await _firestore.collection('results').doc(resultDocId).set({
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
        // Token-gated write: matches firestore.rules results create (L165)
        'token': activeToken,
      }).timeout(const Duration(seconds: 20), onTimeout: () {
        throw TimeoutException("Koneksi data seluler lambat/timeout. Dialihkan ke antrean lokal.");
      });
    } catch (e) {
      AppLogger.e("Submit Result Utama Gagal", e);
      rethrow;
    }

    // 2. KEDUA: Update status Monitoring (Non-blocking & Gunakan set merge agar safe)
    try {
      await _firestore.collection('active_exams').doc(docId).set({
        'status': 'finished',
        'finished_at': FieldValue.serverTimestamp(),
        'temp_answers': formattedAnswers,
        'current_index': finalIndex,
        'last_activity': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      AppLogger.e("Update Monitoring active_exams gagal, tapi nilai sudah aman tersimpan.", e);
    }
  }
}
