import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/ai_service.dart';
import '../../services/mood_storage.dart';
import '../../models/mood_entry.dart';

class StatsTab extends StatelessWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<MoodStorage>(context, listen: false);
    final ai = Provider.of<AIService>(context, listen: false);

    return FutureBuilder<List<MoodEntry>>(
      future: storage.loadEntries(),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? [];
        final week = _last7DaysEntries(entries);

        final counts = _moodCounts(week);
        final total = counts.values.fold<int>(0, (a, b) => a + b);
        final pct = total == 0
            ? {'😀': 0.0, '😐': 0.0, '😢': 0.0}
            : counts.map((k, v) => MapEntry(k, v / total));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _WeeklyBar(pct: pct),
            const SizedBox(height: 20),
            FutureBuilder<String>(
              future: ai.weeklySummary(week.map((e) => e.aiMood ?? 'Neutral').toList()),
              builder: (context, snap) => _InsightsCard(
                summary: snap.data ?? 'Gathering insights...',
                topics: _topTopics(week),
                pct: pct,
              ),
            ),
          ],
        );
      },
    );
  }

  List<MoodEntry> _last7DaysEntries(List<MoodEntry> all) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 7));
    return all.where((e) => e.date.isAfter(cutoff)).toList();
  }

  Map<String, int> _moodCounts(List<MoodEntry> entries) {
    final map = {'😀': 0, '😐': 0, '😢': 0};
    for (final e in entries) {
      for (final emo in e.emojis) {
        map[emo] = (map[emo] ?? 0) + 1;
      }
    }
    return map;
  }

  List<String> _topTopics(List<MoodEntry> entries) {
    final count = <String, int>{};
    for (final e in entries) {
      for (final t in e.aiTopics ?? const <String>[]) {
        count[t] = (count[t] ?? 0) + 1;
      }
    }
    final sorted = count.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) => e.key).toList();
  }
}

class _WeeklyBar extends StatelessWidget {
  final Map<String, double> pct;
  const _WeeklyBar({required this.pct});

  @override
  Widget build(BuildContext context) {
    final data = [
      ('😀', pct['😀'] ?? 0, Colors.green),
      ('😐', pct['😐'] ?? 0, Colors.amber),
      ('😢', pct['😢'] ?? 0, Colors.redAccent),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekly Mood Mix', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        final labels = ['😀', '😐', '😢'];
                        if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                        return Text(labels[i], style: const TextStyle(color: Colors.white));
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (int i = 0; i < data.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: data[i].$2 * 100,
                          width: 24,
                          color: data[i].$3,
                          borderRadius: BorderRadius.circular(6),
                          rodStackItems: [
                            BarChartRodStackItem(0, data[i].$2 * 100, data[i].$3.withOpacity(0.8)),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final (label, value, color) in data)
                Column(
                  children: [
                    Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('${(value * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  final String summary;
  final List<String> topics;
  final Map<String, double> pct;
  const _InsightsCard({required this.summary, required this.topics, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF92FE9D), Color(0xFF00C9FF)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI Insights', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(summary, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: topics.isEmpty
                ? [const Chip(label: Text('No topics yet'))]
                : topics.map((t) => Chip(label: Text(t))).toList(),
          ),
        ],
      ),
    );
  }
}
