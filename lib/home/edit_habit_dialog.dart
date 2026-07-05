import 'package:flutter/material.dart';
import '../habit.dart';
import '../habit_service.dart';
import '../notifications_service.dart';
import '../theme_provider.dart';

/// Diálogo de edição de um hábito (nome + lembrete diário).
/// Extraído de `main.dart` (era `_HomeScreenState._showEditDialog` e
/// `_dialogBtn`).
///
/// [onSaved] é chamado depois de guardar as alterações, para o ecrã pai
/// poder atualizar o seu estado (equivalente ao `setState(() {})` que
/// existia no método original).
void showEditHabitDialog({
  required BuildContext context,
  required Habit habit,
  required ThemeProvider theme,
  required VoidCallback onSaved,
}) {
  final controller = TextEditingController(text: habit.name);
  bool reminderEnabled = habit.reminderEnabled;
  TimeOfDay reminderTime = TimeOfDay(
    hour: habit.reminderHour ?? 8,
    minute: habit.reminderMinute ?? 0,
  );

  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: theme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: StatefulBuilder(
          builder: (ctx, setStateDialog) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Editar hábito',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                cursorColor: theme.accent,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: theme.isLight
                      ? const Color(0xFFF0F0F0)
                      : const Color(0xFF2C2C2C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.accent, width: 1),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Switch(
                    value: reminderEnabled,
                    onChanged: (v) => setStateDialog(() => reminderEnabled = v),
                    activeThumbColor: theme.accent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Lembrete diário',
                    style: TextStyle(color: theme.textPrimary),
                  ),
                  const Spacer(),
                  if (reminderEnabled)
                    GestureDetector(
                      onTap: () async {
                        final t = await showTimePicker(
                          context: ctx,
                          initialTime: reminderTime,
                        );
                        if (t != null) setStateDialog(() => reminderTime = t);
                      },
                      child: Text(
                        reminderTime.format(ctx),
                        style: TextStyle(color: theme.textPrimary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: _dialogBtn(
                        'Cancelar',
                        theme.isLight
                            ? const Color(0xFFE8E8E8)
                            : const Color(0xFF2C2C2C),
                        const Color(0xFF888888),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (controller.text.trim().isEmpty) return;
                        habit.name = controller.text.trim();
                        habit.reminderEnabled = reminderEnabled;
                        habit.reminderHour = reminderEnabled
                            ? reminderTime.hour
                            : null;
                        habit.reminderMinute = reminderEnabled
                            ? reminderTime.minute
                            : null;
                        HabitService.saveHabit(habit);
                        if (habit.reminderEnabled &&
                            habit.reminderHour != null) {
                          NotificationsService.scheduleDailyReminder(
                            habit.id,
                            habit.reminderHour!,
                            habit.reminderMinute!,
                            'Lembra-te de: ${habit.name}',
                            'Não te esqueças do teu hábito diário.',
                          );
                        } else {
                          NotificationsService.cancelReminder(habit.id);
                        }
                        Navigator.pop(ctx);
                        onSaved();
                      },
                      child: _dialogBtn('Guardar', theme.accent, Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _dialogBtn(String label, Color bg, Color fg) => Container(
  padding: const EdgeInsets.symmetric(vertical: 12),
  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
  child: Text(
    label,
    textAlign: TextAlign.center,
    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg),
  ),
);
