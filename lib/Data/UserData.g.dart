// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'UserData.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserDataAdapter extends TypeAdapter<UserData> {
  @override
  final int typeId = 0;

  @override
  UserData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserData()
      ..id = fields[0] as String
      ..name = fields[1] as String
      ..chinese_name = fields[2] as String
      ..gpa = fields[3] as double
      ..credits = fields[4] as int
      ..withdrawals = fields[5] as int
      ..passed = fields[6] as int
      ..semester = fields[7] as int
      ..profile = fields[8] as String?
      ..coursestaken = (fields[9] as List)
          .map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList();
  }

  @override
  void write(BinaryWriter writer, UserData obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.chinese_name)
      ..writeByte(3)
      ..write(obj.gpa)
      ..writeByte(4)
      ..write(obj.credits)
      ..writeByte(5)
      ..write(obj.withdrawals)
      ..writeByte(6)
      ..write(obj.passed)
      ..writeByte(7)
      ..write(obj.semester)
      ..writeByte(8)
      ..write(obj.rank)
      ..writeByte(9)
      ..write(obj.preferences)
      ..writeByte(10)
      ..write(obj.selectedData)
      ..writeByte(11)
      ..write(obj.profile)
      ..writeByte(12)
      ..write(obj.coursestaken)
      ..writeByte(13)
      ..write(obj.recommended)
      ..writeByte(14)
      ..write(obj.usedslot);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
