import 'dart:collection';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/mood_entry.dart';

class MoodStorage {
  static const _boxName = 'mood_entries';

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MoodEntryAdapter());
    }
    await Hive.openBox<MoodEntry>(_boxName);
  }

  Box<MoodEntry> get _box => Hive.box<MoodEntry>(_boxName);

  Future<void> saveEntry(MoodEntry entry) async {
    // Key by date-only to allow one per day; append time if multiple
    final key = entry.date.toIso8601String();
    await _box.put(key, entry);
  }

  Future<List<MoodEntry>> loadEntries() async {
    return _box.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<Map<DateTime, List<MoodEntry>>> entriesByDay() async {
    final map = <DateTime, List<MoodEntry>>{};
    for (final e in _box.values) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      map.putIfAbsent(d, () => []).add(e);
    }
    final ordered = SplayTreeMap<DateTime, List<MoodEntry>>.from(
      map,
      (a, b) => a.compareTo(b),
    );
    return ordered;
  }

  Future<void> clearAll() async => _box.clear();
}
