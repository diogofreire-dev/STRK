// Pré-visualização do ecrã principal sem Firebase, para ver as animações
// no simulador sem precisar de login:
//   flutter run -t lib/dev/home_preview.dart
import 'package:flutter/material.dart';
import '../habit.dart';
import '../home/celebrations.dart';
import '../home/habit_card.dart';
import '../home/progress_card.dart';
import '../theme_provider.dart';

void main() => runApp(const _PreviewApp());

class _PreviewApp extends StatefulWidget {
  const _PreviewApp();
  @override
  State<_PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<_PreviewApp> {
  final theme = ThemeProvider();
  int confetti = 0;
  final habits = [
    Habit(
      id: '1',
      name: 'Beber água',
      icon: Icons.water_drop_outlined,
      streak: 6,
    ),
    Habit(
      id: '2',
      name: 'Exercício',
      icon: Icons.fitness_center_outlined,
      streak: 12,
      completedToday: true,
    ),
    Habit(id: '3', name: 'Leitura', icon: Icons.menu_book_outlined, streak: 2),
    Habit(id: '4', name: 'Meditação', icon: Icons.self_improvement_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final done = habits.where((h) => h.completedToday).length;
    return ThemeProviderScope(
      provider: theme,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme.themeData,
        home: Scaffold(
          backgroundColor: theme.bg,
          body: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    ProgressCard(
                      theme: theme,
                      completedCount: done,
                      totalCount: habits.length,
                    ),
                    const SizedBox(height: 20),
                    for (final h in habits)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                        child: HabitCard(
                          habit: h,
                          theme: theme,
                          onToggle: () => setState(() {
                            final wasPerfect = done == habits.length;
                            h.toggleCompletion();
                            final nowDone = habits
                                .where((x) => x.completedToday)
                                .length;
                            if (!wasPerfect && nowDone == habits.length) {
                              confetti++;
                            }
                          }),
                          onLongPress: () {},
                          onDismissed: () {},
                        ),
                      ),
                  ],
                ),
              ),
              Positioned.fill(
                child: ConfettiOverlay(
                  trigger: confetti,
                  colors: [
                    theme.accent,
                    const Color(0xFFFFD60A),
                    const Color(0xFFFF375F),
                    const Color(0xFF30D158),
                    const Color(0xFF64D2FF),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
