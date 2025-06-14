// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'CourseData.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CourseDataAdapter extends TypeAdapter<CourseData> {
  @override
  final int typeId = 1;

  @override
  CourseData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CourseData(
      id: fields[0] as String,
      name: fields[1] as String,
      credit: fields[2] as int,
      professor: fields[3] as String,
      classTime: fields[4] as String?,
      location: fields[5] as String?,
      syllabus: fields[6] as String?,
      grading: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CourseData obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.credit)
      ..writeByte(3)
      ..write(obj.professor)
      ..writeByte(4)
      ..write(obj.classTime)
      ..writeByte(5)
      ..write(obj.location)
      ..writeByte(6)
      ..write(obj.syllabus)
      ..writeByte(7)
      ..write(obj.grading);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
