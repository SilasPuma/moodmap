import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/mood_entry.dart';
import '../../services/ai_service.dart';
import '../../services/mood_storage.dart';
import '../widgets/mood_button.dart';

class LogTab extends StatefulWidget {
  const LogTab({super.key});

  @override
  State<LogTab> createState() => _LogTabState();
}

class _LogTabState extends State<LogTab> {
  final emojis = ['😀', '😐', '😢'];
  final selected = <int>{};
  final controller = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ai = Provider.of<AIService>(context, listen: false);
    final storage = Provider.of<MoodStorage>(context, listen: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('How are you today?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Tap one or more that fit', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
          const SizedBox(height: 14),
          Center(
            child: SizedBox(
              height: 68,
              child: ListView.separated(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemBuilder: (c, i) {
                  final isSel = selected.contains(i);
                  return MoodButton(
                    emoji: emojis[i],
                    selected: isSel,
                    onTap: () {
                      setState(() {
                        if (isSel) {
                          selected.remove(i);
                        } else {
                          selected.add(i);
                        }
                      });
                    },
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 22),
                itemCount: emojis.length,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFAFFD1), Color(0xFFA1FFCE)]),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add a short journal (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'How are you feeling today?',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedTextKit(
                  repeatForever: true,
                  pause: const Duration(milliseconds: 1200),
                  animatedTexts: [
                    FadeAnimatedText('Tip: Mention topics like work, family, or sleep.'),
                    FadeAnimatedText('Your notes help AI generate insights.'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: const Color(0xFF7F7FD5),
                foregroundColor: Colors.white,
              ).copyWith(
                backgroundColor: const MaterialStatePropertyAll(Colors.transparent),
                shadowColor: const MaterialStatePropertyAll(Colors.transparent),
                elevation: const MaterialStatePropertyAll(0),
              ),
              onPressed: loading
                  ? null
                  : () async {
                      if (selected.isEmpty && controller.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick a mood or write a note.')));
                        return;
                      }
                      setState(() => loading = true);
                      try {
                        final emojisPicked = selected.map((i) => emojis[i]).toList();
                        final analysis = await ai.analyzeMood(controller.text);
                        final entry = MoodEntry(
                          date: DateTime.now(),
                          emojis: emojisPicked,
                          journal: controller.text.trim().isEmpty ? null : controller.text.trim(),
                          aiMood: analysis.$1,
                          aiTopics: analysis.$2,
                        );
                        await storage.saveEntry(entry);
                        controller.clear();
                        setState(() => selected.clear());
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved!')));
                        }
                      } finally {
                        if (mounted) setState(() => loading = false);
                      }
                    },
              child: Ink(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF7F7FD5), Color(0xFF86A8E7), Color(0xFF91EAE4)]),
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 160, minHeight: 48),
                  alignment: Alignment.center,
                  child: loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Today', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
