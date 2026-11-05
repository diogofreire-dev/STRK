import 'dart:math';
import 'package:flutter/material.dart';
import 'theme_provider.dart';

/// Num ecrã largo (computador, tablet deitado) a STRK vive numa coluna
/// centrada em vez de esticar campos e botões até às bordas da janela.
/// À volta fica o fundo da app com um brilho suave da cor do tema.
class WebFrame extends StatelessWidget {
  final Widget child;
  const WebFrame({super.key, required this.child});

  /// A partir desta largura a coluna deixa de ocupar o ecrã todo.
  static const breakpoint = 700.0;
  static const columnWidth = 480.0;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width < breakpoint) return child;

    final theme = ThemeProviderScope.of(context);
    final width = min(columnWidth, media.size.width);
    return ColoredBox(
      color: theme.bg,
      child: Stack(
        children: [
          // Brilho atrás da coluna, como a chama a iluminar a página.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.35),
                  radius: 1.1,
                  colors: [
                    theme.accent.withValues(alpha: theme.isLight ? 0.10 : 0.14),
                    theme.bg.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: width,
              // A borda vai por cima (foregroundDecoration) para não roubar
              // espaço: a app tem exatamente a largura que o MediaQuery diz.
              foregroundDecoration: BoxDecoration(
                border: Border.symmetric(
                  vertical: BorderSide(color: theme.cardBorder),
                ),
              ),
              decoration: BoxDecoration(
                color: theme.bg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 40,
                  ),
                ],
              ),
              // Os widgets que se medem pelo ecrã passam a ver a coluna.
              child: MediaQuery(
                data: media.copyWith(size: Size(width, media.size.height)),
                child: ClipRect(child: child),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
