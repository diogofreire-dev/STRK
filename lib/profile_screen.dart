import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'profile_service.dart';
import 'badges_screen.dart';
import 'habit.dart';
import 'strk_mascot.dart'; // ← novo

const _kOrange = Color(0xFFFF6B00);
const _kBg = Color(0xFF0D0D0D);
const _kSurf = Color(0xFF1A1A1A);
const _kText = Color(0xFFE8E8E8);

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

  @override
  void initState() {
    super.initState();
    _refreshUser();
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

  // ── Mood derivado dos hábitos ─────────────────────────────────────────────
  MascotMood get _mood {
    final habits = widget.habits;
    if (habits.isEmpty) return MascotMood.idle;
    final allDone = habits.every((h) => h.completedToday);
    if (allDone) return MascotMood.celebrating;
    final anyAtRisk = habits.any((h) => h.streak > 0 && !h.completedToday);
    if (anyAtRisk) return MascotMood.encouraging;
    return MascotMood.idle;
  }

  String get _moodMessage {
    final name = _user?.displayName?.split(' ').first ?? '';
    final greeting = name.isNotEmpty ? ', $name' : '';
    switch (_mood) {
      case MascotMood.celebrating:
        return 'Dia perfeito$greeting! 🔥';
      case MascotMood.encouraging:
        return 'Ainda dá tempo$greeting! 💪';
      case MascotMood.idle:
        final badges = computeBadgesResolved(widget.habits);
        final count = badges.where((b) => b.unlocked).length;
        return '$count conquistas desbloqueadas 🏆';
      case MascotMood.sleeping:
        return 'Volta em breve$greeting 😴';
    }
  }

  // ── Photo helpers ─────────────────────────────────────────────────────────
  Future<void> _pickProfilePhoto(ImageSource source) async {
    final file = await ProfileService.pickProfilePhoto(source: source);
    if (file == null) return;
    setState(() => _isUploading = true);
    try {
      final url = await ProfileService.uploadProfilePhoto(file);
      await ProfileService.saveProfilePhotoUrl(url);
      if (mounted)
        setState(() {
          _photoUrl = url;
          _isUploading = false;
        });
    } catch (_) {
      _showMessage('Não foi possível carregar a foto.', isError: true);
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<ImageSource?> _showPhotoSourceDialog() =>
      showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: const Color(0xFF121212),
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
                  leading: const Icon(
                    Icons.photo_camera_rounded,
                    color: _kOrange,
                  ),
                  title: const Text('Câmara'),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: _kOrange,
                ),
                title: const Text('Galeria'),
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
        backgroundColor: isError ? const Color(0xFFFF3B30) : _kSurf,
      ),
    );
  }

  Future<void> _confirmRemovePhoto() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: _kSurf,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Remover foto de perfil?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'A foto será removida do teu perfil e da cloud.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFFBEBEBE)),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx, false),
                          child: _dialogBtn(
                            'Cancelar',
                            const Color(0xFF2C2C2C),
                            const Color(0xFF888888),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx, true),
                          child: _dialogBtn(
                            'Remover',
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final name = _user?.displayName ?? 'Sem nome';
    final email = _user?.email ?? '';
    final photo = _photoUrl;

    final badges = computeBadgesResolved(widget.habits);
    final unlockedBadges = badges.where((b) => b.unlocked).toList();
    final unlockedCount = unlockedBadges.length;
    final totalCount = badges.length;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Logo ────────────────────────────────────────────────────
              SvgPicture.asset('assets/images/strk_logo.svg', height: 22),
              const SizedBox(height: 20),

              const Text(
                'Perfil',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _kText,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 20),

              // ── Mascote centrada ─────────────────────────────────────────
              _buildMascotSection(),
              const SizedBox(height: 20),

              _buildProfileCard(name, email, photo),
              const SizedBox(height: 20),

              // ── Conquistas ───────────────────────────────────────────────
              if (widget.habits.isNotEmpty) ...[
                _buildBadgesSection(
                  unlockedBadges,
                  unlockedCount,
                  totalCount,
                  badges,
                ),
                const SizedBox(height: 20),
              ],

              _buildSection('Conta', [
                if (photo != null)
                  _buildTile(
                    icon: Icons.delete_outline,
                    label: 'Remover foto',
                    value: 'Eliminar',
                    valueColor: const Color(0xFFFF3B30),
                    onTap: _confirmRemovePhoto,
                  ),
                _buildTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Nome',
                  value: name,
                  onTap: () => _editName(context),
                ),
                _buildTile(
                  icon: Icons.mail_outline_rounded,
                  label: 'Email',
                  value: email,
                ),
                if (_user?.emailVerified == false)
                  _buildTile(
                    icon: Icons.verified_outlined,
                    label: 'Email não verificado',
                    value: 'Reenviar email',
                    valueColor: _kOrange,
                    onTap: () async {
                      await _user?.sendEmailVerification();
                      if (context.mounted)
                        _showMessage('Email de verificação enviado!');
                    },
                  ),
              ]),
              const SizedBox(height: 16),
              _buildSection('Sessão', [
                _buildTile(
                  icon: Icons.logout_rounded,
                  label: 'Terminar sessão',
                  valueColor: const Color(0xFFFF3B30),
                  onTap: () => _confirmLogout(context),
                ),
              ]),
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  'strk v1.0.0',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0x26FFFFFF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Mascote + bolha no topo do perfil ─────────────────────────────────────
  Widget _buildMascotSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: _kSurf,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          StrkMascot(mood: _mood, size: 72),
          const SizedBox(width: 14),
          Expanded(
            child: MascotBubble(mood: _mood, customMessage: _moodMessage),
          ),
        ],
      ),
    );
  }

  // ── Badges section ────────────────────────────────────────────────────────
  Widget _buildBadgesSection(
    List<HabitBadge> unlockedBadges,
    int unlockedCount,
    int totalCount,
    List<HabitBadge> allBadges,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurf,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CONQUISTAS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0x4DFFFFFF),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$unlockedCount',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _kText,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: ' / $totalCount',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0x4DFFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _kOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _kOrange.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Color(0xFFFFD60A),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${((unlockedCount / totalCount) * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: totalCount == 0 ? 0 : unlockedCount / totalCount,
              minHeight: 5,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(_kOrange),
            ),
          ),
          const SizedBox(height: 20),
          _buildBadgeGrid(allBadges),
          if (unlockedBadges.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'ÚLTIMAS CONQUISTAS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0x33FFFFFF),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            _buildRecentBadges(unlockedBadges),
          ],
        ],
      ),
    );
  }

  Widget _buildBadgeGrid(List<HabitBadge> badges) {
    const iconSize = 36.0;
    const spacing = 8.0;
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: badges.map((badge) {
        return Tooltip(
          message: badge.unlocked ? badge.title : '${badge.title} (bloqueado)',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: badge.unlocked
                  ? badge.color.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.05),
              border: Border.all(
                color: badge.unlocked
                    ? badge.color.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.08),
                width: 1.5,
              ),
            ),
            child: Icon(
              badge.unlocked ? badge.icon : Icons.lock_outline_rounded,
              size: 16,
              color: badge.unlocked
                  ? badge.color
                  : Colors.white.withValues(alpha: 0.15),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentBadges(List<HabitBadge> unlocked) {
    final recent = unlocked.reversed.take(3).toList();
    return Row(
      children: recent.map((badge) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: badge == recent.last ? 0 : 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: badge.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: badge.color.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(badge.icon, size: 14, color: badge.color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    badge.title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: badge.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Profile card ──────────────────────────────────────────────────────────
  Widget _buildProfileCard(String name, String email, String? photo) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurf,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final source = await _showPhotoSourceDialog();
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
                    color: const Color(0xFF2C2C2C),
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
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: _kOrange,
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
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: _kOrange,
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
                      color: _kBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _kOrange, width: 1.5),
                    ),
                    child: Icon(
                      _isUploading
                          ? Icons.hourglass_top_rounded
                          : Icons.photo_camera_rounded,
                      size: 16,
                      color: _kOrange,
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
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _kText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0x59FFFFFF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section / Tile ────────────────────────────────────────────────────────
  Widget _buildSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0x4DFFFFFF),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: _kSurf,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String label,
    String? value,
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0x0DFFFFFF), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white38),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xB3FFFFFF),
                ),
              ),
            ),
            if (value != null)
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: valueColor ?? Colors.white24,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Color(0x26FFFFFF),
              ),
          ],
        ),
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────
  void _editName(BuildContext context) {
    final controller = TextEditingController(text: _user?.displayName ?? '');
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _kSurf,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Editar nome',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kText,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: _kText, fontSize: 15),
                cursorColor: _kOrange,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF2C2C2C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kOrange, width: 1),
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
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: _dialogBtn(
                        'Cancelar',
                        const Color(0xFF2C2C2C),
                        const Color(0xFF888888),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
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
                      child: _dialogBtn('Guardar', _kOrange, Colors.white),
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

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _kSurf,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Terminar sessão?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Os teus hábitos ficam guardados na cloud.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0x59FFFFFF)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: _dialogBtn(
                        'Cancelar',
                        const Color(0xFF2C2C2C),
                        const Color(0xFF888888),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(ctx);
                        await FirebaseAuth.instance.signOut();
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
}
