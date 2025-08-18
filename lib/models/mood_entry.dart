import 'package:hive/hive.dart';

class MoodEntry extends HiveObject {
  final DateTime date; // Stores full timestamp
  final List<String> emojis; // e.g. ["😀", "😐", "😢"]
  final String? journal;
  final String? aiMood; // e.g. "Positive"
  final List<String>? aiTopics; // e.g. ["work", "health"]

  MoodEntry({
    required this.date,
    required this.emojis,
    this.journal,
    this.aiMood,
    this.aiTopics,
  });
}

class MoodEntryAdapter extends TypeAdapter<MoodEntry> {
  @override
  final int typeId = 0;

  @override
  MoodEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return MoodEntry(
      date: fields[0] as DateTime,
      emojis: (fields[1] as List).cast<String>(),
      journal: fields[2] as String?,
      aiMood: fields[3] as String?,
      aiTopics: (fields[4] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, MoodEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.emojis)
      ..writeByte(2)
      ..write(obj.journal)
      ..writeByte(3)
      ..write(obj.aiMood)
      ..writeByte(4)
      ..write(obj.aiTopics);
  }
}
