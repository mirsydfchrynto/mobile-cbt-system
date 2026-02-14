import 'package:flutter/foundation.dart'; // for compute
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
  bool _isScanning = false;
  String _loadingStatus = ""; // Status text for user visibility
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
      body: Stack(
        children: [
          SafeArea(
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
                    "OKEY BIMBEL v1.3.1 (STABLE)",
                    style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.textSecondary.withValues(alpha: 0.2), letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ),
          if (_isDownloading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return GestureDetector(
      onLongPress: () {
        // Emergency Reset mechanism
        setState(() => _isDownloading = false);
        AppLogger.w("User forced reset from loading screen");
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white.withValues(alpha: 0.95), // Solid background
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 5).animate().scale(duration: 400.ms),
              const SizedBox(height: 24),
              Text(
                "MEMPROSES DATA...",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, 
                  fontWeight: FontWeight.w900, 
                  color: AppColors.primary,
                  letterSpacing: 2
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _loadingStatus,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary
                ),
              ).animate().fadeIn(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    return GestureDetector(
      onTap: (_isDownloading || _isScanning) ? null : () => _showScanner(),
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
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), shape: BoxShape.circle),
                child: const Icon(LucideIcons.qrCode, color: AppColors.primary, size: 60),
              ),
              const SizedBox(height: 20),
              Text(
                "MULAI UJIAN",
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 2),
              ),
            ],
          ),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 2.seconds, begin: const Offset(1, 1), end: const Offset(1.05, 1.05));
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
    setState(() => _isScanning = true);
    AppLogger.i("Opening Scanner...");
    
    // Gunakan try-catch block untuk scanner navigation
    try {
      final String? result = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ScannerPage()),
      );
      
      AppLogger.i("Scanner closed. Result: $result");
      
      // Jeda wajib untuk membiarkan resource kamera lepas sepenuhnya & UI rebuild
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (mounted) {
        setState(() => _isScanning = false);
        if (result != null) {
          _handleQRDiscovery(result);
        }
      }
    } catch (e) {
      AppLogger.e("Scanner Error", e);
      setState(() => _isScanning = false);
    }
  }

  void _handleQRDiscovery(String code) async {
    if (!mounted) return;
    
    // 1. Set State Loading
    setState(() {
      _isDownloading = true;
      _loadingStatus = "Validasi Kode...";
    });
    
    try {
      AppLogger.i("Discovery: Parsing code...");
      final parts = code.split('|');
      if (parts.length < 3 || parts[0] != 'SCBT') throw "Format QR Salah";
      
      final String examId = parts[1];
      final String sessionId = parts[2];

      // 2. Fetch Session
      if (mounted) setState(() => _loadingStatus = "Mengecek Sesi...");
      AppLogger.i("Discovery: Fetching session $sessionId...");
      
      final sessionDoc = await FirebaseFirestore.instance.collection('sessions')
          .doc(sessionId).get().timeout(const Duration(seconds: 15)); // Timeout lebih panjang
      
      if (!sessionDoc.exists) throw "Sesi tidak ditemukan";
      final sessionData = sessionDoc.data()!;

      if (sessionData['status'] != 'active') throw "Sesi Ujian Ditutup";
      
      // Validation with Grace Period (activeToken or lastToken)
      final String activeToken = sessionData['activeToken'] ?? "";
      final String lastToken = sessionData['lastToken'] ?? "";
      
      if (activeToken != code && lastToken != code) {
        throw "Token QR Kedaluwarsa. Silakan scan ulang QR terbaru.";
      }

      // 3. Fetch Exam Data
      if (mounted) setState(() => _loadingStatus = "Mengunduh Soal...");
      AppLogger.i("Discovery: Fetching exam data...");
      
      Map<String, dynamic> examRawData;
      if (sessionData['examSnapshot'] != null) {
        examRawData = Map<String, dynamic>.from(sessionData['examSnapshot']);
        examRawData['id'] = examId;
      } else {
        final examDoc = await FirebaseFirestore.instance.collection('exams').doc(examId).get().timeout(const Duration(seconds: 20));
        if (!examDoc.exists) throw "Data Soal Hilang";
        examRawData = examDoc.data()!;
        examRawData['id'] = examId;
      }

      // 4. Heavy Processing in Isolate (Compute)
      if (mounted) setState(() => _loadingStatus = "Menyiapkan Ujian...");
      AppLogger.i("Discovery: Processing Logic...");
      
      // Kirim data mentah ke isolate untuk diproses agar UI tidak freeze
      final Exam examModel = await compute(_processExamData, examRawData);
      
      // Override duration from session
      final finalExamModel = Exam(
        id: examModel.id,
        title: examModel.title,
        questions: examModel.questions,
        durationMinutes: sessionData['duration'] ?? examModel.durationMinutes,
        shuffleQuestions: examModel.shuffleQuestions,
        shuffleOptions: examModel.shuffleOptions,
        navigationMode: examModel.navigationMode,
        questionIndexMapping: examModel.questionIndexMapping,
        optionMappings: examModel.optionMappings,
      );

      // 5. Save to LocalDB
      AppLogger.i("Discovery: Saving to DB...");
      await LocalDBService.saveExam(finalExamModel);
      
      if (mounted) {
        setState(() => _loadingStatus = "Selesai!");
        await Future.delayed(const Duration(milliseconds: 500)); // Visual delay
        
        if (!mounted) return;
        setState(() => _isDownloading = false);
        
        // 6. Navigate Cleanly
        Navigator.push(
          context, 
          MaterialPageRoute(
            builder: (context) => IdentityPage(
              exam: finalExamModel, 
              session: sessionData, 
              examId: examId, 
              sessionId: sessionId
            )
          )
        );
      }
    } catch (e, stack) {
      AppLogger.e("Discovery Failed", e, stack);
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _loadingStatus = "";
        });
        _showErrorDialog(e.toString());
      }
    }
  }

  // Fungsi Statis untuk Compute (Isolate)
  static Exam _processExamData(Map<String, dynamic> data) {
    try {
      final List<dynamic> questionsRaw = data['questions'] ?? [];
      final List<Question> questions = questionsRaw.map((q) {
        return Question(
          id: q['id']?.toString() ?? StudentUtils.generateNewId(),
          text: q['text']?.toString() ?? "",
          options: List<String>.from(q['options'] ?? []),
          correctOptionIndex: q['correctOptionIndex'] ?? q['correctIndex'],
          type: q['type']?.toString() ?? 'multiple_choice',
          correctIndices: q['correctIndices'] != null ? List<int>.from(q['correctIndices']) : null,
          points: q['points'] ?? 10,
          images: q['images'] != null ? List<String>.from(q['images']) : null,
          optionImages: q['optionImages'] != null ? List<String>.from(q['optionImages']) : null,
          statements: q['statements'] != null ? (q['statements'] as List).map((s) => Statement(
            text: s['text']?.toString() ?? "",
            isCorrect: s['isCorrect'] ?? false,
            imageUrl: s['imageUrl']?.toString(),
          )).toList() : null,
        );
      }).toList();

      final examModel = Exam(
        id: data['id'], 
        title: data['title']?.toString() ?? "Ujian", 
        questions: questions,
        durationMinutes: data['duration'] ?? 60,
        shuffleQuestions: data['shuffleQuestions'] ?? false,
        shuffleOptions: data['shuffleOptions'] ?? false,
        navigationMode: 'sequential',
      );

      // Pre-calculate shuffles in isolate
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
      
      return examModel;
    } catch (e) {
      throw "Gagal memproses data soal: $e";
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("⚠️ Waduh, Belum Bisa Mulai", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.red)),
        content: SingleChildScrollView(child: Text(message)), // Prevent overflow
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("COBA LAGI YA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          )
        ],
      ),
    );
  }
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.qrCode],
  );

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    controller.dispose();
    super.dispose();
  }

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
            controller: controller,
            onDetect: (capture) {
              if (_isDisposed) return;
              final barcode = capture.barcodes.firstOrNull;
              if (barcode?.rawValue != null) {
                // Prevent multiple pops
                if (mounted) {
                   Navigator.of(context).pop(barcode!.rawValue);
                }
              }
            },
            errorBuilder: (context, error) {
              return Center(child: Text("Camera Error: $error", style: const TextStyle(color: Colors.red)));
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
