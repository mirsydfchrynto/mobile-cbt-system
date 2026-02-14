// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StatementAdapter extends TypeAdapter<Statement> {
  @override
  final int typeId = 2;

  @override
  Statement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Statement(
      text: fields[0] as String,
      isCorrect: fields[1] as bool,
      imageUrl: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Statement obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.text)
      ..writeByte(1)
      ..write(obj.isCorrect)
      ..writeByte(2)
      ..write(obj.imageUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class QuestionAdapter extends TypeAdapter<Question> {
  @override
  final int typeId = 0;

  @override
  Question read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Question(
      id: fields[0] as String,
      text: fields[1] as String,
      options: (fields[2] as List).cast<String>(),
      correctOptionIndex: fields[3] as int?,
      imageUrl: fields[4] as String?,
      type: fields[5] as String?,
      correctIndices: (fields[6] as List?)?.cast<int>(),
      points: fields[7] as int?,
      images: (fields[8] as List?)?.cast<String>(),
      optionImages: (fields[9] as List?)?.cast<String>(),
      statements: (fields[10] as List?)?.cast<Statement>(),
    );
  }

  @override
  void write(BinaryWriter writer, Question obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.options)
      ..writeByte(3)
      ..write(obj.correctOptionIndex)
      ..writeByte(4)
      ..write(obj.imageUrl)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.correctIndices)
      ..writeByte(7)
      ..write(obj.points)
      ..writeByte(8)
      ..write(obj.images)
      ..writeByte(9)
      ..write(obj.optionImages)
      ..writeByte(10)
      ..write(obj.statements);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExamAdapter extends TypeAdapter<Exam> {
  @override
  final int typeId = 1;

  @override
  Exam read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Exam(
      id: fields[0] as String,
      title: fields[1] as String,
      questions: (fields[2] as List).cast<Question>(),
      durationMinutes: fields[3] as int,
      shuffleQuestions: fields[4] as bool,
      shuffleOptions: fields[5] as bool,
      navigationMode: fields[6] as String,
      questionIndexMapping: (fields[7] as List?)?.cast<int>(),
      optionMappings: (fields[8] as Map?)?.map((dynamic k, dynamic v) =>
          MapEntry(k as int, (v as List).cast<int>())),
    );
  }

  @override
  void write(BinaryWriter writer, Exam obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.questions)
      ..writeByte(3)
      ..write(obj.durationMinutes)
      ..writeByte(4)
      ..write(obj.shuffleQuestions)
      ..writeByte(5)
      ..write(obj.shuffleOptions)
      ..writeByte(6)
      ..write(obj.navigationMode)
      ..writeByte(7)
      ..write(obj.questionIndexMapping)
      ..writeByte(8)
      ..write(obj.optionMappings);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
