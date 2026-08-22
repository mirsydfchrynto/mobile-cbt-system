import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:okey_bimbel/core/theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:okey_bimbel/core/utils/local_db_service.dart';
import 'package:okey_bimbel/core/utils/remote_data_source.dart';
import 'package:okey_bimbel/injection_container.dart';

class ExamFinishPage extends StatefulWidget {
  const ExamFinishPage({super.key});

  @override
  State<ExamFinishPage> createState() => _ExamFinishPageState();
}

class _ExamFinishPageState extends State<ExamFinishPage> {
  bool _isRetrying = false;
  bool _isSynced = false;
  String? _errorMessage;

  Future<void> _retrySubmit(Map<String, dynamic> payload, String pendingDocId) async {
    setState(() {
      _isRetrying = true;
      _errorMessage = null;
    });

    try {
      final answers = Map<int, dynamic>.from(payload['answers'] ?? {});
      await sl<RemoteDataSource>().submitResultToCloud(
        studentId: payload['studentId'],
        studentName: payload['studentName'],
        studentGroup: payload['studentGroup'],
        examId: payload['examId'],
        sessionId: payload['sessionId'],
        answers: answers,
        score: payload['score'],
        violationCount: payload['violationCount'],
        finalIndex: payload['finalIndex'],
        activeToken: payload['activeToken'],
        violationReason: payload['violationReason'],
        sessionName: payload['sessionName'],
      );

      await LocalDBService.deletePendingSubmission(pendingDocId);

      if (mounted) {
        setState(() {
          _isRetrying = false;
          _isSynced = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRetrying = false;
          _errorMessage = "Internet masih belum stabil. Coba tekan tombol lagi ya!";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?) ?? {};
    final bool isDisqualified = (args['isDisqualified'] ?? false) || (args['violationReason'] == 'Batas Pelanggaran');
    final bool isOfflineQueued = !isDisqualified && (args['isOfflineQueued'] ?? false) && !_isSynced;
    final String? pendingDocId = args['pendingDocId'];
    final Map<String, dynamic>? payload = args['payload'];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: isDisqualified
                        ? Colors.red.withValues(alpha: 0.15)
                        : (isOfflineQueued 
                            ? Colors.orange.withValues(alpha: 0.15)
                            : AppColors.success.withValues(alpha: 0.1)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDisqualified
                        ? LucideIcons.shieldAlert
                        : (isOfflineQueued ? LucideIcons.cloudOff : LucideIcons.shieldCheck), 
                    color: isDisqualified
                        ? Colors.red
                        : (isOfflineQueued ? Colors.orange : AppColors.success), 
                    size: 80
                  ),
                ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                
                const SizedBox(height: 48),
                
                Text(
                  isDisqualified
                      ? "Ujian Dihentikan!"
                      : (isOfflineQueued ? "Jawaban Tersimpan di HP!" : "Hebat, Selesai!"),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: isDisqualified ? Colors.red.shade700 : AppColors.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isDisqualified
                      ? "Kamu telah mencapai batas maksimal pelanggaran (berpindah aplikasi / keluar layar). Skor ujianmu tercatat 0. Silakan hubungi guru/pengawas untuk konfirmasi jika diizinkan mengulang."
                      : (isOfflineQueued
                          ? "Koneksi internetmu sedang terputus/lambat. Jangan khawatir! Semua jawabanmu sudah tersimpan aman di HP dan akan terkirim begitu internet terhubung."
                          : "Jawabanmu sudah aman di tangan guru. Kamu boleh keluar dari aplikasi sekarang. Selamat beristirahat ya!"),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                ],

                const SizedBox(height: 48),
                
                if (isOfflineQueued && pendingDocId != null && payload != null) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isRetrying ? null : () => _retrySubmit(payload, pendingDocId),
                      icon: _isRetrying 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(LucideIcons.refreshCw, size: 20),
                      label: Text(
                        _isRetrying ? "MENGIRIM JAWABAN..." : "KIRIM SEKARANG (COBA LAGI)",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(
                      "KEMBALI KE BERANDA",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
