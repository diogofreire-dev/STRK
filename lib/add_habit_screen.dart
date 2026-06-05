import 'package:flutter/material.dart';
import 'habit.dart';

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

    final newHabit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      icon: _selectedIcon,
      streak: 0,
      reminderEnabled: _reminderEnabled,
      reminderHour: _reminderEnabled ? _reminderTime.hour : null,
      reminderMinute: _reminderEnabled ? _reminderTime.minute : null,
    );

    Navigator.pop(context, newHabit);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.4)),
        ),
        title: const Text(
          'Novo hábito',
          style: TextStyle(
            color: Color(0xFFE8E8E8),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Nome'),
            const SizedBox(height: 10),
            _buildNameField(),
            const SizedBox(height: 12),
            Row(
              children: [
                Switch(
                  value: _reminderEnabled,
                  onChanged: (v) => setState(() => _reminderEnabled = v),
                  activeThumbImage: null,
                  activeThumbColor: const Color(0xFFC8FF00),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Lembrete diário',
                  style: TextStyle(color: Color(0xFFE8E8E8)),
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
                      style: const TextStyle(color: Color(0xFFE8E8E8)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            _buildLabel('Ícone'),
            const SizedBox(height: 10),
            _buildIconGrid(),
            const SizedBox(height: 32),
            _buildSaveButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.3),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      autofocus: true,
      style: const TextStyle(
        color: Color(0xFFE8E8E8),
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      cursorColor: const Color(0xFFC8FF00),
      decoration: InputDecoration(
        hintText: 'Ex: Beber água, Exercício...',
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.2),
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFC8FF00), width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildIconGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _icons.length,
      itemBuilder: (context, index) {
        final item = _icons[index];
        final isSelected = _selectedIcon == item['icon'];
        return GestureDetector(
          onTap: () => setState(() => _selectedIcon = item['icon']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFC8FF00).withValues(alpha: 0.15)
                  : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFC8FF00)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Icon(
              item['icon'] as IconData,
              size: 20,
              color: isSelected
                  ? const Color(0xFFC8FF00)
                  : Colors.white.withValues(alpha: 0.3),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _save,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFC8FF00),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'Criar hábito',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0D0D0D),
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }
}
