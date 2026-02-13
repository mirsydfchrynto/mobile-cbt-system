import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:okey_bimbel/core/theme/app_colors.dart';
import 'package:okey_bimbel/core/utils/local_db_service.dart';
import 'package:okey_bimbel/core/utils/student_utils.dart';
import 'package:okey_bimbel/core/utils/remote_data_source.dart';
import 'package:okey_bimbel/injection_container.dart';
import 'package:okey_bimbel/features/exam/data/models/exam_model.dart';

class IdentityPage extends StatefulWidget {
  final Exam exam;
  final Map<String, dynamic> session;
  final String examId;
  final String sessionId;

  const IdentityPage({
    super.key,
    required this.exam,
    required this.session,
    required this.examId,
    required this.sessionId,
  });

  @override
  State<IdentityPage> createState() => _IdentityPageState();
}

class _IdentityPageState extends State<IdentityPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _groupController = TextEditingController();
  bool _isLoading = false;
  String? _savedUid;

  @override
  void initState() {
    super.initState();
    _loadSavedIdentity();
  }

  void _loadSavedIdentity() {
    final metadata = LocalDBService.getStudentMetadata();
    _nameController.text = metadata['name'] ?? "";
    _groupController.text = metadata['group'] ?? "";
    _savedUid = metadata['uid'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "IDENTITAS PESERTA",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12, 
            fontWeight: FontWeight.w900, 
            color: AppColors.textPrimary, 
            letterSpacing: 1
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Siapa namamu?",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28, 
                fontWeight: FontWeight.w900, 
                color: AppColors.primary
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Masukkan nama lengkap dan kelasmu untuk mulai ujian ya.",
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary, 
                fontSize: 14,
                fontWeight: FontWeight.w500
              ),
            ),
            const SizedBox(height: 48),
            _buildField("NAMA LENGKAP", _nameController, LucideIcons.user),
            const SizedBox(height: 32),
            _buildField("KELAS / GRUP", _groupController, LucideIcons.users),
            const SizedBox(height: 64),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      "LANJUTKAN", 
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900, 
                        color: Colors.white, 
                        fontSize: 16,
                        letterSpacing: 1
                      )
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10, 
            fontWeight: FontWeight.w800, 
            color: AppColors.textSecondary, 
            letterSpacing: 2
          )
        ),
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold, 
            fontSize: 18, 
            color: AppColors.textPrimary
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
            prefixIconConstraints: const BoxConstraints(minWidth: 40),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.border, width: 2)
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 2)
            ),
          ),
        ),
      ],
    );
  }

  void _handleContinue() async {
    final name = _nameController.text.trim();
    final group = _groupController.text.trim();

    if (name.isEmpty || group.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mohon isi nama dan kelas ya!"))
      );
      return;
    }

    setState(() => _isLoading = true);
    final normalizedName = StudentUtils.normalizeName(name);
    
    // Logic Identitas (Nama sebagai kunci)
    final metadata = LocalDBService.getStudentMetadata();
    final savedName = metadata['name'] ?? "";
    
    String uid;
    if (_savedUid != null && normalizedName.toLowerCase() == savedName.toLowerCase()) {
      uid = _savedUid!;
    } else {
      uid = StudentUtils.generateNewId();
    }

    try {
      await LocalDBService.saveStudentMetadata(normalizedName, group, uid);
      await sl<RemoteDataSource>().syncStudentData(uid: uid, name: normalizedName, group: group);
      
      if (mounted) {
        // Micro delay untuk stabilitas transisi
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
        
        setState(() => _isLoading = false);
        Navigator.pushReplacementNamed(context, '/exam_prep', arguments: {
          'exam': widget.exam,
          'session': widget.session,
          'examId': widget.examId,
          'sessionId': widget.sessionId,
          'student_id': uid,
          'student_name': normalizedName,
          'student_group': group,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal sinkronisasi data: $e"))
        );
      }
    }
  }
}
