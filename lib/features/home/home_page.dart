import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:okey_bimbel/core/theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:okey_bimbel/core/utils/local_db_service.dart';
import 'package:okey_bimbel/core/utils/student_utils.dart';
import 'package:okey_bimbel/core/utils/app_logger.dart';
import 'package:okey_bimbel/features/exam/data/models/exam_model.dart';
import 'package:okey_bimbel/features/home/identity_page.dart';
import 'package:talker_flutter/talker_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isDownloading = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _groupController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedIdentity();
  }

  void _loadSavedIdentity() async {
    try {
      final metadata = LocalDBService.getStudentMetadata();
      _nameController.text = metadata['name'] ?? "";
      _groupController.text = metadata['group'] ?? "";
    } catch (e) {
      AppLogger.e("Load Identity Failed", e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, 
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            children: [
              const Spacer(flex: 2),
              GestureDetector(
                onLongPress: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TalkerScreen(talker: AppLogger.talker))),
                child: Hero(
                  tag: 'app_logo',
                  child: Image.asset(
                    'assets/images/logo.png', 
                    height: 100,
                    errorBuilder: (c, e, s) => const Icon(LucideIcons.graduationCap, size: 80, color: AppColors.primary),
                  ),
                ),
              ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.9, 0.9)),
              const Spacer(flex: 3),
              _buildScanButton(),
              const Spacer(flex: 4),
              _buildCompactGuide(),
              const SizedBox(height: 32),
              Text(
                "OKEY BIMBEL v1.3",
                style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.textSecondary.withValues(alpha: 0.2), letterSpacing: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    return GestureDetector(
      onTap: _isDownloading ? null : () => _showScanner(),
      child: Container(
        width: 220, height: 220,
        decoration: BoxDecoration(
          color: Colors.white, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 60, offset: const Offset(0, 25))],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isDownloading 
                ? const SizedBox(width: 50, height: 50, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 5))
                : Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), shape: BoxShape.circle),
                    child: const Icon(LucideIcons.qrCode, color: AppColors.primary, size: 60),
                  ),
              const SizedBox(height: 20),
              Text(
                _isDownloading ? "PROSES DATA..." : "MULAI UJIAN",
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 2),
              ),
            ],
          ),
        ),
      ),
    ).animate(target: _isDownloading ? 0 : 1, onPlay: (c) => c.repeat(reverse: true)).scale(duration: 2.seconds, begin: const Offset(1, 1), end: const Offset(1.05, 1.05));
  }

  Widget _buildCompactGuide() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(28), border: Border.all(color: AppColors.primary.withValues(alpha: 0.05))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _guideIcon(LucideIcons.scan, "Scan QR"),
          _guideIcon(LucideIcons.userCheck, "Isi Data"),
          _guideIcon(LucideIcons.shieldCheck, "Mulai"),
        ],
      ),
    );
  }

  Widget _guideIcon(IconData icon, String label) {
    return Column(children: [Icon(icon, size: 20, color: AppColors.primary.withValues(alpha: 0.5)), const SizedBox(height: 8), Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary.withValues(alpha: 0.6)))]);
  }

  void _showScanner() async {
    final String? result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ScannerPage()),
    );

    if (result != null && mounted) {
      _handleQRDiscovery(result);
    }
  }

  void _handleQRDiscovery(String code) async {
    if (!mounted) return;
    setState(() => _isDownloading = true);
    
    try {
      AppLogger.i("Discovery: Spliting code...");
      final parts = code.split('|');
      if (parts.length < 3 || parts[0] != 'SCBT') throw "Format QR tidak dikenal";
      
      final String examId = parts[1];
      final String sessionId = parts[2];

      AppLogger.i("Discovery: Fetching session $sessionId...");
      final sessionDoc = await FirebaseFirestore.instance.collection('sessions')
          .doc(sessionId).get().timeout(const Duration(seconds: 10));
      
      if (!sessionDoc.exists) throw "Sesi pengerjaan tidak ditemukan di server";
      final sessionData = sessionDoc.data()!;

      if (sessionData['status'] != 'active') throw "Sesi sudah tidak aktif atau telah ditutup";
      if (sessionData['activeToken'] != code) throw "Token sudah kedaluwarsa, silakan scan ulang QR terbaru dari layar proyektor";

      AppLogger.i("Discovery: Processing exam data...");
      Map<String, dynamic> examRawData;
      if (sessionData['examSnapshot'] != null) {
        examRawData = Map<String, dynamic>.from(sessionData['examSnapshot']);
        examRawData['id'] = examId;
      } else {
        final examDoc = await FirebaseFirestore.instance.collection('exams').doc(examId).get().timeout(const Duration(seconds: 10));
        if (!examDoc.exists) throw "Materi soal asli tidak ditemukan";
        examRawData = examDoc.data()!;
        examRawData['id'] = examId;
      }

      final List<dynamic> questionsRaw = examRawData['questions'] ?? [];
      final List<Question> questions = questionsRaw.map((q) {
        try {
          return Question(
            id: q['id']?.toString() ?? StudentUtils.generateNewId(),
            text: q['text']?.toString() ?? "",
            options: List<String>.from(q['options'] ?? []),
            correctOptionIndex: q['correctOptionIndex'] ?? q['correctIndex'],
            type: q['type']?.toString() ?? 'multiple_choice',
            correctIndices: q['correctIndices'] != null ? List<int>.from(q['correctIndices']) : null,
            points: q['points'] ?? 10,
            images: q['images'] != null ? List<String>.from(q['images']) : null,
          );
        } catch (e) {
          AppLogger.e("Question Mapping Error", e);
          throw "Gagal memproses butir soal. Format data tidak valid.";
        }
      }).toList();

      final examModel = Exam(
        id: examId, title: examRawData['title']?.toString() ?? "Ujian", questions: questions,
        durationMinutes: sessionData['duration'] ?? 60,
        shuffleQuestions: examRawData['shuffleQuestions'] ?? false,
        shuffleOptions: examRawData['shuffleOptions'] ?? false,
        navigationMode: 'sequential',
      );

      if (examModel.questionIndexMapping == null) {
        List<int> mapping = List.generate(questions.length, (i) => i);
        if (examModel.shuffleQuestions) mapping.shuffle();
        examModel.questionIndexMapping = mapping;
        Map<int, List<int>> optMappings = {};
        for (int i = 0; i < questions.length; i++) {
          List<int> optMap = List.generate(questions[i].options.length, (j) => j);
          if (examModel.shuffleOptions) optMap.shuffle();
          optMappings[i] = optMap;
        }
        examModel.optionMappings = optMappings;
      }

      AppLogger.i("Discovery: Saving to LocalDB...");
      await LocalDBService.saveExam(examModel);
      
      if (mounted) {
        setState(() => _isDownloading = false);
        // NAVIGASI LANGSUNG KE HALAMAN IDENTITAS (STABIL)
        Navigator.push(
          context, 
          MaterialPageRoute(
            builder: (context) => IdentityPage(
              exam: examModel, 
              session: sessionData, 
              examId: examId, 
              sessionId: sessionId
            )
          )
        );
      }
    } catch (e, stack) {
      AppLogger.e("Discovery Fatal Error", e, stack);
      if (mounted) {
        setState(() => _isDownloading = false);
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("⚠️ Gagal Memulai", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.red)),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("SAYA MENGERTI", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          )
        ],
      ),
    );
  }
}

class ScannerPage extends StatelessWidget {
  const ScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: Text("SCAN QR UJIAN", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final barcode = capture.barcodes.firstOrNull;
              if (barcode?.rawValue != null) {
                Navigator.pop(context, barcode!.rawValue);
              }
            },
          ),
          Center(
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                borderRadius: BorderRadius.circular(40)
              ),
            ),
          ),
        ],
      ),
    );
  }
}
