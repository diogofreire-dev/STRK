import 'package:flutter/material.dart';
import '../onboarding_service.dart';
import '../mascot.dart';
import '../theme_provider.dart';

/// Diálogo de boas-vindas mostrado na primeira utilização da app.
/// Extraído de `main.dart` (era `_HomeScreenState._showOnboardingDialog` e
/// `_buildOnboardingTip`).
Future<void> showOnboardingDialog(BuildContext context) async {
  final theme = ThemeProviderScope.of(context);
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      backgroundColor: theme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      title: Column(
        children: [
          const StrkMascot(mood: MascotMood.festa, size: 110),
          const SizedBox(height: 8),
          Text(
            'Bem-vindo ao STRK',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Eu sou a chama dos teus hábitos. Cada dia que cumpres, cresço um bocadinho.',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          _onboardingTip('Marca um hábito e vê o teu streak crescer.', theme),
          const SizedBox(height: 8),
          _onboardingTip('Volta todos os dias para manter o ritmo.', theme),
          const SizedBox(height: 8),
          _onboardingTip(
            'Usa o calendário para acompanhar o teu progresso.',
            theme,
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              await OnboardingService.completeOnboarding();
              if (context.mounted) Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Começar'),
          ),
        ),
      ],
    ),
  );
}

Widget _onboardingTip(String text, ThemeProvider theme) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.check_circle_rounded, color: theme.accent, size: 18),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: TextStyle(color: theme.textPrimary, fontSize: 13, height: 1.4),
        ),
      ),
    ],
  );
}
