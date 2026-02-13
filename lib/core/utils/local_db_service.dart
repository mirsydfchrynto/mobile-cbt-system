import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/exam/data/models/exam_model.dart';
import 'app_logger.dart';

class LocalDBService {
  static const String examBoxName = 'exams_box';
  static const String answerBoxName = 'answers_box';
  static const String metadataBoxName = 'metadata_box';
  static const String secureKeyName = 'hive_encryption_key';

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

      await _openAllBoxes(encryptionKey);
      AppLogger.i("LocalDB: All boxes initialized.");
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
  }

  static Future<void> saveAnswers(String examId, Map<int, dynamic> answers) async {
    final box = await Hive.openBox(answerBoxName);
    await box.put(examId, answers);
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
    await box.put('name', name);
    await box.put('group', group);
    await box.put('uid', uid);
  }
}
