import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'notifications_service.dart';
import 'firebase_options.dart';
import 'habit.dart';
import 'add_habit_screen.dart';
import 'habit_service.dart';
import 'auth_screen.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';
import 'calendar_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GoogleSignIn.instance.initialize();
  await NotificationsService.init();
  runApp(const StrkApp());
}

class StrkApp extends StatelessWidget {
  const StrkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Strk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC8FF00),
          surface: Color(0xFF1A1A1A),
        ),
        fontFamily: 'SF Pro Display',
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF0D0D0D),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFFC8FF00)),
              ),
            );
          }
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  List<Habit> habits = [];
  User? _user;
  late final StreamSubscription<User?> _userSubscription;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _userSubscription = FirebaseAuth.instance.userChanges().listen((user) {
      if (!mounted) return;
      setState(() {
        _user = user;
      });
    });
    _loadHabits();
  }

  @override
  void dispose() {
    _userSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadHabits() async {
    final loaded = await HabitService.loadHabits();
    final lastDate = await HabitService.getLastOpenDate();
    final today = HabitService.todayString();
    final shouldReset = lastDate != today;

    setState(() {
      habits = loaded.isEmpty
          ? [
              Habit(
                id: '1',
                name: 'Beber água',
                icon: Icons.water_drop_outlined,
                streak: 12,
              ),
              Habit(
                id: '2',
                name: 'Exercício',
                icon: Icons.fitness_center_outlined,
                streak: 7,
              ),
              Habit(
                id: '3',
                name: 'Leitura',
                icon: Icons.menu_book_outlined,
                streak: 3,
              ),
              Habit(
                id: '4',
                name: 'Meditação',
                icon: Icons.self_improvement_outlined,
                streak: 1,
              ),
            ]
          : loaded;

      if (shouldReset) {
        for (final habit in habits) {
          if (!habit.completedToday) habit.streak = 0;
          habit.completedToday = false;
        }
      }
    });

    // Schedule reminders for loaded habits so they persist across restarts
    for (final habit in habits) {
      if (habit.reminderEnabled &&
          habit.reminderHour != null &&
          habit.reminderMinute != null) {
        // Cancel any existing scheduled notification (idempotent) then reschedule
        await NotificationsService.cancelReminder(habit.id);
        await NotificationsService.scheduleDailyReminder(
          habit.id,
          habit.reminderHour!,
          habit.reminderMinute!,
          'Lembra-te de: ${habit.name}',
          'Não te esqueças do teu hábito diário.',
        );
      }
    }

    await HabitService.saveLastOpenDate(today);
    await HabitService.saveAllHabits(habits);
  }

  void toggleHabit(Habit habit) {
    setState(() {
      habit.completedToday = !habit.completedToday;
      if (habit.completedToday) {
        habit.streak++;
      } else {
        habit.streak--;
      }
    });
    HabitService.saveHabit(habit);
    HabitService.saveDailyLog(
      habit.id,
      HabitService.todayString(),
      habit.completedToday,
    );
  }

  int get completedCount => habits.where((h) => h.completedToday).length;

  void _showEditDialog(Habit habit) {
    final controller = TextEditingController(text: habit.name);
    bool reminderEnabled = habit.reminderEnabled;
    TimeOfDay reminderTime = TimeOfDay(
      hour: habit.reminderHour ?? 8,
      minute: habit.reminderMinute ?? 0,
    );

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Editar hábito',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE8E8E8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: const TextStyle(
                      color: Color(0xFFE8E8E8),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    cursorColor: const Color(0xFFC8FF00),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF2C2C2C),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFC8FF00),
                          width: 1,
                        ),
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
                        onChanged: (v) =>
                            setStateDialog(() => reminderEnabled = v),
                        activeThumbImage: null,
                        activeThumbColor: const Color(0xFFC8FF00),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Lembrete diário',
                        style: TextStyle(color: Color(0xFFE8E8E8)),
                      ),
                      const Spacer(),
                      if (reminderEnabled)
                        GestureDetector(
                          onTap: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: reminderTime,
                            );
                            if (t != null) {
                              setStateDialog(() => reminderTime = t);
                            }
                          },
                          child: Text(
                            reminderTime.format(context),
                            style: const TextStyle(color: Color(0xFFE8E8E8)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2C),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Cancelar',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF888888),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (controller.text.trim().isNotEmpty) {
                              setState(
                                () => habit.name = controller.text.trim(),
                              );
                              // update reminder fields
                              habit.reminderEnabled = reminderEnabled;
                              if (reminderEnabled) {
                                habit.reminderHour = reminderTime.hour;
                                habit.reminderMinute = reminderTime.minute;
                              } else {
                                habit.reminderHour = null;
                                habit.reminderMinute = null;
                              }
                              HabitService.saveHabit(habit);

                              // schedule or cancel notification
                              if (habit.reminderEnabled &&
                                  habit.reminderHour != null &&
                                  habit.reminderMinute != null) {
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

                              Navigator.pop(context);
                              setState(() {});
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC8FF00),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Guardar',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0D0D0D),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: _buildTabContent(),
      floatingActionButton: _currentTab == 0
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFC8FF00),
              foregroundColor: const Color(0xFF0D0D0D),
              elevation: 0,
              onPressed: () async {
                final newHabit = await Navigator.push<Habit>(
                  context,
                  MaterialPageRoute(builder: (_) => const AddHabitScreen()),
                );
                if (newHabit != null) {
                  setState(() => habits.add(newHabit));
                  HabitService.saveHabit(newHabit);
                  if (newHabit.reminderEnabled &&
                      newHabit.reminderHour != null &&
                      newHabit.reminderMinute != null) {
                    NotificationsService.scheduleDailyReminder(
                      newHabit.id,
                      newHabit.reminderHour!,
                      newHabit.reminderMinute!,
                      'Lembra-te de: ${newHabit.name}',
                      'Não te esqueças do teu hábito diário.',
                    );
                  }
                }
              },
              child: const Icon(Icons.add, size: 28),
            )
          : null,
      bottomNavigationBar: _buildTabBar(),
    );
  }

  Widget _buildTabContent() {
    if (_currentTab == 0) {
      return SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildHeader(), _buildProgressCard(), _buildHabitsList()],
        ),
      );
    }

    if (_currentTab == 1) {
      return SafeArea(
        child: Column(
          children: [
            _buildPageHeader('Calendário'),
            Expanded(child: CalendarScreen(habits: habits)),
          ],
        ),
      );
    }

    if (_currentTab == 2) {
      return SafeArea(
        child: Column(
          children: [
            _buildPageHeader('Stats'),
            Expanded(child: StatsScreen(habits: habits)),
          ],
        ),
      );
    }

    return const ProfileScreen();
  }

  Widget _buildPageHeader(String title) {
    final name = _user?.displayName?.split(' ').first ?? 'Diogo';
    final photoUrl = _user?.photoURL;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFFE8E8E8),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF2C2C2C),
              backgroundImage: photoUrl != null
                  ? NetworkImage(photoUrl) as ImageProvider
                  : null,
              child: photoUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'D',
                      style: const TextStyle(
                        color: Color(0xFFC8FF00),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final name = _user?.displayName?.split(' ').first ?? 'Diogo';
    final photoUrl = _user?.photoURL;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset('assets/images/strk_logo.svg', height: 28),
                const SizedBox(height: 20),
                Text(
                  _getGreeting(name),
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color.fromRGBO(255, 255, 255, 0.35),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Os teus\nhábitos.',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE8E8E8),
                    letterSpacing: -1.5,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF2C2C2C),
            backgroundImage: photoUrl != null
                ? NetworkImage(photoUrl) as ImageProvider
                : null,
            child: photoUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'D',
                    style: const TextStyle(
                      color: Color(0xFFC8FF00),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  String _getGreeting(String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia, $name 👋';
    if (hour < 19) return 'Boa tarde, $name 👋';
    return 'Boa noite, $name 🌙';
  }

  Widget _buildProgressCard() {
    final progress = habits.isEmpty ? 0.0 : completedCount / habits.length;
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFC8FF00),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOJE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color.fromRGBO(13, 13, 13, 0.5),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$completedCount',
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0D0D0D),
                        letterSpacing: -2,
                        height: 1,
                      ),
                    ),
                    TextSpan(
                      text: '/${habits.length}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color.fromRGBO(13, 13, 13, 0.35),
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).round()}% feito',
                style: TextStyle(
                  fontSize: 13,
                  color: const Color.fromRGBO(13, 13, 13, 0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: const Color.fromRGBO(13, 13, 13, 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF0D0D0D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsList() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'HÁBITOS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color.fromRGBO(255, 255, 255, 0.3),
                    letterSpacing: 0.8,
                  ),
                ),
                const Text(
                  '+ Novo',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFC8FF00),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: habits.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _buildHabitCard(habits[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitCard(Habit habit) {
    return Dismissible(
      key: Key(habit.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HabitService.deleteHabit(habit.id);
        NotificationsService.cancelReminder(habit.id);
        setState(() => habits.remove(habit));
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 59, 48, 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Color(0xFFFF3B30),
          size: 22,
        ),
      ),
      child: GestureDetector(
        onTap: () => toggleHabit(habit),
        onLongPress: () => _showEditDialog(habit),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: habit.completedToday
                  ? const Color.fromRGBO(200, 255, 0, 0.3)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  habit.icon,
                  size: 18,
                  color: habit.completedToday
                      ? const Color(0xFFC8FF00)
                      : const Color.fromRGBO(255, 255, 255, 0.3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: habit.completedToday
                            ? const Color(0xFFE8E8E8)
                            : const Color.fromRGBO(255, 255, 255, 0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${habit.streak} dias',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: habit.completedToday
                                  ? const Color(0xFFC8FF00)
                                  : const Color.fromRGBO(255, 255, 255, 0.2),
                            ),
                          ),
                          TextSpan(
                            text: ' seguidos',
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color.fromRGBO(255, 255, 255, 0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: habit.completedToday
                      ? const Color(0xFFC8FF00)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: habit.completedToday
                        ? const Color(0xFFC8FF00)
                        : const Color.fromRGBO(255, 255, 255, 0.15),
                    width: 1.5,
                  ),
                ),
                child: habit.completedToday
                    ? const Icon(
                        Icons.check,
                        size: 14,
                        color: Color(0xFF0D0D0D),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D0D),
        border: Border(top: BorderSide(color: Color(0xFF222222), width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabItem(Icons.grid_view_rounded, 'Hoje', 0),
          _buildTabItem(Icons.calendar_month_outlined, 'Calendário', 1),
          _buildTabItem(Icons.bar_chart_rounded, 'Stats', 2),
          _buildTabItem(Icons.person_outline_rounded, 'Perfil', 3),
        ],
      ),
    );
  }

  Widget _buildTabItem(IconData icon, String label, int index) {
    final active = _currentTab == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: active
                ? const Color(0xFFC8FF00)
                : const Color.fromRGBO(255, 255, 255, 0.25),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: active
                  ? const Color(0xFFC8FF00)
                  : const Color.fromRGBO(255, 255, 255, 0.25),
            ),
          ),
        ],
      ),
    );
  }
}
