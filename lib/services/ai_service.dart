import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

class AIService {
  // Optional: set via --dart-define=AI_ENDPOINT=https://your-api.com
  static const String _endpoint = String.fromEnvironment('AI_ENDPOINT');
  static const String _apiKey = String.fromEnvironment('AI_API_KEY');

  Future<(String mood, List<String> topics)> analyzeMood(String? text) async {
    // Remote mode
    if (_endpoint.isNotEmpty) {
      try {
        final uri = Uri.parse(_endpoint.endsWith('/') ? '${_endpoint}analyze' : '$_endpoint/analyze');
        final res = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            if (_apiKey.isNotEmpty) 'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({'text': text ?? ''}),
        );
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final json = jsonDecode(res.body) as Map<String, dynamic>;
          final mood = (json['mood'] ?? 'Neutral').toString();
          final topics = (json['topics'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
          return (mood, topics);
        }
      } catch (_) {
        // Fall through to mock
      }
    }

    // Mock analyzer
    await Future.delayed(const Duration(milliseconds: 400));
    if (text == null || text.trim().isEmpty) {
      return ('Neutral', const <String>[]);
    }
    final lowered = text.toLowerCase();
    final keywords = <String>['work', 'family', 'friends', 'health', 'study', 'money', 'sleep', 'food'];
    final topics = keywords.where((k) => lowered.contains(k)).toList();

    final positiveWords = ['good', 'great', 'happy', 'love', 'excited', 'proud'];
    final negativeWords = ['bad', 'sad', 'angry', 'tired', 'worried', 'anxious'];

    int score = 0;
    for (final w in positiveWords) {
      if (lowered.contains(w)) score++;
    }
    for (final w in negativeWords) {
      if (lowered.contains(w)) score--;
    }

    String mood;
    if (score >= 2) {
      mood = 'Positive';
    } else if (score <= -2) mood = 'Negative';
    else mood = 'Neutral';

    if (topics.isEmpty) {
      final fallback = ['general', 'routine', 'chores', 'commute'];
      topics.add(fallback[Random().nextInt(fallback.length)]);
    }

    return (mood, topics);
  }

  Future<String> weeklySummary(List<String> dailySummaries) async {
    // Remote mode
    if (_endpoint.isNotEmpty) {
      try {
        final uri = Uri.parse(_endpoint.endsWith('/') ? '${_endpoint}weekly-summary' : '$_endpoint/weekly-summary');
        final res = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            if (_apiKey.isNotEmpty) 'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({'moods': dailySummaries}),
        );
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final json = jsonDecode(res.body) as Map<String, dynamic>;
          return (json['summary'] ?? 'No summary').toString();
        }
      } catch (_) {
        // Fall through to mock
      }
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (dailySummaries.isEmpty) return 'No data for this week yet.';
    final positives = dailySummaries.where((s) => s.toLowerCase().contains('positive')).length;
    final negatives = dailySummaries.where((s) => s.toLowerCase().contains('negative')).length;
    final neutrals = dailySummaries.length - positives - negatives;
    return 'This week had $positives positive, $neutrals neutral, and $negatives negative days.';
  }
}
