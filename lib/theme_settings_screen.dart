import 'package:flutter/material.dart';
import 'theme_provider.dart';
import 'strk_header.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  static const _presets = [
    Color(0xFFFF6B00),
    Color(0xFFFF375F),
    Color(0xFFBF5AF2),
    Color(0xFF5E5CE6),
    Color(0xFF64D2FF),
    Color(0xFF30D158),
    Color(0xFFFFD60A),
    Color(0xFFFF9F0A),
    Color(0xFFAC8E68),
    Color(0xFFFF6961),
    Color(0xFF77DD77),
    Color(0xFFAEC6CF),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProviderScope.of(context);
    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            StrkHeader(
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: theme.textSecondary,
                  size: 20,
                ),
              ),
              trailing: Text(
                'Aparência',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: theme,
                builder: (context, _) => SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('TEMA', theme),
                      const SizedBox(height: 12),
                      _buildThemeSelector(theme),
                      const SizedBox(height: 32),
                      if (theme.mode == StrkThemeMode.custom) ...[
                        _label('FUNDO', theme),
                        const SizedBox(height: 12),
                        _buildBgSelector(theme),
                        const SizedBox(height: 32),
                        _label('COR DE DESTAQUE', theme),
                        const SizedBox(height: 12),
                        _buildColorGrid(theme),
                        const SizedBox(height: 32),
                      ],
                      _label('PRÉ-VISUALIZAÇÃO', theme),
                      const SizedBox(height: 12),
                      _buildPreview(theme),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t, ThemeProvider theme) => Text(
    t,
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: theme.textHint,
      letterSpacing: 0.8,
    ),
  );

  Widget _buildThemeSelector(ThemeProvider theme) {
    final options = [
      (StrkThemeMode.dark, Icons.dark_mode_rounded, 'Escuro'),
      (StrkThemeMode.light, Icons.light_mode_rounded, 'Claro'),
      (StrkThemeMode.custom, Icons.palette_rounded, 'Custom'),
    ];
    return Row(
      children: List.generate(options.length, (i) {
        final (mode, icon, label) = options[i];
        final sel = theme.mode == mode;
        return Expanded(
          child: GestureDetector(
            onTap: () => theme.setMode(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: sel
                    ? theme.accent.withValues(alpha: 0.15)
                    : theme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: sel ? theme.accent : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    color: sel ? theme.accent : theme.textHint,
                    size: 26,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sel ? theme.accent : theme.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBgSelector(ThemeProvider theme) {
    return Row(
      children: [
        _bgOption(
          theme,
          CustomBgMode.dark,
          Icons.dark_mode_rounded,
          'Escuro',
          const Color(0xFF0D0D0D),
          Colors.white38,
          true,
        ),
        const SizedBox(width: 10),
        _bgOption(
          theme,
          CustomBgMode.light,
          Icons.light_mode_rounded,
          'Claro',
          const Color(0xFFF5F5F5),
          Colors.black38,
          false,
        ),
      ],
    );
  }

  Widget _bgOption(
    ThemeProvider theme,
    CustomBgMode bgMode,
    IconData icon,
    String label,
    Color swatch,
    Color iconColor,
    bool hasDarkBorder,
  ) {
    final sel = theme.customBg == bgMode;
    return Expanded(
      child: GestureDetector(
        onTap: () => theme.setCustomBg(bgMode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: sel ? theme.accent.withValues(alpha: 0.15) : theme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: sel ? theme.accent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: swatch,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasDarkBorder ? Colors.white12 : Colors.black12,
                  ),
                ),
                child: Icon(
                  icon,
                  color: sel ? theme.accent : iconColor,
                  size: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: sel ? theme.accent : theme.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorGrid(ThemeProvider theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _presets.length,
      itemBuilder: (_, i) {
        final color = _presets[i];
        final sel = theme.customAccent.toARGB32() == color.toARGB32();
        return GestureDetector(
          onTap: () => theme.setCustomAccent(color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: sel
                    ? (theme.isLight ? Colors.black45 : Colors.white70)
                    : Colors.transparent,
                width: 3,
              ),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: sel
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildPreview(ThemeProvider theme) {
    final accent = theme.accent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.water_drop_outlined, size: 16, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Beber água',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                    ),
                    Text(
                      '12 dias seguidos',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 13, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: 0.75,
              minHeight: 5,
              backgroundColor: accent.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '3/4 hábitos',
                style: TextStyle(fontSize: 11, color: theme.textSecondary),
              ),
              Text(
                '75%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Criar hábito',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
