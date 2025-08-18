import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/mood_entry.dart';
import '../../services/mood_storage.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  List<MoodEntry> selectedEntries = [];

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<MoodStorage>(context, listen: false);

    return FutureBuilder<Map<DateTime, List<MoodEntry>>>(
      future: storage.entriesByDay(),
      builder: (context, snapshot) {
        final events = snapshot.data ?? {};
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TableCalendar<MoodEntry>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: focusedDay,
                selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                eventLoader: (day) => events[DateTime(day.year, day.month, day.day)] ?? [],
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  todayDecoration: BoxDecoration(
                    color: const Color(0xFF86A8E7).withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Color(0xFF7F7FD5),
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(fontWeight: FontWeight.w700),
                ),
                startingDayOfWeek: StartingDayOfWeek.monday,
                onDaySelected: (selected, focused) {
                  setState(() {
                    selectedDay = selected;
                    focusedDay = focused;
                    selectedEntries = events[DateTime(selected.year, selected.month, selected.day)] ?? [];
                  });
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, entries) {
                    if (entries.isEmpty) return const SizedBox.shrink();
                    final avg = _averageMood(entries.cast<MoodEntry>());
                    final emoji = avg >= 0.66 ? '😀' : avg <= 0.33 ? '😢' : '😐';
                    return Center(child: Text(emoji));
                  },
                  defaultBuilder: (context, day, focused) => Center(child: Text('${day.day}')),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (selectedDay != null)
              Expanded(
                child: _DailySummary(entries: selectedEntries),
              ),
          ],
        );
      },
    );
  }

  double _averageMood(List<MoodEntry> entries) {
    double score = 0;
    int count = 0;
    for (final e in entries) {
      for (final emo in e.emojis) {
        if (emo == '😀') score += 1;
        if (emo == '😐') score += 0.5;
        if (emo == '😢') score += 0;
        count++;
      }
    }
    if (count == 0) return 0.5;
    return score / count;
  }
}

class _DailySummary extends StatelessWidget {
  final List<MoodEntry> entries;
  const _DailySummary({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final moods = entries.map((e) => e.aiMood ?? 'Neutral').toList();
    final topics = entries.expand((e) => e.aiTopics ?? const <String>[]).toSet().toList();
    final chips = entries.expand((e) => e.emojis).toList();
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFBD3E9), Color(0xFFBB377D)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI Daily Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: chips.map((e) => Chip(label: Text(e))).toList(),
          ),
          const SizedBox(height: 8),
          Text('Moods: ${moods.join(', ')}', style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 6),
          Text('Topics: ${topics.join(', ')}', style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 12),
          ...entries.where((e) => (e.journal ?? '').isNotEmpty).map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• ${e.journal}', style: const TextStyle(color: Colors.white)),
                ),
              ),
        ],
      ),
    );
  }
}
