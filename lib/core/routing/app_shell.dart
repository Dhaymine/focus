import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../localization/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';

class _Dest {
  const _Dest(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onSelect(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = Responsive.of(context);

    final destinations = [
      _Dest(Icons.home_outlined, Icons.home_rounded, l10n.navHome),
      _Dest(Icons.timer_outlined, Icons.timer_rounded, l10n.navFocus),
      _Dest(Icons.check_circle_outline, Icons.check_circle_rounded,
          l10n.navTasks),
      _Dest(Icons.event_outlined, Icons.event_rounded, l10n.navCountdown),
      _Dest(Icons.bar_chart_outlined, Icons.bar_chart_rounded,
          l10n.navStatistics),
    ];

    final settingsButton = IconButton(
      icon: const Icon(Icons.settings_outlined),
      tooltip: l10n.settings,
      onPressed: () => context.push('/settings'),
    );

    if (size == ScreenSize.compact) {
      return Scaffold(
        appBar: AppBar(
          title: Text(destinations[navigationShell.currentIndex].label),
          actions: [settingsButton],
        ),
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onSelect,
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      );
    }

    final extended = size == ScreenSize.expanded;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onSelect,
            extended: extended,
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.white),
              ),
            ),
            trailing: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: settingsButton,
            ),
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
