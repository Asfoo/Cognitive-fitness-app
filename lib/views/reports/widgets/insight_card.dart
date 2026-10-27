import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../models/summaries.dart';
import '../../common/buttons.dart';

/// Orange tip card with a floating dark badge, as in the design.
class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.insight, required this.onDismiss, required this.onAction});

  final Insight insight;
  final VoidCallback onDismiss;
  final VoidCallback onAction;

  static const _badgeSize = 72.0;

  @override
  Widget build(BuildContext context) {
    final icon = switch (insight.tone) {
      InsightTone.positive => Icons.trending_up_rounded,
      InsightTone.warning => Icons.priority_high_rounded,
      InsightTone.neutral => Icons.lightbulb_rounded,
    };

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          margin: const EdgeInsets.only(top: _badgeSize / 2),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(AppRadius.lg + 4),
            boxShadow: AppDecorations.accentGlow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg + 4),
            child: CustomPaint(
              painter: _RipplePainter(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, _badgeSize / 2 + 18, 22, 22),
                child: Column(
                  children: [
                    Text(
                      insight.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(child: PillButton(label: 'Dismiss', style: PillStyle.ghost, onPressed: onDismiss)),
                        const SizedBox(width: 12),
                        Expanded(child: PillButton(label: 'Start test', style: PillStyle.light, onPressed: onAction)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          width: _badgeSize + 16,
          height: _badgeSize + 16,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.background,
            border: Border.all(color: AppColors.track),
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.ink,
              boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 6))],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
      ],
    );
  }
}

/// Faint concentric rings in the top-right corner.
class _RipplePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.18);
    final center = Offset(size.width + 10, -10);
    for (var r = 40.0; r <= 100; r += 20) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => false;
}
