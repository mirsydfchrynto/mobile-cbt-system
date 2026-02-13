import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:okey_bimbel/core/theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:okey_bimbel/features/exam/data/models/exam_model.dart';

class ExamPrepPage extends StatelessWidget {
  const ExamPrepPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final Exam exam = args['exam'];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              const SizedBox(height: 60),
              
              // Animasi Ikon Berdenyut
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05), 
                  shape: BoxShape.circle
                ),
                child: const Icon(LucideIcons.bookOpen, color: AppColors.primary, size: 60),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .scale(duration: 1.seconds, begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1)),
              
              const SizedBox(height: 48),
              
              Text(
                "Soal Sudah Siap!",
                style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                exam.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, 
                  fontWeight: FontWeight.w700, 
                  color: AppColors.primary,
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Kartu Detail Soal (Mudah Dibaca)
              Row(
                children: [
                  Expanded(child: _buildInfoCard(LucideIcons.clock, "${exam.durationMinutes}", "MENIT", Colors.orange)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildInfoCard(LucideIcons.listTodo, "${exam.questions.length}", "SOAL", Colors.green)),
                ],
              ),

              const SizedBox(height: 24),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.shieldCheck, color: AppColors.primary, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        "Mode ujian aman sudah aktif. Kerjakan dengan jujur ya!",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, 
                          fontWeight: FontWeight.w600, 
                          color: AppColors.textSecondary
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48), // Diperkecil agar tombol naik
              
              SizedBox(
                width: double.infinity,
                height: 64, // Sedikit diperkecil agar pas
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/exam_room', arguments: args);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 4,
                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  child: const Text("MULAI MENGERJAKAN", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 16)),
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: color, letterSpacing: 1)),
        ],
      ),
    );
  }
}
