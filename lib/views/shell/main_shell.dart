import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/navigation_controller.dart';
import '../dashboard/dashboard_view.dart';
import '../profile/profile_view.dart';
import '../reports/reports_view.dart';
import '../tests/test_hub_view.dart';
import 'floating_nav_bar.dart';

/// Bottom padding that keeps tab content clear of the floating nav bar.
const shellBottomInset = 120.0;

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const _items = {
    AppTab.home: NavItem(icon: Icons.donut_large_rounded, label: 'Home'),
    AppTab.progress: NavItem(icon: Icons.insights_rounded, label: 'Progress'),
    AppTab.tests: NavItem(icon: Icons.bolt_rounded, label: 'Train'),
    AppTab.profile: NavItem(icon: Icons.person_rounded, label: 'Profile'),
  };

  @override
  Widget build(BuildContext context) {
    final navigation = context.watch<NavigationController>();

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: navigation.tab.index,
        children: const [DashboardView(), ReportsView(), TestHubView(), ProfileView()],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: FloatingNavBar(
          items: AppTab.values.map((tab) => _items[tab]!).toList(),
          selectedIndex: navigation.tab.index,
          onSelected: (i) => navigation.select(AppTab.values[i]),
        ),
      ),
    );
  }
}
