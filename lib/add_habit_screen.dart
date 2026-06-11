import 'package:flutter/material.dart';
import 'habit.dart';
import 'theme_provider.dart';
import 'strk_logo.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});
  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final TextEditingController _nameController = TextEditingController();
  IconData _selectedIcon = Icons.star_outline_rounded;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);

  final List<Map<String, dynamic>> _icons = [
    {'icon': Icons.water_drop_outlined, 'label': 'Água'},
    {'icon': Icons.fitness_center_outlined, 'label': 'Exercício'},
    {'icon': Icons.menu_book_outlined, 'label': 'Leitura'},
    {'icon': Icons.self_improvement_outlined, 'label': 'Meditação'},
    {'icon': Icons.bedtime_outlined, 'label': 'Sono'},
    {'icon': Icons.restaurant_outlined, 'label': 'Dieta'},
    {'icon': Icons.code_outlined, 'label': 'Código'},
    {'icon': Icons.music_note_outlined, 'label': 'Música'},
    {'icon': Icons.directions_run_outlined, 'label': 'Corrida'},
    {'icon': Icons.favorite_outline_rounded, 'label': 'Saúde'},
    {'icon': Icons.lightbulb_outline_rounded, 'label': 'Aprender'},
    {'icon': Icons.star_outline_rounded, 'label': 'Outro'},
  ];

  void _save() {
    if (_nameController.text.trim().isEmpty) return;
    Navigator.pop(
      context,
      Habit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        icon: _selectedIcon,
        streak: 0,
        reminderEnabled: _reminderEnabled,
        reminderHour: _reminderEnabled ? _reminderTime.hour : null,
        reminderMinute: _reminderEnabled ? _reminderTime.minute : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProviderScope.of(context);
    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: theme.bg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.close, color: theme.textHint),
        ),
        title: const StrkLogo(height: 22),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Novo hábito',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: theme.textPrimary,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 24),
            _buildLabel('Nome', theme),
            const SizedBox(height: 10),
            _buildNameField(theme),
            const SizedBox(height: 12),
            Row(
              children: [
                Switch(
                  value: _reminderEnabled,
                  onChanged: (v) => setState(() => _reminderEnabled = v),
                  activeThumbColor: theme.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  'Lembrete diário',
                  style: TextStyle(color: theme.textPrimary),
                ),
                const Spacer(),
                if (_reminderEnabled)
                  GestureDetector(
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: _reminderTime,
                      );
                      if (t != null) setState(() => _reminderTime = t);
                    },
                    child: Text(
                      _reminderTime.format(context),
                      style: TextStyle(
                        color: theme.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            _buildLabel('Ícone', theme),
            const SizedBox(height: 10),
            _buildIconGrid(theme),
            const SizedBox(height: 32),
            _buildSaveButton(theme),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, ThemeProvider theme) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: theme.textHint,
      letterSpacing: 0.8,
    ),
  );

  Widget _buildNameField(ThemeProvider theme) => TextField(
    controller: _nameController,
    autofocus: true,
    style: TextStyle(
      color: theme.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    cursorColor: theme.accent,
    decoration: InputDecoration(
      hintText: 'Ex: Beber água, Exercício...',
      hintStyle: TextStyle(
        color: theme.textHint,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: theme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.accent, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );

  Widget _buildIconGrid(ThemeProvider theme) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 6,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
    ),
    itemCount: _icons.length,
    itemBuilder: (_, index) {
      final item = _icons[index];
      final isSelected = _selectedIcon == item['icon'];
      return GestureDetector(
        onTap: () => setState(() => _selectedIcon = item['icon']),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.accent.withValues(alpha: 0.15)
                : theme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? theme.accent : Colors.transparent,
              width: 1,
            ),
          ),
          child: Icon(
            item['icon'] as IconData,
            size: 20,
            color: isSelected ? theme.accent : theme.textHint,
          ),
        ),
      );
    },
  );

  Widget _buildSaveButton(ThemeProvider theme) => GestureDetector(
    onTap: _save,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.accent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'Criar hábito',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
      ),
    ),
  );
}
