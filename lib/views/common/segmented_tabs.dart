import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';

/// Daily / Weekly / Monthly style switcher with a sliding white pill.
class SegmentedTabs<T> extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final index = values.indexOf(selected);
    final style = Theme.of(context).textTheme.titleMedium!;

    return Container(
      height: 60,
      padding: const EdgeInsets.all(6),
      decoration: AppDecorations.well(),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment(values.length == 1 ? 0 : -1 + 2 * index / (values.length - 1), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / values.length,
              heightFactor: 1,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
                  boxShadow: AppDecorations.softShadow,
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final value in values)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(value),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: style.copyWith(
                          color: value == selected ? AppColors.ink : AppColors.muted,
                          fontWeight: value == selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        child: Text(labelOf(value)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
