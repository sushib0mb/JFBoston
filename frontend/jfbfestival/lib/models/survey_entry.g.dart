// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'survey_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SurveyEntryAdapter extends TypeAdapter<SurveyEntry> {
  @override
  final int typeId = 1;

  @override
  SurveyEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SurveyEntry(
      timestamp: fields[0] as DateTime,
      usabilityRating: fields[1] as int,
      featureRating: fields[2] as int,
      comments: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SurveyEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.usabilityRating)
      ..writeByte(2)
      ..write(obj.featureRating)
      ..writeByte(3)
      ..write(obj.comments);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurveyEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
