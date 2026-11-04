import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme_provider.dart';

/// Barra de navegação inferior com os 4 separadores do ecrã principal
/// (Hoje, Calendário, Stats, Perfil). Um traço na cor do tema desliza até
/// ao separador ativo, e o ícone ativo cresce um pouco.
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

  static const _items = [
    (Icons.grid_view_rounded, 'Hoje'),
    (Icons.calendar_month_outlined, 'Calendário'),
    (Icons.bar_chart_rounded, 'Stats'),
    (Icons.person_outline_rounded, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    final duration = reduce ? Duration.zero : const Duration(milliseconds: 380);
    return Container(
      decoration: BoxDecoration(
        color: theme.bg,
        border: Border(top: BorderSide(color: theme.divider, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final slot = constraints.maxWidth / _items.length;
            const indicator = 28.0;
            return Stack(
              children: [
                // O traço passa um pouco do sítio e volta (easeOutBack),
                // como se tivesse sido atirado.
                AnimatedPositioned(
                  duration: duration,
                  curve: Curves.easeOutBack,
                  top: 0,
                  left: slot * currentTab + (slot - indicator) / 2,
                  width: indicator,
                  height: 3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.accent,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(3),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      for (var i = 0; i < _items.length; i++)
                        Expanded(child: _tabItem(i, duration)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _tabItem(int index, Duration duration) {
    final (icon, label) = _items[index];
    final active = currentTab == index;
    final color = active
        ? theme.accent
        : theme.textPrimary.withValues(alpha: 0.25);
    return Semantics(
      button: true,
      selected: active,
      label: label,
      excludeSemantics: true,
      onTap: () => onTabSelected(index),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (active) return;
          HapticFeedback.selectionClick();
          onTabSelected(index);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: active ? 1.15 : 1,
              duration: duration,
              curve: Curves.easeOutBack,
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: duration,
              style: TextStyle(
                fontSize: 9,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
