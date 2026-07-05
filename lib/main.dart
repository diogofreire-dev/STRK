import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
import 'home/habit_card.dart';
import 'home/progress_card.dart';
import 'home/birthday_banner.dart';
import 'home/tab_bar.dart';
import 'home/onboarding_dialog.dart';
import 'home/edit_habit_dialog.dart';

// Chave do site reCAPTCHA v3 para o App Check na versão Web.
// Obtém-se em: Firebase Console > Build > App Check > Apps > STRK (Web) > reCAPTCHA v3
// Sem isto preenchido, o App Check na Web não funciona (mas Android/iOS/macOS não precisam disto).
const String kAppCheckWebRecaptchaSiteKey = 'COLA_AQUI_A_TUA_SITE_KEY';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // App Check tem de ser ativado logo a seguir ao Firebase.initializeApp(),
  // antes de qualquer outro serviço (Auth, Firestore, Storage, Messaging) ser usado.
  // Em debug usamos os "debug providers" (precisam de um token registado na
  // consola); em release usamos os providers reais de cada plataforma.
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
    webProvider: ReCaptchaV3Provider(kAppCheckWebRecaptchaSiteKey),
  );

  if (!kIsWeb) {
    await GoogleSignIn.instance.initialize();

    // Crashlytics não está disponível na Web/Windows, só em
    // Android/iOS/macOS. Isto envia automaticamente para o Firebase
    // qualquer erro não tratado do Flutter e da própria Dart VM.
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  await NotificationsService.init();

  final themeProvider = ThemeProvider();
  await themeProvider.load();

  // O login (ou o restauro de sessão) acontece de forma assíncrona depois
  // do arranque, por isso recarregamos o tema sempre que o utilizador
  // autenticado muda — assim usamos sempre a chave correta (por uid) em
  // vez de ficarmos presos no tema "guest".
  FirebaseAuth.instance.authStateChanges().listen((_) {
    themeProvider.load();
  });

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
    await HabitService.loadUserProfile();
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
        HabitService.applyDailyReset(habits);
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
      if (mounted) showOnboardingDialog(context);
    });
  }

  void toggleHabit(Habit habit) {
    setState(() {
      habit.toggleCompletion();
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
      bottomNavigationBar: StrkTabBar(
        currentTab: _currentTab,
        onTabSelected: (i) => setState(() => _currentTab = i),
        theme: theme,
      ),
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
    return BirthdayBanner(theme: theme, displayName: _user?.displayName);
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
    return ProgressCard(
      theme: theme,
      completedCount: completedCount,
      totalCount: habits.length,
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
    return HabitCard(
      habit: habit,
      theme: theme,
      onToggle: () => toggleHabit(habit),
      onLongPress: () => showEditHabitDialog(
        context: context,
        habit: habit,
        theme: theme,
        onSaved: () => setState(() {}),
      ),
      onDismissed: () {
        HabitService.deleteHabit(habit.id);
        NotificationsService.cancelReminder(habit.id);
        setState(() => habits.remove(habit));
      },
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
}
