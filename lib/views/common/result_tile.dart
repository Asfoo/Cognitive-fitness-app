import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/test_result.dart';
import '../results/result_view.dart';
import 'charts.dart';
import 'test_type_style.dart';

/// One session row: icon, name, time, key metric and score ring. Opens the result.
class ResultTile extends StatelessWidget {
  const ResultTile({super.key, required this.result, required this.now});

  final TestResult result;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final metric = result.reactionMs != null
        ? '${Format.ms(result.reactionMs)} ms'
        : result.tapIntervalMs != null
            ? '${Format.ms(result.tapIntervalMs)} ms/tap'
            : '${Format.percent(result.accuracy)}% acc.';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ResultView(result: result, fromHistory: true)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(color: AppColors.well, shape: BoxShape.circle),
              child: Icon(result.type.icon, color: AppColors.ink, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.type.title, style: text.titleMedium, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${result.timestamp.relativeLabel(now)} · $metric', style: text.bodySmall),
                ],
              ),
            ),
            RingProgress(
              value: result.score / 100,
              size: 44,
              strokeWidth: 4,
              color: AppColors.accent,
              child: Text('${result.score}', style: text.labelLarge),
            ),
          ],
        ),
      ),
    );
  }
}
