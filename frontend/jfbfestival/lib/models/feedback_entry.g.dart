// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FeedbackEntryAdapter extends TypeAdapter<FeedbackEntry> {
  @override
  final int typeId = 0;

  @override
  FeedbackEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FeedbackEntry(
      subject: fields[0] as String,
      message: fields[1] as String,
      timestamp: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FeedbackEntry obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.subject)
      ..writeByte(1)
      ..write(obj.message)
      ..writeByte(2)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedbackEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
