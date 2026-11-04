import 'package:flutter/material.dart';

/// Um GestureDetector que, quando tem uma ação, mostra a mão do rato ao
/// passar por cima. Na web, sem isto, nada na STRK parecia clicável (os
/// GestureDetector mostram sempre a seta normal).
class Tappable extends StatelessWidget {
  final Widget? child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCancelCallback? onTapCancel;
  final HitTestBehavior? behavior;

  const Tappable({
    super.key,
    this.child,
    this.onTap,
    this.onLongPress,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.behavior,
  });

  @override
  Widget build(BuildContext context) {
    final clickable = onTap != null || onLongPress != null;
    return MouseRegion(
      cursor: clickable ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        onTapDown: onTapDown,
        onTapUp: onTapUp,
        onTapCancel: onTapCancel,
        behavior: behavior,
        child: child,
      ),
    );
  }
}
