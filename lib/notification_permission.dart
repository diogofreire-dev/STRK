import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'notifications_service.dart';
import 'theme_provider.dart';

/// Chamado quando alguém liga o switch de um lembrete. Explica primeiro
/// para que servem as notificações e só depois mostra o pedido do sistema,
/// que no iOS só aparece uma vez na vida da app. Devolve true se o lembrete
/// pode ficar ligado.
Future<bool> ensureNotificationPermission(BuildContext context) async {
  if (kIsWeb) return false;
  final theme = ThemeProviderScope.of(context);

  final status = await NotificationsService.currentStatus();
  final step = NotificationsService.stepFor(status, defaultTargetPlatform);
  if (step == PermissionStep.granted) return true;
  if (!context.mounted) return false;

  if (step == PermissionStep.openSettings) {
    await _showSettingsHint(context, theme);
    return false;
  }

  final wants = await _showExplanation(context, theme);
  if (wants != true) return false;

  final granted = await NotificationsService.requestPermission();
  if (!granted && context.mounted) await _showSettingsHint(context, theme);
  return granted;
}

Future<bool?> _showExplanation(BuildContext context, ThemeProvider theme) =>
    showDialog<bool>(
      context: context,
      builder: (ctx) => _PermissionDialog(
        theme: theme,
        icon: Icons.notifications_active_rounded,
        title: 'Queres que a STRK te lembre?',
        body:
            'Só te avisamos dos hábitos que ainda não fizeste, à hora que '
            'escolheres. Nada de spam.',
        primary: 'Ativar lembretes',
        secondary: 'Agora não',
      ),
    );

Future<void> _showSettingsHint(BuildContext context, ThemeProvider theme) =>
    showDialog<bool>(
      context: context,
      builder: (ctx) => _PermissionDialog(
        theme: theme,
        icon: Icons.notifications_off_rounded,
        title: 'As notificações estão desligadas',
        body:
            'Para receberes lembretes, ativa as notificações da STRK nas '
            'Definições do telemóvel e volta a ligar o lembrete.',
        primary: 'Percebi',
      ),
    );

class _PermissionDialog extends StatelessWidget {
  final ThemeProvider theme;
  final IconData icon;
  final String title;
  final String body;
  final String primary;
  final String? secondary;

  const _PermissionDialog({
    required this.theme,
    required this.icon,
    required this.title,
    required this.body,
    required this.primary,
    this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: theme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 28, color: theme.accent),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: theme.textSecondary,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  primary,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            if (secondary != null)
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  foregroundColor: theme.textSecondary,
                ),
                child: Text(secondary!),
              ),
          ],
        ),
      ),
    );
  }
}
