import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Cabeçalho partilhado com logo STRK para todos os ecrãs.
///
/// Uso básico (só logo):
///   StrkHeader()
///
/// Com avatar à direita:
///   StrkHeader(trailing: CircleAvatar(...))
///
/// Com subtítulo (saudação/título de página):
///   StrkHeader(subtitle: 'Bom dia, Diogo 👋')
class StrkHeader extends StatelessWidget {
  /// Widget opcional no lado direito (ex.: avatar, botão de ícone).
  final Widget? trailing;

  /// Texto opcional abaixo da logo.
  final String? subtitle;

  const StrkHeader({super.key, this.trailing, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Logo ────────────────────────────────────────────────────────
          SvgPicture.asset('assets/images/strk_logo.svg', height: 26),
          const SizedBox(width: 10),
          if (subtitle != null) ...[
            Expanded(
              child: Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0x55FFFFFF),
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
