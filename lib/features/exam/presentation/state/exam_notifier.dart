import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:okey_bimbel/features/exam/data/models/exam_model.dart';

class ExamState {
  final Exam? exam;
  final String? sessionId;
  final String? studentId;
  final bool isLoading;
  final String? error;

  ExamState({this.exam, this.sessionId, this.studentId, this.isLoading = false, this.error});

  ExamState copyWith({Exam? exam, String? sessionId, String? studentId, bool? isLoading, String? error}) {
    return ExamState(
      exam: exam ?? this.exam,
      sessionId: sessionId ?? this.sessionId,
      studentId: studentId ?? this.studentId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ExamNotifier extends StateNotifier<ExamState> {
  ExamNotifier() : super(ExamState());

  Timer? _heartbeatTimer;
  StreamSubscription? _sessionSubscription;

  Future<void> startSession({
    required Exam exam,
    required String sessionId,
    required String studentId,
    required String studentName,
    required String studentGroup,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final docId = "${sessionId}_$studentId";
      
      // 1. Initial Handshake to active_exams
      await FirebaseFirestore.instance.collection('active_exams').doc(docId).set({
        'student_id': studentId,
        'student_name': studentName,
        'student_group': studentGroup,
        'session_id': sessionId,
        'exam_id': exam.id,
        'status': 'active',
        'last_heartbeat': FieldValue.serverTimestamp(),
        'violation_count': 0,
        'temp_answers': {},
        'started_at': FieldValue.serverTimestamp(),
      });

      // 2. Start Heartbeat Timer (Every 30 seconds)
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        FirebaseFirestore.instance.collection('active_exams').doc(docId).update({
          'last_heartbeat': FieldValue.serverTimestamp(),
        });
      });

      // 3. Listen to Session status (Remote Kill)
      _sessionSubscription?.cancel();
      _sessionSubscription = FirebaseFirestore.instance.collection('sessions').doc(sessionId).snapshots().listen((snap) {
        if (snap.exists && snap.data()?['status'] == 'finished') {
          // Trigger finishing logic
        }
      });

      state = state.copyWith(exam: exam, sessionId: sessionId, studentId: studentId, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void stopAll() {
    _heartbeatTimer?.cancel();
    _sessionSubscription?.cancel();
  }

  @override
  void dispose() {
    stopAll();
    super.dispose();
  }
}

final examProvider = StateNotifierProvider<ExamNotifier, ExamState>((ref) => ExamNotifier());
