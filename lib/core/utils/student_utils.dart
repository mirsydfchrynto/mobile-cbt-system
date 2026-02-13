import 'dart:math';

class StudentUtils {
  /// Normalisasi Nama: Trim + Capitalize Every Word
  static String normalizeName(String name) {
    if (name.trim().isEmpty) {
      return "";
    }
    return name.trim().split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) {
        return "";
      }
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Generate ID baru dengan format STD-timestamp-random
  static String generateNewId() {
    final random = Random().nextInt(999999).toString().padLeft(6, '0');
    return "STD-${DateTime.now().microsecondsSinceEpoch}-$random";
  }

  /// ID cadangan berbasis nama jika ID utama hilang
  static String generateSlugId(String normalizedName) {
    return normalizedName.replaceAll(' ', '_').toLowerCase();
  }
}
