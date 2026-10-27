import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';

enum PillStyle { accent, light, dark, ghost }

class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = PillStyle.accent,
    this.icon,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final PillStyle style;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, border) = switch (style) {
      PillStyle.accent => (AppColors.accent, Colors.white, null),
      PillStyle.light => (AppColors.surface, AppColors.ink, null),
      PillStyle.dark => (AppColors.ink, Colors.white, null),
      PillStyle.ghost => (const Color(0x26FFFFFF), Colors.white, const BorderSide(color: Color(0x66FFFFFF))),
    };
    final enabled = onPressed != null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.45,
      child: SizedBox(
        width: expand ? double.infinity : null,
        height: 56,
        child: Material(
          color: background,
          shape: StadiumBorder(side: border ?? BorderSide.none),
          elevation: style == PillStyle.light && enabled ? 2 : 0,
          shadowColor: const Color(0x33000000),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20, color: foreground), const SizedBox(width: 8)],
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: foreground, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// White circular icon button with a soft shadow (back buttons, quick actions).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 48,
    this.color = AppColors.surface,
    this.iconColor = AppColors.ink,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color color;
  final Color iconColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = DecoratedBox(
      decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: AppDecorations.softShadow),
      child: Material(
        color: color,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox.square(dimension: size, child: Icon(icon, color: iconColor, size: size * 0.45)),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}

/// Glowing orange orb (the design's lightning button); [pulse] adds breathing halos.
class AccentOrb extends StatefulWidget {
  const AccentOrb({
    super.key,
    required this.onPressed,
    this.icon = Icons.bolt_rounded,
    this.size = 64,
    this.pulse = false,
    this.tooltip,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final double size;
  final bool pulse;
  final String? tooltip;

  @override
  State<AccentOrb> createState() => _AccentOrbState();
}

class _AccentOrbState extends State<AccentOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Created eagerly: a lazy controller first touched in dispose() would
    // create its ticker on a deactivated element.
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    if (widget.pulse) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orb = DecoratedBox(
      decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: AppDecorations.accentGlow),
      child: Material(
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.3, -0.4),
              colors: [AppColors.accentLight, AppColors.accent],
            ),
          ),
          child: InkWell(
            onTap: widget.onPressed,
            child: SizedBox.square(
              dimension: widget.size,
              child: Icon(widget.icon, color: Colors.white, size: widget.size * 0.42),
            ),
          ),
        ),
      ),
    );

    final content = !widget.pulse
        ? orb
        : AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_controller.value);
              return Container(
                padding: EdgeInsets.all(widget.size * (0.22 + 0.06 * t)),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: 0.08 + 0.06 * t),
                ),
                child: Container(
                  padding: EdgeInsets.all(widget.size * 0.14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.14 + 0.08 * t),
                  ),
                  child: child,
                ),
              );
            },
            child: orb,
          );

    return widget.tooltip == null ? content : Tooltip(message: widget.tooltip, child: content);
  }
}
