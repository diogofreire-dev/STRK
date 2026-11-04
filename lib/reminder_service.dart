import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'habit.dart';

/// Um lembrete concreto: qual notificação, quando, e o que diz.
class PlannedReminder {
  final int id;
  final DateTime when;
  final String title;
  final String body;

  const PlannedReminder({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
  });
}

/// Lembretes locais dos hábitos. Em vez de um alarme diário fixo (que
/// tocava mesmo com o hábito já feito), agendamos notificações soltas para
/// os próximos dias e saltamos hoje quando o hábito já está concluído.
/// Sempre que algo muda, [sync] apaga tudo o que está pendente e volta a
/// agendar.
class ReminderService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  /// O iOS só guarda 64 notificações pendentes por app; deixamos folga.
  static const maxPending = 60;
  static const maxDaysAhead = 7;

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static Future<void> init() async {
    if (!_supported || _ready) return;
    tz.initializeTimeZones();
    final local = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(local.identifier));

    // As permissões já são pedidas pelo NotificationsService (FCM), por isso
    // aqui não voltamos a pedir.
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: darwin,
        macOS: darwin,
      ),
    );
    _ready = true;
  }

  static Future<void> sync(List<Habit> habits) async {
    if (!_supported) return;
    try {
      await init();
      await _plugin.cancelAllPendingNotifications();
      for (final r in plan(habits, DateTime.now())) {
        await _plugin.zonedSchedule(
          id: r.id,
          scheduledDate: tz.TZDateTime.from(r.when, tz.local),
          title: r.title,
          body: r.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'habit_reminders',
              'Lembretes de hábitos',
              channelDescription:
                  'Lembra-te dos hábitos que ainda não fizeste.',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
            macOS: DarwinNotificationDetails(),
          ),
          // Inexato: pode chegar uns minutos depois, mas não precisa da
          // permissão de alarmes exatos (que a Play Store restringe).
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e, stack) {
      debugPrint('Falha ao agendar lembretes: $e\n$stack');
    }
  }

  static Future<void> cancelAll() async {
    if (!_supported || !_ready) return;
    await _plugin.cancelAllPendingNotifications();
  }

  // ── Planeamento (puro, testável) ─────────────────────────────────────────

  /// Calcula todos os lembretes a agendar a partir de [now].
  static List<PlannedReminder> plan(List<Habit> habits, DateTime now) {
    final withReminder = habits
        .where(
          (h) =>
              h.reminderEnabled &&
              h.reminderHour != null &&
              h.reminderMinute != null,
        )
        .toList();
    if (withReminder.isEmpty) return const [];
    final days = (maxPending ~/ withReminder.length).clamp(1, maxDaysAhead);

    final result = <PlannedReminder>[];
    for (final h in withReminder) {
      for (var offset = 0; offset < days; offset++) {
        final when = DateTime(
          now.year,
          now.month,
          now.day + offset,
          h.reminderHour!,
          h.reminderMinute!,
        );
        if (offset == 0 && (h.completedToday || !when.isAfter(now))) continue;
        result.add(
          PlannedReminder(
            id: notificationId(h.id, offset),
            when: when,
            title: h.name,
            body: _body(h, offset),
          ),
        );
      }
    }
    // Com mais de [maxPending] hábitos, ficam os lembretes mais próximos.
    result.sort((a, b) => a.when.compareTo(b.when));
    return result.take(maxPending).toList();
  }

  static String _body(Habit h, int offset) {
    // Hoje sabemos o streak que está em risco; nos dias seguintes não.
    if (offset == 0 && h.streak > 0) {
      final dias = h.streak == 1 ? '1 dia' : '${h.streak} dias';
      return '🔥 Vais em $dias seguidos. Não deixes o streak cair hoje.';
    }
    return 'Ainda vais a tempo. Marca o hábito de hoje no STRK.';
  }

  /// Id estável por hábito e dia. Não usamos `String.hashCode` porque o Dart
  /// não garante que seja igual entre execuções da app. FNV-1a de 32 bits,
  /// cortado para caber num int de 32 bits depois de multiplicado por 10.
  static int notificationId(String habitId, int dayOffset) {
    var hash = 0x811c9dc5;
    for (final unit in habitId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return (hash % 200000000) * 10 + dayOffset;
  }
}
