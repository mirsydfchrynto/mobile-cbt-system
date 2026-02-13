import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:okey_bimbel/core/theme/app_colors.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:okey_bimbel/core/utils/security_service.dart';
import 'package:okey_bimbel/core/utils/local_db_service.dart';
import 'package:okey_bimbel/core/utils/remote_data_source.dart';
import 'package:okey_bimbel/core/utils/app_logger.dart';
import 'package:okey_bimbel/injection_container.dart';
import 'package:okey_bimbel/features/exam/data/models/exam_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ExamRoomPage extends StatefulWidget {
  const ExamRoomPage({super.key});

  @override
  State<ExamRoomPage> createState() => _ExamRoomPageState();
}

class _ExamRoomPageState extends State<ExamRoomPage> with WidgetsBindingObserver {
  late Exam exam;
  late String examId;
  late String sessionId;
  late String studentId;
  late String studentName;
  late String studentGroup;
  late Map<String, dynamic> _routeArgs;
  
  List<Question> _shuffledQuestions = [];
  Map<int, List<int>> _optionMappings = {}; 
  
  int _currentIndex = 0;
  int _maxSeenIndex = 0; 
  final Map<int, dynamic> _answers = {}; 
  Timer? _timer;
  Timer? _heartbeatTimer;
  StreamSubscription? _sessionSubscription;

  late DateTime _targetEndTime;
  Duration _remainingDuration = Duration.zero;
  bool _isSubmitting = false;
  int _violationCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable(); 
    SecurityService.startKioskMode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _routeArgs = args;
    
    examId = args['examId'];
    sessionId = args['sessionId'];
    studentId = args['student_id'];
    studentName = args['student_name'];
    studentGroup = args['student_group'] ?? "Umum";

    final localExam = Hive.box<Exam>(LocalDBService.examBoxName).get(examId);
    if (localExam == null) {
      Navigator.pop(context);
      return;
    }
    exam = localExam;

    final mapping = exam.questionIndexMapping ?? List.generate(exam.questions.length, (i) => i);
    _shuffledQuestions = mapping.map((i) => exam.questions[i]).toList();
    _optionMappings = exam.optionMappings ?? {};

    final metadataBox = Hive.box(LocalDBService.metadataBoxName);
    _maxSeenIndex = metadataBox.get('max_index_$examId') ?? 0;
    
    final localAnswers = LocalDBService.getAnswers(examId);
    if (localAnswers.isNotEmpty) {
      _answers.addAll(localAnswers);
    }

