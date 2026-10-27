import 'package:flutter/material.dart';

import '../../models/test_type.dart';

extension TestTypeStyle on TestType {
  IconData get icon => switch (this) {
        TestType.single => Icons.touch_app_rounded,
        TestType.dual => Icons.calculate_rounded,
        TestType.auditory => Icons.graphic_eq_rounded,
        TestType.visual => Icons.visibility_rounded,
        TestType.tapping => Icons.ads_click_rounded,
      };
}
