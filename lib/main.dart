import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'notifications_service.dart';
import 'reminder_service.dart';
import 'emulators.dart';
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
import 'home/celebrations.dart';
import 'mascot.dart';
import 'transitions.dart';
import 'web_frame.dart';
import 'tappable.dart';

// Chave do site reCAPTCHA v3 para o App Check na versão web. Não é um
// segredo (fica visível no browser), mas cada um põe a sua ao compilar:
//   flutter build web --dart-define=APPCHECK_WEB_KEY=<chave>
// Obtém-se em: Firebase Console > App Check > Apps > STRK (Web) > reCAPTCHA v3.
const kAppCheckWebRecaptchaSiteKey = String.fromEnvironment('APPCHECK_WEB_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (useEmulators) await connectToEmulators();

  // App Check tem de ser ativado logo a seguir ao Firebase.initializeApp(),
  // antes de qualquer outro serviço (Auth, Firestore, Storage, Messaging) ser usado.
  // Em debug usamos os "debug providers" (precisam de um token registado na
  // consola); em release usamos os providers reais de cada plataforma.
  // Na web sem chave (ou com emuladores) não ativamos: o reCAPTCHA com uma
  // chave inválida só enchia a consola de erros.
  final appCheckOnWeb =
      kAppCheckWebRecaptchaSiteKey.isNotEmpty && !useEmulators;
  if (!kIsWeb || appCheckOnWeb) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestProvider(),
      providerWeb: ReCaptchaV3Provider(kAppCheckWebRecaptchaSiteKey),
    );
  }

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
            // Coluna centrada em ecrãs largos (web no computador).
            builder: (context, child) => WebFrame(child: child!),
            theme: themeProvider.themeData,
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                final Widget page;
                if (snapshot.connectionState == ConnectionState.waiting) {
                  page = Scaffold(
                    key: const ValueKey('loading'),
                    backgroundColor: themeProvider.bg,
                    body: const MascotLoader(),
                  );
                } else if (snapshot.hasData) {
                  page = const HomeScreen(key: ValueKey('home'));
                } else {
                  page = const AuthScreen(key: ValueKey('auth'));
                }
                // Entrar e sair da conta passa a ser um cruzamento suave
                // em vez de um corte seco.
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  child: page,
                );
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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentTab = 0;
  List<Habit> habits = [];
  User? _user;
  bool _onboardingShown = false;
  String? _currentDay;
  // Enquanto os hábitos não chegam do Firestore não mostramos o estado
  // vazio ("Começa hoje a tua rotina"), que piscava a cada arranque.
  bool _loading = true;
  int _confettiTrigger = 0;
  late final StreamSubscription<User?> _userSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // As poses da mascote ficam em memória antes de serem precisas.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) StrkMascot.precache(context);
    });
    _user = FirebaseAuth.instance.currentUser;
    _userSubscription = FirebaseAuth.instance.userChanges().listen((user) {
      if (!mounted) return;
      setState(() => _user = user);
    });
    _loadHabits();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _userSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadHabits() async {
    final String lastDate;
    final List<Habit> loaded;
    try {
      await HabitService.loadUserProfile();
      lastDate = await HabitService.getLastOpenDate();
      loaded = await HabitService.loadHabits(lastOpenDate: lastDate);
    } catch (e) {
      debugPrint('Falha ao carregar hábitos: $e');
      if (!mounted) return;
      setState(() => _loading = false);
      _showToast('Não foi possível carregar os hábitos. Verifica a ligação.');
      return;
    }
    final today = HabitService.todayString();

    if (!mounted) return;
    setState(() {
      habits = loaded;
      _loading = false;
      _refreshDay();
    });

    ReminderService.sync(habits);

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

  /// Recalcula o "feito hoje" e os streaks quebrados de todos os hábitos.
  /// Chamado ao carregar e sempre que a app volta ao primeiro plano, porque
  /// pode ter ficado aberta de um dia para o outro.
  void _refreshDay() {
    final now = DateTime.now();
    for (final h in habits) {
      h.refreshForDay(now);
    }
    _currentDay = dateKey(now);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_currentDay == null || _currentDay == HabitService.todayString()) {
      return;
    }
    setState(_refreshDay);
    HabitService.saveAllHabits(habits);
    ReminderService.sync(habits);
  }

  void toggleHabit(Habit habit) {
    final wasPerfect = habits.isNotEmpty && completedCount == habits.length;
    setState(() {
      // Se passou da meia-noite com a app aberta, primeiro fecha o dia antigo.
      if (_currentDay != HabitService.todayString()) _refreshDay();
      habit.toggleCompletion();
      // Último hábito do dia concluído → confettis.
      if (!wasPerfect && completedCount == habits.length) {
        _confettiTrigger++;
        HapticFeedback.heavyImpact();
      }
    });
    if (habit.completedToday) {
      final milestone = streakMilestone(habit.name, habit.streak);
      if (milestone != null) {
        _showToast(milestone, icon: Icons.local_fire_department_rounded);
      }
    }
    HabitService.saveHabit(habit);
    HabitService.saveDailyLog(
      habit.id,
      HabitService.todayString(),
      habit.completedToday,
    );
    // Feito hoje → o lembrete de hoje deixa de fazer sentido (e vice-versa).
    ReminderService.sync(habits);
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
      body: Stack(
        children: [
          DirectionalTabSwitcher(
            index: _currentTab,
            child: _buildTabContent(theme),
          ),
          Positioned.fill(
            child: ConfettiOverlay(
              trigger: _confettiTrigger,
              // A cor do tema mais umas quentes, para combinar com a chama.
              colors: [
                theme.accent,
                const Color(0xFFFFD60A),
                const Color(0xFFFF375F),
                const Color(0xFF30D158),
                const Color(0xFF64D2FF),
              ],
            ),
          ),
        ],
      ),
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
              if (_loading)
                const Expanded(
                  child: MascotLoader(message: 'A carregar os teus hábitos…'),
                )
              else ...[
                _buildProgressCard(theme),
                _buildHabitsList(theme),
              ],
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
    final name = _firstName;
    final photoUrl = _user?.photoURL;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StrkHeader(
          subtitle: _getGreeting(name),
          trailing: _buildAvatar(
            photoUrl,
            name ?? _user?.email ?? 'S',
            theme,
            radius: 24,
          ),
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
    final name = _firstName;
    final photoUrl = _user?.photoURL;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StrkHeader(
          trailing: Tappable(
            // O perfil já é um separador: ir para lá em vez de o abrir
            // por cima (ficava duplicado na pilha de navegação).
            onTap: () => setState(() => _currentTab = 3),
            child: _buildAvatar(
              photoUrl,
              name ?? _user?.email ?? 'S',
              theme,
              radius: 18,
            ),
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
    return Tappable(
      onTap: () => setState(() => _currentTab = 3),
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

  /// Primeiro nome, ou null para quem se registou por email sem nome
  /// (antes aparecia "Boa noite, STRK", como se a app fosse a pessoa).
  String? get _firstName {
    final first = _user?.displayName?.trim().split(' ').first;
    return (first == null || first.isEmpty) ? null : first;
  }

  String _getGreeting(String? name) {
    final h = DateTime.now().hour;
    final base = h < 12 ? 'Bom dia' : (h < 19 ? 'Boa tarde' : 'Boa noite');
    return name == null ? base : '$base, $name';
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
              const StrkMascot(mood: MascotMood.feliz, size: 120),
              const SizedBox(height: 12),
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
                Tappable(
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
                  itemBuilder: (_, i) => StaggeredEntrance(
                    key: ValueKey('entrada-${habits[i].id}'),
                    index: i,
                    child: _buildHabitCard(habits[i], theme),
                  ),
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
        onSaved: () {
          setState(() {});
          ReminderService.sync(habits);
        },
      ),
      onDismissed: () => _deleteWithUndo(habit),
    );
  }

  /// Apagar um hábito apaga também o histórico todo, por isso não o fazemos
  /// logo: o cartão sai da lista e só é apagado no Firestore quando a barra
  /// "Desfazer" desaparece sem ter sido usada.
  void _deleteWithUndo(Habit habit) {
    final index = habits.indexOf(habit);
    setState(() => habits.remove(habit));
    ReminderService.sync(habits);

    var undone = false;
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    messenger
        .showSnackBar(
          _snackBar(
            '"${habit.name}" apagado',
            action: SnackBarAction(
              label: 'Desfazer',
              textColor: ThemeProviderScope.of(context).accent,
              onPressed: () {
                undone = true;
                if (!mounted) return;
                setState(() => habits.insert(index, habit));
                ReminderService.sync(habits);
              },
            ),
          ),
        )
        .closed
        .then((_) {
          // Se entretanto a sessão terminou, não há a quem apagar o hábito
          // (fica, o que é o lado seguro do erro).
          if (undone || FirebaseAuth.instance.currentUser == null) return;
          HabitService.deleteHabit(habit.id);
        });
  }

  void _showToast(String message, {IconData? icon}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(_snackBar(message, icon: icon));
  }

  SnackBar _snackBar(String message, {SnackBarAction? action, IconData? icon}) {
    final theme = ThemeProviderScope.of(context);
    return SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: theme.accent, size: 20),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: theme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      action: action,
      behavior: SnackBarBehavior.floating,
      backgroundColor: theme.surfaceAlt,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 4),
    );
  }

  // ── Add habit ─────────────────────────────────────────────────────────────

  Future<void> _addHabit() async {
    final newHabit = await Navigator.push<Habit>(
      context,
      sheetRoute(const AddHabitScreen()),
    );
    if (newHabit != null) {
      setState(() => habits.add(newHabit));
      HabitService.saveHabit(newHabit);
      ReminderService.sync(habits);
    }
  }
}
