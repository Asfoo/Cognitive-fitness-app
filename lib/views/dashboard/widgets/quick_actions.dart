import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../common/buttons.dart';
import '../../common/surfaces.dart';

class QuickAction {
  const QuickAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// Row of tall grey capsules, each with a white icon button and a label.
class QuickActions extends StatelessWidget {
  const QuickActions({super.key, required this.actions});

  final List<QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, action) in actions.indexed) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: SoftWell(
              radius: 40,
              padding: const EdgeInsets.fromLTRB(6, 10, 6, 16),
              child: Column(
                children: [
                  CircleIconButton(icon: action.icon, size: 60, onPressed: action.onTap, tooltip: action.label),
                  const SizedBox(height: 12),
                  Text(
                    action.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