    final DateTime now = DateTime.now();
    final DateTime personalEndTime = now.add(Duration(minutes: exam.durationMinutes));
    DateTime globalEndTime = personalEndTime;
    if (args['session'] != null && args['session']['endTime'] != null) {
      final rawEndTime = args['session']['endTime'];
      if (rawEndTime is Timestamp) {
        globalEndTime = rawEndTime.toDate();
      } else if (rawEndTime is DateTime) {
        globalEndTime = rawEndTime;
      }
    }
    _targetEndTime = globalEndTime.isBefore(personalEndTime) ? globalEndTime : personalEndTime;
    _syncWithServerTime();
    _listenToSessionStatus();
  }

  void _listenToSessionStatus() {
    _sessionSubscription?.cancel();
    _sessionSubscription = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .snapshots()
        .listen((snap) {
      if (snap.exists && snap.data()?['status'] == 'finished') {
        _handleSubmit(isAutomatic: true, reason: "Sesi diakhiri oleh Admin");
      }
    });
  }

  void _syncWithServerTime() async {
    try {
      final serverTime = await sl<RemoteDataSource>().getServerTime(studentId);
      if (!mounted) {
        return;
      }
      
      final diff = serverTime.difference(DateTime.now());
      _targetEndTime = _targetEndTime.subtract(diff); 
      
      _startTimer();
      _startHeartbeat();
      _initMonitoringRecord();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal sinkronisasi waktu aman.")));
        Navigator.pop(context);
      }
    }
  }

  void _initMonitoringRecord() async {
    await sl<RemoteDataSource>().startActiveExam(
      studentId: studentId, studentName: studentName, studentGroup: studentGroup,
      examId: examId, sessionId: sessionId, totalQuestions: _shuffledQuestions.length,
    );
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _syncProgressToCloud();
    });
  }

  void _syncProgressToCloud({String? violation}) {
    if (!mounted || _isSubmitting) {
      return;
    }
    sl<RemoteDataSource>().updateProgress(
      studentId: studentId, sessionId: sessionId,
      currentIndex: _currentIndex, maxSeenIndex: _maxSeenIndex,
      violationCount: _violationCount, answers: _answers,
      violation: violation,
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final difference = _targetEndTime.difference(DateTime.now());
      if (difference.isNegative) {
        timer.cancel();
        _handleSubmit(isAutomatic: true, reason: "Waktu Habis");
      } else {
        setState(() {
          _remainingDuration = difference;
        });
      }
    });
  }

  void _saveLocalProgress() {
    Hive.box(LocalDBService.metadataBoxName).put('max_index_$examId', _maxSeenIndex);
    LocalDBService.saveAnswers(examId, _answers);
    _syncProgressToCloud(); 
  }

  void _handleSubmit({bool isAutomatic = false, String? reason}) async {
    if (_isSubmitting) {
      return;
    }
    if (!isAutomatic && _answers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Minimal jawab 1 soal.")));
      return;
    }

    _timer?.cancel();
    _heartbeatTimer?.cancel();
    _sessionSubscription?.cancel();

    if (mounted) {
      setState(() => _isSubmitting = true);
    }
    
    try {
      int score = 0;
      final finalAnswers = Map<int, dynamic>.from(_answers);
      for (int i = 0; i < exam.questions.length; i++) {
        final q = exam.questions[i];
        final studentAns = finalAnswers[i]; 
        if (studentAns == null) {
          continue;
        }
        if (q.type == 'checkboxes') {
          final correct = List<int>.from(q.correctIndices ?? [])..sort();
          final student = List<int>.from(studentAns)..sort();
          if (jsonEncode(correct) == jsonEncode(student)) {
            score += (q.points ?? 10);
          }
        } else {
          if (studentAns == q.correctOptionIndex) {
            score += (q.points ?? 10);
          }
        }
      }

      final sessionData = (_routeArgs['session'] as Map<dynamic, dynamic>?);
      await sl<RemoteDataSource>().submitResultToCloud(
        studentId: studentId, studentName: studentName, studentGroup: studentGroup,
        examId: examId, sessionId: sessionId, answers: finalAnswers,
        score: score, violationCount: _violationCount, finalIndex: _currentIndex,
        violationReason: reason, sessionName: sessionData?['name'] ?? exam.title,
        kkm: sessionData?['kkm'] ?? 75,
      );

      await LocalDBService.deleteAnswers(examId);
      await Hive.box(LocalDBService.metadataBoxName).delete('max_index_$examId');
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/finish', (route) => false);
        SecurityService.stopKioskMode(); WakelockPlus.disable();
      }
    } catch (e) {
      AppLogger.e("Submit Gagal", e);
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal mengirim jawaban.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_shuffledQuestions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final q = _shuffledQuestions[_currentIndex];
    final int currentOriginalIdx = exam.questions.indexOf(q);
    final List<int> mapping = _optionMappings[currentOriginalIdx] ?? List.generate(q.options.length, (i) => i);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white, elevation: 0, title: _buildTimerBadge(), centerTitle: true, automaticallyImplyLeading: false,
          actions: [IconButton(icon: const Icon(LucideIcons.layoutGrid, color: AppColors.textPrimary), onPressed: () => _showGrid(_shuffledQuestions.length))],
        ),
        body: Column(
          children: [
            LinearProgressIndicator(value: (_currentIndex + 1) / _shuffledQuestions.length, minHeight: 8, backgroundColor: AppColors.background, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary)),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(), padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("SOAL ${_currentIndex + 1} dari ${_shuffledQuestions.length}", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1, fontSize: 12)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            q.type == 'checkboxes' ? "PILIHAN GANDA KOMPLEKS" : q.type == 'true_false' ? "BENAR / SALAH" : "PILIHAN GANDA",
                            style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (q.images != null && q.images!.isNotEmpty)
                      _buildMultiImage(q.images!),
                    Text(q.text, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.4)),
                    const SizedBox(height: 32),
                    ...List.generate(mapping.length, (i) {
                      if (mapping[i] >= q.options.length) {
                        return const SizedBox();
                      }
                      return _buildOption(q, mapping[i], i, currentOriginalIdx);
                    }),
                  ],
                ),
              ),
            ),
            _buildNav(_shuffledQuestions.length),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerBadge() {
    final m = _remainingDuration.inMinutes.toString().padLeft(2, '0');
    final s = (_remainingDuration.inSeconds % 60).toString().padLeft(2, '0');
    return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(20)), child: Text("$m:$s", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.red)));
  }

  Widget _buildOption(Question q, int originalOptionIdx, int displayIdx, int originalQuestionIdx) {
    final isSelected = q.type == 'checkboxes' 
        ? (_answers[originalQuestionIdx] as List? ?? []).contains(originalOptionIdx) 
        : _answers[originalQuestionIdx] == originalOptionIdx;

    Widget leading;
    if (q.type == 'checkboxes') {
      leading = Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: 2)
        ),
        child: isSelected ? const Icon(LucideIcons.check, color: Colors.white, size: 20) : null,
      );
    } else if (q.type == 'true_false') {
      final isTrue = q.options[originalOptionIdx].toLowerCase() == 'benar' || q.options[originalOptionIdx].toLowerCase() == 'true';
      leading = Icon(
        isTrue ? LucideIcons.circleCheck : LucideIcons.circleX,
        color: isSelected ? AppColors.primary : AppColors.border,
        size: 32,
      );
    } else {
      leading = Container(
        width: 36, height: 36, 
        decoration: BoxDecoration(color: isSelected ? AppColors.primary : AppColors.background, shape: BoxShape.circle), 
        child: Center(child: Text(String.fromCharCode(65 + displayIdx), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 14)))
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _isSubmitting ? null : () {
          setState(() {
            if (q.type == 'checkboxes') {
              final current = List<int>.from(_answers[originalQuestionIdx] as List? ?? []);
              if (current.contains(originalOptionIdx)) {
                current.remove(originalOptionIdx);
              } else {
                current.add(originalOptionIdx);
              }
              _answers[originalQuestionIdx] = current;
            } else {
              _answers[originalQuestionIdx] = originalOptionIdx;
            }
            _saveLocalProgress();
          });
        },
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.all(20), 
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white, 
            borderRadius: BorderRadius.circular(24), 
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 3 : 2),
            boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8))] : null,
          ),
          child: Row(children: [
            leading,
            const SizedBox(width: 16),
            Expanded(child: Text(q.options[originalOptionIdx], style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.textPrimary))),
          ]),
        ),
      ),
    );
  }

  Widget _buildNav(int total) {
    final isLast = _currentIndex == total - 1;
    return Container(
      padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(children: [
        if (_currentIndex > 0)
          Expanded(child: OutlinedButton(onPressed: _isSubmitting ? null : () => setState(() => _currentIndex--), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text("KEMBALI", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)))),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: ElevatedButton(
          onPressed: _isSubmitting ? null : () {
            if (_currentIndex < total - 1) { 
              setState(() { 
                _currentIndex++; 
                if (_currentIndex > _maxSeenIndex) {
                  _maxSeenIndex = _currentIndex; 
                  _saveLocalProgress();
                } 
              }); 
            }
            else {
              _showSubmitDialog();
            }
          }, 
          style: ElevatedButton.styleFrom(backgroundColor: isLast ? Colors.green : AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), 
          child: _isSubmitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : Text(isLast ? "KUMPULKAN" : "SELANJUTNYA", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16))
        )),
      ]),
    );
  }

  void _showGrid(int total) {
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))), builder: (context) => Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text("Daftar Soal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 24),
      GridView.builder(shrinkWrap: true, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 12, crossAxisSpacing: 12), itemCount: total, itemBuilder: (context, index) {
        final isLocked = index > _maxSeenIndex;
        final isCurrent = index == _currentIndex;
        final isAnswered = _answers.containsKey(exam.questions.indexOf(_shuffledQuestions[index]));
        return InkWell(onTap: isLocked || _isSubmitting ? null : () { setState(() => _currentIndex = index); Navigator.pop(context); }, child: Container(decoration: BoxDecoration(color: isLocked ? Colors.grey[100] : isCurrent ? AppColors.primary : isAnswered ? AppColors.primary.withValues(alpha: 0.1) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isCurrent ? AppColors.primary : AppColors.border, width: 2)), child: Center(child: isLocked ? const Icon(LucideIcons.lock, size: 16, color: Colors.grey) : Text("${index + 1}", style: TextStyle(fontWeight: FontWeight.bold, color: isCurrent ? Colors.white : AppColors.textPrimary)))));
      }),
      const SizedBox(height: 24),
    ])));
  }

  void _showSubmitDialog() {
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))), builder: (context) => Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(LucideIcons.circleCheck, color: Colors.green, size: 60),
      const SizedBox(height: 24),
      const Text("Selesai Ujian?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      const Text("Pastikan semua jawaban sudah benar ya!", textAlign: TextAlign.center),
      const SizedBox(height: 40),
      SizedBox(width: double.infinity, height: 60, child: ElevatedButton(onPressed: () { Navigator.pop(context); _handleSubmit(); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("YA, KUMPULKAN JAWABAN", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)))),
      TextButton(onPressed: () => Navigator.pop(context), child: const Text("KEMBALI", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
    ])));
  }

  Widget _buildMultiImage(List<String> images) {
    return Padding(padding: const EdgeInsets.only(bottom: 24), child: Wrap(spacing: 8, runSpacing: 8, children: images.map((img) => GestureDetector(onTap: () => _showLargeImage(img), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(base64Decode(img.split(',').last), height: 140, width: 140, fit: BoxFit.cover, gaplessPlayback: true)))).toList()));
  }

  void _showLargeImage(String base64) {
    showDialog(context: context, builder: (context) => Dialog(backgroundColor: Colors.transparent, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Align(alignment: Alignment.topRight, child: IconButton(icon: const Icon(LucideIcons.x, color: Colors.white), onPressed: () => Navigator.pop(context))),
      ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(base64Decode(base64.split(',').last), fit: BoxFit.contain)),
    ])));
  }

  void _handleViolation() {
    if (!mounted || _isSubmitting) {
      return;
    }
    setState(() => _violationCount++);
    _saveLocalProgress();
    if (_violationCount >= 3) {
      _handleSubmit(isAutomatic: true, reason: "Batas Pelanggaran");
    } else {
      if (mounted) {
        _showViolationWarning();
      }
    }
  }

  void _showViolationWarning() {
    showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), title: const Text("⚠️ PERINGATAN", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.red)), content: Text("Dilarang keluar dari aplikasi ujian! Kesempatan tersisa: ${3 - _violationCount}"), actions: [SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("SAYA MENGERTI", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))))]));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isSubmitting) {
      return;
    }
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _handleViolation();
    }
  }

  @override
  void dispose() { 
    WidgetsBinding.instance.removeObserver(this); 
    _timer?.cancel(); 
    _heartbeatTimer?.cancel(); 
    _sessionSubscription?.cancel();
    super.dispose(); 
  }
}
