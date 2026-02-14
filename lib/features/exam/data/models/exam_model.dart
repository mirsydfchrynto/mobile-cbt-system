import 'package:hive/hive.dart';

part 'exam_model.g.dart';

@HiveType(typeId: 2)
class Statement extends HiveObject {
  @HiveField(0)
  final String text;

  @HiveField(1)
  final bool isCorrect;

  @HiveField(2)
  final String? imageUrl;

  Statement({
    required this.text,
    required this.isCorrect,
    this.imageUrl,
  });
}

@HiveType(typeId: 0)
class Question extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String text;

  @HiveField(2)
  final List<String> options;

  @HiveField(3)
  final int? correctOptionIndex;

  @HiveField(4)
  final String? imageUrl; // Legacy support

  @HiveField(5)
  String? type; // 'multiple_choice', 'checkboxes', or 'true_false'

  @HiveField(6)
  final List<int>? correctIndices; // For checkboxes

  @HiveField(7)
  int? points;

  @HiveField(8)
  final List<String>? images; // Support for multiple base64 images

  @HiveField(9)
  final List<String>? optionImages; // Support for images per option

  @HiveField(10)
  final List<Statement>? statements; // For true_false multi-statement

  Question({
    required this.id,
    required this.text,
    required this.options,
    this.correctOptionIndex,
    this.imageUrl,
    this.type = 'multiple_choice',
    this.correctIndices,
    this.points = 10,
    this.images,
    this.optionImages,
    this.statements,
  });
}

@HiveType(typeId: 1)
class Exam extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final List<Question> questions;

  @HiveField(3)
  final int durationMinutes;

  @HiveField(4)
  final bool shuffleQuestions;

  @HiveField(5)
  final bool shuffleOptions;

  @HiveField(6)
  final String navigationMode; // 'sequential' or 'free'

  @HiveField(7)
  List<int>? questionIndexMapping; // Stores the shuffled order of question indices

  @HiveField(8)
  Map<int, List<int>>? optionMappings; // Stores shuffled order of options per question index

  Exam({
    required this.id,
    required this.title,
    required this.questions,
    required this.durationMinutes,
    this.shuffleQuestions = false,
    this.shuffleOptions = false,
    this.navigationMode = 'sequential',
    this.questionIndexMapping,
    this.optionMappings,
  });
}
