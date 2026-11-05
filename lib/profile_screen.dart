import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'account_service.dart';
import 'profile_service.dart';
import 'badges_screen.dart';
import 'habit.dart';
import 'habit_service.dart';
import 'theme_provider.dart';
import 'strk_header.dart';
import 'theme_settings_screen.dart';
import 'profile/badges_section.dart';
import 'tappable.dart';

class ProfileScreen extends StatefulWidget {
  final List<Habit> habits;
  const ProfileScreen({super.key, this.habits = const []});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  String? _photoUrl;
  bool _isUploading = false;
  DateTime? _birthday;

  @override
  void initState() {
    super.initState();
    _refreshUser();
    _birthday = HabitService.cachedBirthday;
  }

  Future<void> _refreshUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) await user.reload();
    final refreshed = FirebaseAuth.instance.currentUser;
    if (!mounted) return;
    setState(() {
      _user = refreshed;
      _photoUrl = refreshed?.photoURL;
    });
  }

  // ── Photo ──────────────────────────────────────────────────────────────────

  Future<void> _pickProfilePhoto(ImageSource source) async {
    final file = await ProfileService.pickProfilePhoto(source: source);
    if (file == null) return;
    setState(() => _isUploading = true);
    try {
      final url = await ProfileService.uploadProfilePhoto(file);
      await ProfileService.saveProfilePhotoUrl(url);
      if (mounted) {
        setState(() {
          _photoUrl = url;
          _isUploading = false;
        });
      }
    } catch (_) {
      _showMessage('Não foi possível carregar a foto.', isError: true);
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<ImageSource?> _showPhotoSourceDialog(
    ThemeProvider theme,
  ) => showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: theme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          if (!kIsWeb)
            ListTile(
              leading: Icon(Icons.photo_camera_rounded, color: theme.accent),
              title: Text('Câmara', style: TextStyle(color: theme.textPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ListTile(
            leading: Icon(Icons.photo_library_rounded, color: theme.accent),
            title: Text('Galeria', style: TextStyle(color: theme.textPrimary)),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? const Color(0xFFFF3B30)
            : const Color(0xFF1A1A1A),
      ),
    );
  }

  Future<void> _confirmRemovePhoto(ThemeProvider theme) async {
    final confirmed =
        await _showConfirmDialog(
          theme,
          title: 'Remover foto de perfil?',
          body: 'A foto será removida do teu perfil e da cloud.',
          confirmLabel: 'Remover',
          confirmColor: const Color(0xFFFF3B30),
        ) ??
        false;
    if (!confirmed) return;
    setState(() => _isUploading = true);
    try {
      await ProfileService.removeProfilePhoto();
      if (mounted) setState(() => _photoUrl = null);
      await _refreshUser();
      _showMessage('Foto removida com sucesso.');
    } catch (_) {
      _showMessage('Não foi possível remover a foto.', isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ── Birthday ───────────────────────────────────────────────────────────────

  Future<void> _pickBirthday(ThemeProvider theme) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 5),
      helpText: 'Data de nascimento',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: theme.accent,
            onPrimary: Colors.white,
            surface: theme.surface,
            onSurface: theme.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    await HabitService.saveBirthday(picked);
    if (mounted) setState(() => _birthday = picked);
    _showMessage('Data de nascimento guardada!');
  }

  Future<void> _removeBirthday(ThemeProvider theme) async {
    final confirmed =
        await _showConfirmDialog(
          theme,
          title: 'Remover data de nascimento?',
          body: 'Deixarás de receber a mensagem de aniversário.',
          confirmLabel: 'Remover',
          confirmColor: const Color(0xFFFF3B30),
        ) ??
        false;
    if (!confirmed) return;
    await HabitService.removeBirthday();
    if (mounted) setState(() => _birthday = null);
    _showMessage('Data removida.');
  }

  // ── Generic confirm dialog ─────────────────────────────────────────────────

  Future<bool?> _showConfirmDialog(
    ThemeProvider theme, {
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
  }) => showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: theme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.textPrimary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Tappable(
                    onTap: () => Navigator.pop(ctx, false),
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
                  child: Tappable(
                    onTap: () => Navigator.pop(ctx, true),
                    child: _dialogBtn(confirmLabel, confirmColor, Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProviderScope.of(context);
    final name = _user?.displayName ?? 'Sem nome';
    final email = _user?.email ?? '';
    final photo = _photoUrl;

    final badges = computeBadgesResolved(widget.habits);
    final unlockedBadges = badges.where((b) => b.unlocked).toList();
    final unlockedCount = unlockedBadges.length;
    final totalCount = badges.length;

    final bdFormatted = _birthday != null
        ? DateFormat("d 'de' MMMM", 'pt_PT').format(_birthday!)
        : null;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StrkHeader(),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Perfil',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: theme.textPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildProfileCard(name, email, photo, theme),
                    const SizedBox(height: 20),
                    if (widget.habits.isNotEmpty) ...[
                      BadgesSection(
                        unlockedBadges: unlockedBadges,
                        unlockedCount: unlockedCount,
                        totalCount: totalCount,
                        allBadges: badges,
                        theme: theme,
                      ),
                      const SizedBox(height: 20),
                    ],
                    // ── Conta ──────────────────────────────────────────────────
                    _buildSection('Conta', theme, [
                      if (photo != null)
                        _buildTile(
                          theme: theme,
                          icon: Icons.delete_outline,
                          label: 'Remover foto',
                          value: 'Eliminar',
                          valueColor: const Color(0xFFFF3B30),
                          onTap: () => _confirmRemovePhoto(theme),
                        ),
                      _buildTile(
                        theme: theme,
                        icon: Icons.person_outline_rounded,
                        label: 'Nome',
                        value: name,
                        onTap: () => _editName(context, theme),
                      ),
                      _buildTile(
                        theme: theme,
                        icon: Icons.mail_outline_rounded,
                        label: 'Email',
                        value: email,
                      ),
                      if (_user?.emailVerified == false)
                        _buildTile(
                          theme: theme,
                          icon: Icons.verified_outlined,
                          label: 'Email não verificado',
                          value: 'Reenviar email',
                          valueColor: theme.accent,
                          onTap: () async {
                            await _user?.sendEmailVerification();
                            if (context.mounted) {
                              _showMessage('Email de verificação enviado!');
                            }
                          },
                        ),
                      _buildTile(
                        theme: theme,
                        icon: Icons.cake_outlined,
                        label: 'Aniversário',
                        value: bdFormatted ?? 'Adicionar',
                        valueColor: bdFormatted != null ? null : theme.accent,
                        onTap: () => _pickBirthday(theme),
                        trailingExtra: bdFormatted != null
                            ? Tappable(
                                onTap: () => _removeBirthday(theme),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: theme.textPrimary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ]),
                    const SizedBox(height: 16),
                    // ── Aparência ──────────────────────────────────────────────
                    _buildSection('Aparência', theme, [
                      _buildTile(
                        theme: theme,
                        icon: Icons.palette_outlined,
                        label: 'Tema',
                        value: _themeLabel(theme.mode),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ThemeSettingsScreen(),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    // ── Sessão ──────────────────────────────────────────────────
                    _buildSection('Sessão', theme, [
                      _buildTile(
                        theme: theme,
                        icon: Icons.logout_rounded,
                        label: 'Terminar sessão',
                        valueColor: const Color(0xFFFF3B30),
                        onTap: () => _confirmLogout(context, theme),
                      ),
                      _buildTile(
                        theme: theme,
                        icon: Icons.person_remove_outlined,
                        label: 'Eliminar conta',
                        valueColor: const Color(0xFFFF3B30),
                        onTap: () => _confirmDeleteAccount(theme),
                      ),
                    ]),
                    const SizedBox(height: 32),
                    Center(
                      child: Text(
                        'STRK v1.0.0',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.textPrimary.withValues(alpha: 0.15),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _themeLabel(StrkThemeMode mode) {
    switch (mode) {
      case StrkThemeMode.dark:
        return 'Escuro';
      case StrkThemeMode.light:
        return 'Claro';
      case StrkThemeMode.custom:
        return 'Personalizado';
    }
  }

  // ── Profile card ───────────────────────────────────────────────────────────

  Widget _buildProfileCard(
    String name,
    String email,
    String? photo,
    ThemeProvider theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Tappable(
            onTap: () async {
              final source = await _showPhotoSourceDialog(theme);
              if (source != null) await _pickProfilePhoto(source);
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.isLight
                        ? const Color(0xFFE8E8E8)
                        : const Color(0xFF2C2C2C),
                    image: photo != null
                        ? DecorationImage(
                            image: NetworkImage(photo),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: photo == null
                      ? Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: theme.accent,
                            ),
                          ),
                        )
                      : null,
                ),
                if (_isUploading)
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: theme.accent,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: theme.bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.accent, width: 1.5),
                    ),
                    child: Icon(
                      _isUploading
                          ? Icons.hourglass_top_rounded
                          : Icons.photo_camera_rounded,
                      size: 16,
                      color: theme.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textPrimary.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section & tile ─────────────────────────────────────────────────────────

  Widget _buildSection(String title, ThemeProvider theme, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.textPrimary.withValues(alpha: 0.3),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _buildTile({
    required ThemeProvider theme,
    required IconData icon,
    required String label,
    String? value,
    Color? valueColor,
    VoidCallback? onTap,
    Widget? trailingExtra,
  }) {
    return Tappable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.textPrimary.withValues(alpha: 0.06),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: theme.textPrimary.withValues(alpha: 0.35),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.textPrimary.withValues(alpha: 0.7),
                ),
              ),
            ),
            if (value != null)
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color:
                      valueColor ?? theme.textPrimary.withValues(alpha: 0.25),
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (trailingExtra != null) ...[
              const SizedBox(width: 8),
              trailingExtra,
            ],
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: theme.textPrimary.withValues(alpha: 0.15),
              ),
          ],
        ),
      ),
    );
  }

  // ── Edit name ──────────────────────────────────────────────────────────────

  void _editName(BuildContext context, ThemeProvider theme) {
    final controller = TextEditingController(text: _user?.displayName ?? '');
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Editar nome',
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
                style: TextStyle(color: theme.textPrimary, fontSize: 15),
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Tappable(
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
                    child: Tappable(
                      onTap: () async {
                        final n = controller.text.trim();
                        if (n.isEmpty) return;
                        await ProfileService.updateDisplayName(n);
                        _refreshUser();
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          _showMessage('Nome atualizado com sucesso.');
                        }
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
    );
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  void _confirmLogout(BuildContext context, ThemeProvider theme) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Terminar sessão?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Os teus hábitos ficam guardados na cloud.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textPrimary.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Tappable(
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
                    child: Tappable(
                      onTap: () async {
                        // Fecha também o ecrã de perfil, se foi aberto por
                        // cima da home, para não ficar visível sem sessão.
                        Navigator.of(context).popUntil((r) => r.isFirst);
                        await AccountService.signOut();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0x26FF3B30),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x4DFF3B30)),
                        ),
                        child: const Text(
                          'Terminar',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF3B30),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Delete account ─────────────────────────────────────────────────────────

  Future<void> _confirmDeleteAccount(ThemeProvider theme) async {
    final passwordController = TextEditingController();
    final usesPassword = AccountService.usesPassword;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFFF3B30),
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                'Eliminar a conta?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vais perder todos os hábitos, streaks, histórico e a foto de '
                'perfil. Isto não se pode desfazer.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textPrimary.withValues(alpha: 0.5),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              if (usesPassword)
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  autofocus: true,
                  style: TextStyle(color: theme.textPrimary, fontSize: 15),
                  cursorColor: theme.accent,
                  decoration: InputDecoration(
                    hintText: 'Confirma com a tua password',
                    hintStyle: TextStyle(color: theme.textHint, fontSize: 13),
                    filled: true,
                    fillColor: theme.inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                )
              else
                Text(
                  'Vais ter de confirmar com a tua conta Google.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: theme.textHint),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Tappable(
                      onTap: () => Navigator.pop(ctx, false),
                      child: _dialogBtn(
                        'Cancelar',
                        theme.surfaceAlt,
                        const Color(0xFF888888),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Tappable(
                      onTap: () => Navigator.pop(ctx, true),
                      child: _dialogBtn(
                        'Eliminar',
                        const Color(0xFFFF3B30),
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
    );
    final password = passwordController.text;
    passwordController.dispose();
    if (confirmed != true) return;
    if (usesPassword && password.isEmpty) {
      _showMessage('Escreve a tua password para confirmar.', isError: true);
      return;
    }

    setState(() => _isUploading = true);
    try {
      await AccountService.reauthenticate(password: password);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _isUploading = false);
      _showMessage(
        e.code == 'wrong-password' || e.code == 'invalid-credential'
            ? 'Password incorreta.'
            : 'Não foi possível confirmar a tua identidade.',
        isError: true,
      );
      return;
    } catch (_) {
      // Por exemplo, a janela do Google fechada sem escolher conta.
      if (mounted) setState(() => _isUploading = false);
      return;
    }

    if (!mounted) return;
    final navigator = Navigator.of(context);
    try {
      await AccountService.deleteAccount();
      // Se o perfil foi aberto por cima da home, fecha-o para se ver o login.
      navigator.popUntil((r) => r.isFirst);
    } catch (e, stack) {
      debugPrint('Falha ao eliminar conta: $e\n$stack');
      if (mounted) setState(() => _isUploading = false);
      _showMessage(
        'Não foi possível eliminar a conta. Tenta outra vez.',
        isError: true,
      );
    }
  }
}
