import 'package:flutter/foundation.dart';

enum AppTab { home, progress, tests, profile }

class NavigationController extends ChangeNotifier {
  AppTab _tab = AppTab.home;

  AppTab get tab => _tab;

  void select(AppTab tab) {
    if (tab == _tab) return;
    _tab = tab;
    notifyListeners();
  }
}
