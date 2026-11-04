import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../habit.dart';
import '../../theme_provider.dart';
import '../tappable.dart';

/// Cartão de um hábito na lista do ecrã principal.
///
/// Tocar marca/desmarca, manter premido edita e deslizar para a esquerda
/// apaga. As ações vêm por callback; o cartão só trata da parte visual:
/// encolher ao carregar, o visto a "saltar" e o streak a subir.
class HabitCard extends StatefulWidget {
  final Habit habit;
  final ThemeProvider theme;
  final VoidCallback onToggle;
  final VoidCallback onLongPress;
  final VoidCallback onDismissed;

  const HabitCard({
    super.key,
    required this.habit,
    required this.theme,
    required this.onToggle,
    required this.onLongPress,
    required this.onDismissed,
  });

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  // O Habit é mutável (o mesmo objeto muda por dentro), por isso guardamos
  // o estado anterior à mão para saber quando passou a concluído.
  late bool _wasCompleted = widget.habit.completedToday;

  // Anima o "salto" do visto e da chama quando o hábito é concluído.
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
    value: 1,
  );

  @override
  void didUpdateWidget(HabitCard old) {
    super.didUpdateWidget(old);
    if (widget.habit.completedToday && !_wasCompleted) _pop.forward(from: 0);
    _wasCompleted = widget.habit.completedToday;
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Vibração diferente para marcar e desmarcar: dá para sentir sem olhar.
    widget.habit.completedToday
        ? HapticFeedback.selectionClick()
        : HapticFeedback.mediumImpact();
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    final theme = widget.theme;
    final done = habit.completedToday;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    // Escala com "mola": passa um pouco de 1 e volta, como um botão físico.
    final Animation<double> popScale = reduceMotion
        ? const AlwaysStoppedAnimation(1.0)
        : TweenSequence([
            TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.25), weight: 40),
            TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 60),
          ]).animate(CurvedAnimation(parent: _pop, curve: Curves.easeOut));

    return Dismissible(
      key: Key(habit.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0x26FF3B30),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Color(0xFFFF3B30),
          size: 22,
        ),
      ),
      child: Semantics(
        button: true,
        toggled: done,
        label: habit.streak == 1
            ? '${habit.name}, 1 dia seguido'
            : '${habit.name}, ${habit.streak} dias seguidos',
        hint: 'Toca para marcar, mantém premido para editar',
        // O excludeSemantics esconde também as ações do GestureDetector,
        // por isso declaramo-las aqui para o leitor de ecrã as poder usar.
        excludeSemantics: true,
        onTap: _handleTap,
        onLongPress: widget.onLongPress,
        child: Tappable(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: _handleTap,
          onLongPress: () {
            HapticFeedback.heavyImpact();
            widget.onLongPress();
          },
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                // Concluído: o cartão ganha um leve tom da cor de destaque.
                color: done
                    ? Color.alphaBlend(
                        theme.accent.withValues(alpha: 0.08),
                        theme.surface,
                      )
                    : theme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: done
                      ? theme.accent.withValues(alpha: 0.35)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: done
                          ? theme.accent.withValues(alpha: 0.15)
                          : theme.isLight
                          ? theme.accent.withValues(alpha: 0.06)
                          : theme.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      habit.icon,
                      size: 18,
                      color: done
                          ? theme.accent
                          : theme.textPrimary.withValues(alpha: 0.25),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: done
                                ? theme.textPrimary
                                : theme.textPrimary.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        _StreakLine(
                          streak: habit.streak,
                          done: done,
                          theme: theme,
                          pop: popScale,
                        ),
                      ],
                    ),
                  ),
                  ScaleTransition(
                    scale: popScale,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: done ? theme.accent : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: done
                              ? theme.accent
                              : theme.textPrimary.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                        boxShadow: done
                            ? [
                                BoxShadow(
                                  color: theme.accent.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                      child: done
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chama + "12 dias seguidos", com o número a deslizar quando muda.
class _StreakLine extends StatelessWidget {
  final int streak;
  final bool done;
  final ThemeProvider theme;
  final Animation<double> pop;

  const _StreakLine({
    required this.streak,
    required this.done,
    required this.theme,
    required this.pop,
  });

  @override
  Widget build(BuildContext context) {
    final muted = theme.textPrimary.withValues(alpha: 0.3);
    return Row(
      children: [
        if (streak > 0) ...[
          ScaleTransition(
            scale: pop,
            // Sem estar feito hoje, a chama fica "apagada" (cinzenta).
            child: Icon(
              Icons.local_fire_department_rounded,
              size: 13,
              color: done ? theme.accent : muted,
            ),
          ),
          const SizedBox(width: 2),
        ],
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.6),
              end: Offset.zero,
            ).animate(anim),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: Text(
            dias(streak),
            key: ValueKey(streak),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: done ? theme.accent : muted,
            ),
          ),
        ),
        Text(
          streak == 1 ? ' seguido' : ' seguidos',
          style: TextStyle(fontSize: 11, color: muted),
        ),
      ],
    );
  }
}
