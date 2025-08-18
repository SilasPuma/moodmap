import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart';

class LottieMood extends StatelessWidget {
  final String mood; // Positive / Neutral / Negative
  const LottieMood({super.key, required this.mood});

  @override
  Widget build(BuildContext context) {
    final asset = switch (mood.toLowerCase()) {
      'positive' => 'assets/lottie/happy.json',
      'negative' => 'assets/lottie/sad.json',
      _ => 'assets/lottie/neutral.json',
    };
    return Lottie.asset(asset, height: 80, repeat: true);
  }
}
