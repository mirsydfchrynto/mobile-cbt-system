import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/exam/data/models/exam_model.dart';
import 'app_logger.dart';

class LocalDBService {
  static const String examBoxName = 'exams_box';
  static const String answerBoxName = 'answers_box';
  static const String metadataBoxName = 'metadata_box';
  static const String pendingSubmissionBoxName = 'pending_submissions_box';
  static const String secureKeyName = 'hive_encryption_key';
  static const String examChecksumKey = 'exam_box_checksum';
  static const String answerChecksumKey = 'answer_box_checksum';

  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      const storage = FlutterSecureStorage();
      
      String? key = await storage.read(key: secureKeyName);
      if (key == null) {
        final secureKey = Hive.generateSecureKey();
        await storage.write(key: secureKeyName, value: base64UrlEncode(secureKey));
        key = base64UrlEncode(secureKey);
      }
      
      final encryptionKey = base64Url.decode(key);

      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(QuestionAdapter());
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ExamAdapter());
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(StatementAdapter());

      await _openAllBoxes(encryptionKey);
      
      // Verify box integrity on startup
      await _verifyBoxIntegrity();
      
      AppLogger.i("LocalDB: All boxes initialized and verified.");
    } catch (e, stack) {
      AppLogger.e("LocalDB: Init failed, attempting recovery...", e, stack);
      await _recover(encryptionKey: null); // Re-init without key or clear
    }
  }

  static Future<void> _openAllBoxes(List<int> encryptionKey) async {
    final cipher = HiveAesCipher(encryptionKey);
    if (!Hive.isBoxOpen(examBoxName)) await Hive.openBox<Exam>(examBoxName, encryptionCipher: cipher);
    if (!Hive.isBoxOpen(answerBoxName)) await Hive.openBox(answerBoxName, encryptionCipher: cipher);
    if (!Hive.isBoxOpen(metadataBoxName)) await Hive.openBox(metadataBoxName, encryptionCipher: cipher);
    if (!Hive.isBoxOpen(pendingSubmissionBoxName)) await Hive.openBox(pendingSubmissionBoxName, encryptionCipher: cipher);
  }

  static Future<void> _verifyBoxIntegrity() async {
    try {
      // Verify exam box
      if (Hive.isBoxOpen(examBoxName)) {
        final examBox = Hive.box<Exam>(examBoxName);
        final storedChecksum = Hive.box(metadataBoxName).get(examChecksumKey) as String?;
        final computedChecksum = _computeExamBoxChecksum(examBox);
        
        if (storedChecksum != null && storedChecksum != computedChecksum) {
          AppLogger.w("LocalDB: Exam box checksum mismatch — potential corruption detected!");
          await _recoverExamBox();
        } else {
          // Update checksum
          await Hive.box(metadataBoxName).put(examChecksumKey, computedChecksum);
        }
      }

      // Verify answer box
      if (Hive.isBoxOpen(answerBoxName)) {
        final answerBox = Hive.box(answerBoxName);
        final storedChecksum = Hive.box(metadataBoxName).get(answerChecksumKey) as String?;
        final computedChecksum = _computeAnswerBoxChecksum(answerBox);
        
        if (storedChecksum != null && storedChecksum != computedChecksum) {
          AppLogger.w("LocalDB: Answer box checksum mismatch — potential corruption detected!");
          await _recoverAnswerBox();
        } else {
          await Hive.box(metadataBoxName).put(answerChecksumKey, computedChecksum);
        }
      }
    } catch (e) {
      AppLogger.e("LocalDB: Integrity check failed", e);
    }
  }

  static String _computeExamBoxChecksum(Box<Exam> box) {
    final buffer = StringBuffer();
    for (final key in box.keys) {
      final exam = box.get(key);
      if (exam != null) {
        buffer.write('${exam.id}:${exam.questions.length}:${exam.updatedAt ?? 0}|');
      }
    }
    return _simpleHash(buffer.toString());
  }

  static String _computeAnswerBoxChecksum(Box box) {
    final buffer = StringBuffer();
    for (final key in box.keys) {
      final answers = box.get(key);
      if (answers != null) {
        final answerMap = Map<int, dynamic>.from(answers);
        buffer.write('$key:${answerMap.length}:${answerMap.values.toList().toString()}|');
      }
    }
    return _simpleHash(buffer.toString());
  }

  static String _simpleHash(String input) {
    // Simple FNV-1a hash for quick integrity check
    int hash = 0x811c9dc5;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  static Future<void> _recoverExamBox() async {
    AppLogger.w("LocalDB: Recovering exam box...");
    if (Hive.isBoxOpen(examBoxName)) await Hive.box(examBoxName).close();
    await Hive.deleteBoxFromDisk(examBoxName);
    AppLogger.i("LocalDB: Exam box recovered (cleared).");
  }

  static Future<void> _recoverAnswerBox() async {
    AppLogger.w("LocalDB: Recovering answer box...");
    if (Hive.isBoxOpen(answerBoxName)) await Hive.box(answerBoxName).close();
    await Hive.deleteBoxFromDisk(answerBoxName);
    AppLogger.i("LocalDB: Answer box recovered (cleared).");
  }

  static Future<void> _recover({List<int>? encryptionKey}) async {
    try {
      await Hive.close();
      await Hive.deleteBoxFromDisk(examBoxName);
      await Hive.deleteBoxFromDisk(answerBoxName);
      await Hive.deleteBoxFromDisk(metadataBoxName);
      // Re-open with new files if corrupted
      if (encryptionKey != null) await _openAllBoxes(encryptionKey);
    } catch (e) {
      AppLogger.e("LocalDB: Recovery fatal failure", e);
    }
  }

  static Future<void> saveExam(Exam exam) async {
    final box = await Hive.openBox<Exam>(examBoxName); // Ensure open
    await box.put(exam.id, exam);
    // Update checksum
    final checksum = _computeExamBoxChecksum(box);
    await Hive.box(metadataBoxName).put(examChecksumKey, checksum);
  }

  static Future<void> saveAnswers(String examId, Map<int, dynamic> answers) async {
    final box = await Hive.openBox(answerBoxName);
    await box.put(examId, answers);
    // Update checksum
    final checksum = _computeAnswerBoxChecksum(box);
    await Hive.box(metadataBoxName).put(answerChecksumKey, checksum);
  }

  static Map<int, dynamic> getAnswers(String examId) {
    if (!Hive.isBoxOpen(answerBoxName)) return {};
    final box = Hive.box(answerBoxName);
    final data = box.get(examId);
    if (data == null) return {};
    return Map<int, dynamic>.from(data);
  }

  static Future<void> deleteAnswers(String examId) async {
    final box = await Hive.openBox(answerBoxName);
    await box.delete(examId);
    // Update checksum
    final checksum = _computeAnswerBoxChecksum(box);
    await Hive.box(metadataBoxName).put(answerChecksumKey, checksum);
  }

  static Map<String, String?> getStudentMetadata() {
    if (!Hive.isBoxOpen(metadataBoxName)) return {'name': null, 'group': null, 'uid': null};
    final box = Hive.box(metadataBoxName);
    return {
      'name': box.get('name') as String?,
      'group': box.get('group') as String?,
      'uid': box.get('uid') as String?,
    };
  }

  static Future<void> saveStudentMetadata(String name, String group, String uid) async {
    final box = await Hive.openBox(metadataBoxName);
    final currentUid = box.get('uid') as String?;
    
    // RED-TEAM FIX: If a different student logs in on the same device, clear previous student's local answers!
    if (currentUid != null && currentUid != uid) {
      AppLogger.w("LocalDB: Account switch detected ($currentUid -> $uid). Clearing stale local answers!");
      await clearUserSession();
    }
    
    await box.put('name', name);
    await box.put('group', group);
    await box.put('uid', uid);
  }

  static Future<void> savePendingSubmission(String docId, Map<String, dynamic> data) async {
    final box = await Hive.openBox(pendingSubmissionBoxName);
    await box.put(docId, data);
    AppLogger.i("LocalDB: Result submission queued offline under ID $docId");
  }

  static Map<String, dynamic> getPendingSubmissions() {
    if (!Hive.isBoxOpen(pendingSubmissionBoxName)) return {};
    final box = Hive.box(pendingSubmissionBoxName);
    final Map<String, dynamic> result = {};
    for (var key in box.keys) {
      final val = box.get(key);
      if (val != null) {
        result[key.toString()] = Map<String, dynamic>.from(val);
      }
    }
    return result;
  }

  static Future<void> deletePendingSubmission(String docId) async {
    if (!Hive.isBoxOpen(pendingSubmissionBoxName)) return;
    final box = Hive.box(pendingSubmissionBoxName);
    await box.delete(docId);
    AppLogger.i("LocalDB: Pending submission $docId flushed and deleted.");
  }

  static Future<void> clearUserSession() async {
    try {
      if (Hive.isBoxOpen(answerBoxName)) await Hive.box(answerBoxName).clear();
      if (Hive.isBoxOpen(metadataBoxName)) await Hive.box(metadataBoxName).clear();
      AppLogger.i("LocalDB: User session data cleared completely.");
    } catch (e) {
      AppLogger.e("LocalDB: Failed to clear session", e);
    }
  }
}
