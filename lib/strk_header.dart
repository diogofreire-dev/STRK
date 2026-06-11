import 'package:flutter/material.dart';
import 'strk_logo.dart';
import 'theme_provider.dart';

class StrkHeader extends StatelessWidget {
  final Widget? trailing;
  final String? subtitle;

  const StrkHeader({super.key, this.trailing, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProviderScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const StrkLogo(height: 26),
          const SizedBox(width: 10),
          if (subtitle != null)
            Expanded(
              child: Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary.withValues(alpha: 0.35),
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
