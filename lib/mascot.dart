import 'dart:math';
import 'package:flutter/material.dart';
import 'theme_provider.dart';

/// Os estados da mascote. Cada um é uma pose renderizada no Blender
/// (`design/mascote.blend`) e exportada para `assets/mascot/`.
enum MascotMood {
  /// Cinza fria, olhos fechados: ainda não fizeste nada hoje.
  apagada,

  /// O dia normal.
  feliz,

  /// Dia perfeito.
  festa,

  /// À espera (ecrãs de carregamento).
  pensar;

  String get asset => 'assets/mascot/$name.png';

  /// Estado da mascote conforme o progresso do dia.
  static MascotMood forProgress(int done, int total) {
    if (total == 0) return feliz;
    if (done == 0) return apagada;
    if (done == total) return festa;
    return feliz;
  }
}

/// A chama da STRK. Está sempre a "respirar" (oscila e estica um pouco,
/// como uma chama a sério) e, quando o estado muda, troca de pose com um
/// pequeno salto. Na festa salta mais e mais depressa.
class StrkMascot extends StatefulWidget {
  final MascotMood mood;
  final double size;
  final String? semanticLabel;

  const StrkMascot({
    super.key,
    required this.mood,
    this.size = 96,
    this.semanticLabel,
  });

  /// Carrega as quatro poses em memória para não piscarem na primeira troca.
  static Future<void> precache(BuildContext context) => Future.wait([
    for (final m in MascotMood.values)
      precacheImage(AssetImage(m.asset), context),
  ]);

  @override
  State<StrkMascot> createState() => _StrkMascotState();
}

class _StrkMascotState extends State<StrkMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Com "reduzir movimento" ligado, a mascote fica parada.
    if (MediaQuery.of(context).disableAnimations) {
      _breath.stop();
    } else if (!_breath.isAnimating) {
      _breath.repeat();
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final party = widget.mood == MascotMood.festa;
    final asleep = widget.mood == MascotMood.apagada;

    final image = Image.asset(
      widget.mood.asset,
      key: ValueKey(widget.mood),
      width: widget.size,
      height: widget.size,
      // Sem isto, o Flutter descodifica a imagem a 512px mesmo para 60px.
      cacheWidth: (widget.size * MediaQuery.of(context).devicePixelRatio)
          .round(),
      gaplessPlayback: true,
    );

    return Semantics(
      image: true,
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _breath,
          builder: (context, child) {
            final t = _breath.value * 2 * pi;
            // A festa respira ao dobro da velocidade e salta; a apagada
            // mexe-se muito pouco, como quem dorme.
            final speed = party ? 2.0 : 1.0;
            final amp = asleep ? 0.4 : (party ? 1.6 : 1.0);
            final stretch = 1 + 0.035 * amp * sin(t * speed);
            final sway = 0.035 * amp * sin(t * speed * 0.5);
            final hop = party
                ? -widget.size * 0.06 * sin(t * speed).abs()
                : 0.0;
            return Transform.translate(
              offset: Offset(0, hop),
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..rotateZ(sway)
                  ..scaleByDouble(1 / sqrt(stretch), stretch, 1, 1),
                child: child,
              ),
            );
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.elasticOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: Tween(begin: 0.7, end: 1.0).animate(anim),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: image,
          ),
        ),
      ),
    );
  }
}

/// Ecrã de carregamento com a mascote a pensar, em vez da roda genérica.
class MascotLoader extends StatelessWidget {
  final String message;
  final double size;
  const MascotLoader({super.key, this.message = 'A acender…', this.size = 110});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProviderScope.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StrkMascot(mood: MascotMood.pensar, size: size),
          const SizedBox(height: 14),
          Text(
            message,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
