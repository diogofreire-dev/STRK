import 'package:flutter/material.dart';
import '../theme_provider.dart';

/// Barra de navegação inferior com os 4 separadores do ecrã principal
/// (Hoje, Calendário, Stats, Perfil).
/// Extraído de `main.dart` (era `_HomeScreenState._buildTabBar` e
/// `_buildTabItem`).
class StrkTabBar extends StatelessWidget {
  final int currentTab;
  final ValueChanged<int> onTabSelected;
  final ThemeProvider theme;

  const StrkTabBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.bg,
        border: Border(top: BorderSide(color: theme.divider, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _tabItem(Icons.grid_view_rounded, 'Hoje', 0),
          _tabItem(Icons.calendar_month_outlined, 'Calendário', 1),
          _tabItem(Icons.bar_chart_rounded, 'Stats', 2),
          _tabItem(Icons.person_outline_rounded, 'Perfil', 3),
        ],
      ),
    );
  }

  Widget _tabItem(IconData icon, String label, int index) {
    final active = currentTab == index;
    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: active
                ? theme.accent
                : theme.textPrimary.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: active
                  ? theme.accent
                  : theme.textPrimary.withValues(alpha: 0.25),
            ),
          ),
        ],
      ),
    );
  }
}
