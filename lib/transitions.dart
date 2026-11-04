import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Transições da STRK num só sítio, para a app inteira se mexer da mesma
/// maneira. Todas respeitam o "reduzir movimento" do sistema.

const _curve = Curves.easeOutCubic;

bool _reduceMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// Abrir uma página: entra a subir um pouco e a ganhar nitidez, e a página
/// de trás recua ligeiramente. No iOS mantemos a transição do sistema, para
/// não perder o gesto de deslizar para trás a partir da margem.
class StrkPageTransitionsBuilder extends PageTransitionsBuilder {
  const StrkPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (_reduceMotion(context)) return child;
    final enter = CurvedAnimation(parent: animation, curve: _curve);
    final behind = CurvedAnimation(parent: secondaryAnimation, curve: _curve);
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.6).animate(behind),
      child: ScaleTransition(
        scale: Tween(begin: 1.0, end: 0.96).animate(behind),
        child: FadeTransition(
          opacity: enter,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(enter),
            child: child,
          ),
        ),
      ),
    );
  }
}

const strkPageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: StrkPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.macOS: StrkPageTransitionsBuilder(),
    TargetPlatform.windows: StrkPageTransitionsBuilder(),
    TargetPlatform.linux: StrkPageTransitionsBuilder(),
  },
);

/// Ecrãs "de criar" (novo hábito): sobem do fundo como uma folha, que é o
/// gesto que se associa a "algo novo por cima do que estava".
Route<T> sheetRoute<T>(Widget page) => PageRouteBuilder<T>(
  fullscreenDialog: true,
  transitionDuration: const Duration(milliseconds: 420),
  reverseTransitionDuration: const Duration(milliseconds: 280),
  pageBuilder: (_, _, _) => page,
  transitionsBuilder: (context, animation, _, child) {
    if (_reduceMotion(context)) return child;
    final a = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutQuart,
      reverseCurve: Curves.easeInCubic,
    );
    return SlideTransition(
      position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(a),
      child: child,
    );
  },
);

/// Troca de separador: o antigo desvanece e o novo entra do lado para onde
/// se andou (da direita se o separador está à direita).
class DirectionalTabSwitcher extends StatefulWidget {
  final int index;
  final Widget child;
  const DirectionalTabSwitcher({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  State<DirectionalTabSwitcher> createState() => _DirectionalTabSwitcherState();
}

class _DirectionalTabSwitcherState extends State<DirectionalTabSwitcher> {
  double _direction = 1;

  @override
  void didUpdateWidget(DirectionalTabSwitcher old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      _direction = widget.index > old.index ? 1 : -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: _reduceMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 320),
      switchInCurve: _curve,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      // "Fade through": a página antiga desaparece por completo nos
      // primeiros 40% do tempo e só depois entra a nova. Com um crossfade
      // simples as duas ficavam visíveis ao mesmo tempo (títulos e cartões
      // por cima uns dos outros).
      transitionBuilder: (child, animation) {
        final incoming = child.key == ValueKey(widget.index);
        // A antiga corre de 1 para 0: com Interval(0.6, 1) chega a 0 quando
        // o valor passa 0.6, ou seja, nos primeiros 40% da transição.
        final opacity = CurvedAnimation(
          parent: animation,
          curve: incoming
              ? const Interval(0.4, 1, curve: Curves.easeOut)
              : const Interval(0.6, 1, curve: Curves.easeIn),
        );
        final dx = incoming ? 0.06 * _direction : 0.0;
        return FadeTransition(
          opacity: opacity,
          child: SlideTransition(
            position: Tween(
              begin: Offset(dx, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: _curve)),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey(widget.index), child: widget.child),
    );
  }
}

/// Faz um item entrar a subir e a aparecer, com um atraso proporcional à
/// posição na lista: os cartões chegam em cascata em vez de todos de uma
/// vez. Só anima na primeira vez que o item é construído.
class StaggeredEntrance extends StatefulWidget {
  final int index;
  final Widget child;
  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.isCompleted) return;
    if (_reduceMotion(context)) {
      _c.value = 1;
      return;
    }
    // A partir do 8.º item já ninguém repara no atraso; não vale a pena
    // fazer a pessoa esperar.
    final delay = Duration(milliseconds: 45 * widget.index.clamp(0, 8));
    Future.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = CurvedAnimation(parent: _c, curve: _curve);
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.25),
          end: Offset.zero,
        ).animate(a),
        child: widget.child,
      ),
    );
  }
}
