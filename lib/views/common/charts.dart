import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

const _chartAnimation = Duration(milliseconds: 900);

/// Circular progress ring that animates to [value] (0–1).
class RingProgress extends StatelessWidget {
  const RingProgress({
    super.key,
    required this.value,
    this.size = 64,
    this.strokeWidth = 7,
    this.color = AppColors.ink,
    this.trackColor = AppColors.track,
    this.child,
  });

  final double value;
  final double size;
  final double strokeWidth;
  final Color color;
  final Color trackColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: _chartAnimation,
      curve: Curves.easeOutCubic,
      builder: (context, animated, child) => CustomPaint(
        size: Size.square(size),
        painter: _ArcPainter(
          arcs: [_Arc(animated, color, strokeWidth, 0)],
          trackColor: trackColor,
          startAngle: -math.pi / 2,
          sweep: 2 * math.pi,
        ),
        child: SizedBox.square(dimension: size, child: Center(child: child)),
      ),
      child: child,
    );
  }
}

/// Two concentric semicircular gauges (outer accent, inner ink).
class DualArcGauge extends StatelessWidget {
  const DualArcGauge({super.key, required this.outer, required this.inner, this.strokeWidth = 14});

  final double outer;
  final double inner;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: _chartAnimation,
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => CustomPaint(
        painter: _ArcPainter(
          arcs: [
            _Arc(outer.clamp(0.0, 1.0) * t, AppColors.accent, strokeWidth, 0, gradientTo: AppColors.accentLight),
            _Arc(inner.clamp(0.0, 1.0) * t, AppColors.ink, strokeWidth, strokeWidth * 1.6),
          ],
          trackColor: AppColors.track,
          startAngle: math.pi,
          sweep: math.pi,
          anchorBottom: true,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _Arc {
  const _Arc(this.value, this.color, this.width, this.inset, {this.gradientTo});

  final double value;
  final Color color;
  final double width;
  final double inset;
  final Color? gradientTo;
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.arcs,
    required this.trackColor,
    required this.startAngle,
    required this.sweep,
    this.anchorBottom = false,
  });

  final List<_Arc> arcs;
  final Color trackColor;
  final double startAngle;
  final double sweep;

  /// Semicircle sitting on the bottom edge instead of a centred circle.
  final bool anchorBottom;

  @override
  void paint(Canvas canvas, Size size) {
    final maxWidth = arcs.map((a) => a.width).reduce(math.max);
    final radius = anchorBottom
        ? math.min(size.width / 2, size.height) - maxWidth / 2
        : math.min(size.width, size.height) / 2 - maxWidth / 2;
    final center = anchorBottom ? Offset(size.width / 2, size.height - maxWidth / 2) : size.center(Offset.zero);

    for (final arc in arcs) {
      final rect = Rect.fromCircle(center: center, radius: radius - arc.inset);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = arc.width
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweep, false, paint..color = trackColor);
      if (arc.value <= 0) continue;
      if (arc.gradientTo != null) {
        paint.shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweep,
          colors: [arc.color, arc.gradientTo!],
        ).createShader(rect);
      } else {
        paint.color = arc.color;
      }
      canvas.drawArc(rect, startAngle, sweep * arc.value, false, paint);
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => true;
}

/// Thin vertical bars on grey tracks; non-null values are drawn in ink.
class MiniBarChart extends StatelessWidget {
  const MiniBarChart({super.key, required this.values, this.height = 96, this.color = AppColors.ink});

  final List<double?> values;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: _chartAnimation,
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => CustomPaint(
        size: Size(double.infinity, height),
        painter: _BarsPainter(values, color, t),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.values, this.color, this.progress);

  final List<double?> values;
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxValue = values.whereType<double>().fold<double>(0, math.max);
    final slot = size.width / values.length;
    final barWidth = math.min(6.0, slot * 0.45);
    final track = Paint()
      ..color = AppColors.track.withValues(alpha: 0.6)
      ..strokeWidth = barWidth
      ..strokeCap = StrokeCap.round;
    final bar = Paint()
      ..color = color
      ..strokeWidth = barWidth
      ..strokeCap = StrokeCap.round;
    final inset = barWidth / 2;

    for (var i = 0; i < values.length; i++) {
      final x = slot * i + slot / 2;
      canvas.drawLine(Offset(x, inset), Offset(x, size.height - inset), track);
      final value = values[i];
      if (value == null || maxValue == 0) continue;
      final barHeight = (size.height - barWidth) * (0.25 + 0.75 * value / maxValue) * progress;
      canvas.drawLine(Offset(x, size.height - inset), Offset(x, size.height - inset - barHeight), bar);
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.values != values || old.progress != progress;
}

/// Smooth accent line through the non-null points, drawn left to right.
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values, this.height = 96});

  final List<double?> values;
  final double height;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: _chartAnimation,
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => CustomPaint(
        size: Size(double.infinity, height),
        painter: _SparklinePainter(values, t),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.values, this.progress);

  final List<double?> values;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[];
    final present = values.whereType<double>();
    if (present.length < 2) {
      _drawBaseline(canvas, size);
      return;
    }
    final minV = present.reduce(math.min);
    final maxV = present.reduce(math.max);
    final span = maxV - minV == 0 ? 1 : maxV - minV;
    const pad = 6.0;
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v == null) continue;
      final x = pad + (size.width - 2 * pad) * i / (values.length - 1);
      final y = size.height - pad - (size.height - 2 * pad) * (v - minV) / span;
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final cur = points[i];
      final midX = (prev.dx + cur.dx) / 2;
      path.cubicTo(midX, prev.dy, midX, cur.dy, cur.dx, cur.dy);
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(points.last, 5, Paint()..color = AppColors.accent);
    canvas.drawCircle(points.last, 2.5, Paint()..color = Colors.white);
    canvas.restore();
  }

  void _drawBaseline(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.track
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(6, size.height / 2), Offset(size.width - 6, size.height / 2), paint);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.values != values || old.progress != progress;
}

/// Horizontal comparison bar (value relative to [max]).
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.color = AppColors.ink, this.height = 8});

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: AppColors.track)),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
              duration: _chartAnimation,
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => FractionallySizedBox(
                widthFactor: v,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(height)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
