import 'package:flutter/material.dart';

import '../../models/test_type.dart';
import 'auditory_test_view.dart';
import 'reaction_test_view.dart';
import 'tapping_test_view.dart';
import 'visual_test_view.dart';

abstract final class TestRoutes {
  static Widget viewFor(TestType type) => switch (type) {
        TestType.single || TestType.dual => ReactionTestView(type: type),
        TestType.auditory => const AuditoryTestView(),
        TestType.visual => const VisualTestView(),
        TestType.tapping => const TappingTestView(),
      };

  static Future<void> open(BuildContext context, TestType type) {
    return Navigator.of(context).push(MaterialPageRoute(builder: (_) => viewFor(type)));
  }

  static Future<void> replaceWith(BuildContext context, TestType type) {
    return Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => viewFor(type)));
  }
}
