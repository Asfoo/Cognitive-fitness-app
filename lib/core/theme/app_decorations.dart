import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppRadius {
  static const sm = 16.0;
  static const md = 24.0;
  static const lg = 32.0;
}

abstract final class AppDecorations {
  /// Floating white card shadow: a soft drop shadow plus a light top-left lift.
  static const softShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 28, offset: Offset(0, 12)),
    BoxShadow(color: Color(0xB3FFFFFF), blurRadius: 10, offset: Offset(-4, -4)),
  ];

  static const accentGlow = [
    BoxShadow(color: Color(0x66E1633F), blurRadius: 24, offset: Offset(0, 10)),
  ];

  static BoxDecoration card({Color color = AppColors.surface, double radius = AppRadius.lg}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: softShadow,
    );
  }

  /// Recessed grey capsule used behind grouped controls.
  static BoxDecoration well({double radius = AppRadius.lg}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.well, AppColors.wellLight],
      ),
      border: Border.all(color: const Color(0x99FFFFFF)),
    );
  }
}
