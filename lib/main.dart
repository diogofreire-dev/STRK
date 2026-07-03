import 'package:flutter/material.dart';
import 'dart:async';
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
import 'package:flutter/foundation.dart';
import 'badges_screen.dart';
import 'strk_header.dart';
import 'theme_provider.dart';
import 'onboarding_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    await GoogleSignIn.instance.initialize();
  }

  await NotificationsService.init();

  final themeProvider = ThemeProvider();
  await themeProvider.load();

  runApp(StrkApp(themeProvider: themeProvider));
}

class StrkApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  const StrkApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return ThemeProviderScope(
      provider: themeProvider,
      child: AnimatedBuilder(
        animation: themeProvider,
        builder: (context, _) {
          return MaterialApp(
            title: 'STRK',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    backgroundColor: themeProvider.bg,
                    body: Center(
                      child: CircularProgressIndicator(
                        color: themeProvider.accent,
                      ),
                    ),
                  );
                }
                if (snapshot.hasData) return const HomeScreen();
                return const AuthScreen();
              },
            ),
          );
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
  bool _onboardingShown = false;
  late final StreamSubscription<User?> _userSubscription;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _userSubscription = FirebaseAuth.instance.userChanges().listen((user) {
      if (!mounted) return;
      setState(() => _user = user);
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
        for (final h in habits) {
          if (!h.completedToday) h.streak = 0;
          h.completedToday = false;
        }
      }
    });

    for (final habit in habits) {
      if (habit.reminderEnabled &&
          habit.reminderHour != null &&
          habit.reminderMinute != null) {
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

    if (!mounted || _onboardingShown) return;
    final shouldShow = await OnboardingService.shouldShowOnboarding();
    if (!shouldShow || !mounted) return;
    _onboardingShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showOnboardingDialog();
    });
  }

  Future<void> _showOnboardingDialog() async {
    final theme = ThemeProviderScope.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.auto_awesome_rounded, color: theme.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Bem-vindo ao STRK',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pequenos hábitos constam mais do que grandes intenções.',
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            _buildOnboardingTip(
              'Marca um hábito e vê o teu streak crescer.',
              theme,
            ),
            const SizedBox(height: 8),
            _buildOnboardingTip(
              'Volta todos os dias para manter o ritmo.',
              theme,
            ),
            const SizedBox(height: 8),
            _buildOnboardingTip(
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

  Widget _buildOnboardingTip(String text, ThemeProvider theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_rounded, color: theme.accent, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  void toggleHabit(Habit habit) {
    setState(() {
      habit.completedToday = !habit.completedToday;
      habit.completedToday ? habit.streak++ : habit.streak--;
    });
    HabitService.saveHabit(habit);
    HabitService.saveDailyLog(
      habit.id,
      HabitService.todayString(),
      habit.completedToday,
    );
  }

  int get completedCount => habits.where((h) => h.completedToday).length;

  bool get _isBirthday {
    final bd = HabitService.cachedBirthday;
    if (bd == null) return false;
    final now = DateTime.now();
    return bd.month == now.month && bd.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProviderScope.of(context);

    return Scaffold(
      backgroundColor: theme.bg,
      body: _buildTabContent(theme),
      floatingActionButton: _currentTab == 0
          ? FloatingActionButton(
              backgroundColor: theme.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              onPressed: _addHabit,
              child: const Icon(Icons.add, size: 28),
            )
          : null,
      bottomNavigationBar: _buildTabBar(theme),
    );
  }

  Widget _buildTabContent(ThemeProvider theme) {
    switch (_currentTab) {
      case 0:
        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHomeHeader(theme),
              if (_isBirthday) _buildBirthdayBanner(theme),
              _buildProgressCard(theme),
              _buildHabitsList(theme),
            ],
          ),
        );
      case 1:
        return SafeArea(
          child: Column(
            children: [
              _buildPageHeader('Calendário', theme),
              Expanded(child: CalendarScreen(habits: habits)),
            ],
          ),
        );
      case 2:
        return DefaultTabController(
          length: 2,
          child: SafeArea(
            child: Column(
              children: [
                _buildPageHeader('Stats', theme),
                Container(
                  margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    labelColor: theme.bg,
                    unselectedLabelColor: theme.textPrimary.withValues(
                      alpha: 0.3,
                    ),
                    indicator: BoxDecoration(
                      color: theme.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: const [
                      Tab(text: 'Estatísticas'),
                      Tab(text: 'Conquistas'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    children: [
                      StatsScreen(habits: habits),
                      BadgesScreen(habits: habits),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      default:
        return ProfileScreen(habits: habits);
    }
  }

  // ── Birthday banner ───────────────────────────────────────────────────────

  Widget _buildBirthdayBanner(ThemeProvider theme) {
    final name = _user?.displayName?.split(' ').first ?? '';
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFBF5AF2).withValues(alpha: 0.2),
            const Color(0xFFFF6B00).withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFBF5AF2).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Text('🥳', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Feliz aniversário${name.isNotEmpty ? ', $name' : ''}!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimary,
                  ),
                ),
                Text(
                  'Que os teus hábitos te levem longe este ano 🔥',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textPrimary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Home header ───────────────────────────────────────────────────────────

  Widget _buildHomeHeader(ThemeProvider theme) {
    final name = _user?.displayName?.split(' ').first ?? 'STRK';
    final photoUrl = _user?.photoURL;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StrkHeader(
          subtitle: _getGreeting(name),
          trailing: _buildAvatar(photoUrl, name, theme, radius: 24),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Os teus\nhábitos.',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: theme.textPrimary,
              letterSpacing: -1.5,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageHeader(String title, ThemeProvider theme) {
    final name = _user?.displayName?.split(' ').first ?? 'strk';
    final photoUrl = _user?.photoURL;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StrkHeader(
          trailing: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfileScreen(habits: habits)),
            ),
            child: _buildAvatar(photoUrl, name, theme, radius: 18),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: theme.textPrimary,
              letterSpacing: -1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(
    String? photoUrl,
    String name,
    ThemeProvider theme, {
    double radius = 22,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfileScreen(habits: habits)),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: theme.surface,
        backgroundImage: photoUrl != null
            ? NetworkImage(photoUrl) as ImageProvider
            : null,
        child: photoUrl == null
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'S',
                style: TextStyle(
                  color: theme.accent,
                  fontSize: radius * 0.85,
                  fontWeight: FontWeight.w800,
                ),
              )
            : null,
      ),
    );
  }

  String _getGreeting(String name) {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia, $name 👋';
    if (h < 19) return 'Boa tarde, $name 👋';
    return 'Boa noite, $name 🌙';
  }

  // ── Progress card ─────────────────────────────────────────────────────────

  Widget _buildProgressCard(ThemeProvider theme) {
    final progress = habits.isEmpty ? 0.0 : completedCount / habits.length;
    final accent = theme.accent;
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.9),
            accent,
            accent.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HOJE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0x80FFFFFF),
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
                        color: Colors.white,
                        letterSpacing: -2,
                        height: 1,
                      ),
                    ),
                    TextSpan(
                      text: '/${habits.length}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0x80FFFFFF),
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).round()}% feito',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xCCFFFFFF),
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
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Pequenos passos todos os dias fazem a diferença ✨',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xCCFFFFFF),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────

  Widget _buildEmptyState(ThemeProvider theme) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.accent.withValues(alpha: 0.18)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: theme.accent,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Começa hoje a tua rotina',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Adiciona o teu primeiro hábito e dá o primeiro passo para uma rotina mais forte.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textPrimary.withValues(alpha: 0.6),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _addHabit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Adicionar hábito'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Habits list ───────────────────────────────────────────────────────────

  Widget _buildHabitsList(ThemeProvider theme) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
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
                    color: theme.textPrimary.withValues(alpha: 0.3),
                    letterSpacing: 0.8,
                  ),
                ),
                GestureDetector(
                  onTap: _addHabit,
                  child: Text(
                    '+ Novo',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.accent,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (habits.isEmpty)
              _buildEmptyState(theme)
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: habits.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _buildHabitCard(habits[i], theme),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitCard(Habit habit, ThemeProvider theme) {
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
          color: const Color(0x26FF3B30),
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
        onLongPress: () => _showEditDialog(habit, theme),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: habit.completedToday
                  ? theme.accent.withValues(alpha: 0.35)
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
                  color: theme.isLight
                      ? theme.accent.withValues(alpha: 0.1)
                      : const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  habit.icon,
                  size: 18,
                  color: habit.completedToday
                      ? theme.accent
                      : theme.textPrimary.withValues(alpha: 0.2),
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
                            ? theme.textPrimary
                            : theme.textPrimary.withValues(alpha: 0.5),
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
                                  ? theme.accent
                                  : theme.textPrimary.withValues(alpha: 0.2),
                            ),
                          ),
                          TextSpan(
                            text: ' seguidos',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.textPrimary.withValues(alpha: 0.2),
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
                      ? theme.accent
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: habit.completedToday
                        ? theme.accent
                        : theme.textPrimary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: habit.completedToday
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────────────────

  Widget _buildTabBar(ThemeProvider theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.bg,
        border: Border(top: BorderSide(color: theme.divider, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabItem(Icons.grid_view_rounded, 'Hoje', 0, theme),
          _buildTabItem(Icons.calendar_month_outlined, 'Calendário', 1, theme),
          _buildTabItem(Icons.bar_chart_rounded, 'Stats', 2, theme),
          _buildTabItem(Icons.person_outline_rounded, 'Perfil', 3, theme),
        ],
      ),
    );
  }

  Widget _buildTabItem(
    IconData icon,
    String label,
    int index,
    ThemeProvider theme,
  ) {
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
                ? theme.accent
                : theme.textPrimary.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: active
                  ? theme.accent
                  : theme.textPrimary.withValues(alpha: 0.25),
            ),
          ),
        ],
      ),
    );
  }

  // ── Add habit ─────────────────────────────────────────────────────────────

  Future<void> _addHabit() async {
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
  }

  // ── Edit dialog ───────────────────────────────────────────────────────────

  void _showEditDialog(Habit habit, ThemeProvider theme) {
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
                      onChanged: (v) =>
                          setStateDialog(() => reminderEnabled = v),
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
                          setState(() => habit.name = controller.text.trim());
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
                          setState(() {});
                        },
                        child: _dialogBtn(
                          'Guardar',
                          theme.accent,
                          Colors.white,
                        ),
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
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg),
    ),
  );
}
