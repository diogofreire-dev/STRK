import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

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
    if (user != null) {
      await user.reload();
    }
    final refreshedUser = FirebaseAuth.instance.currentUser;
    if (!mounted) return;
    setState(() {
      _user = refreshedUser;
      _photoUrl = refreshedUser?.photoURL;
    });
  }

  Future<void> _pickProfilePhoto(ImageSource source) async {
    final file = await ProfileService.pickProfilePhoto(source: source);
    if (file == null) return;

    setState(() => _isUploading = true);

    try {
      final url = await ProfileService.uploadProfilePhoto(file);
      await ProfileService.saveProfilePhotoUrl(url);

      // Força atualização imediata com a URL nova
      if (mounted) {
        setState(() {
          _photoUrl = url;
          _isUploading = false;
        });
      }
    } catch (e) {
      _showMessage(
        'Não foi possível carregar a foto. Tenta novamente.',
        isError: true,
      );
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<ImageSource?> _showPhotoSourceDialog() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(
                    Icons.photo_camera_rounded,
                    color: Color(0xFFC8FF00),
                  ),
                  title: const Text('Câmara'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: Color(0xFFC8FF00),
                ),
                title: const Text('Galeria'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFFF3B30)
            : const Color(0xFF1A1A1A),
      ),
    );
  }

  Future<void> _confirmRemovePhoto() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: const Color(0xFF1A1A1A),
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
                      color: Color(0xFFE8E8E8),
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
                          onTap: () => Navigator.pop(context, false),
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
                          onTap: () => Navigator.pop(context, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF3B30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Remover',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFFFFFF),
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
        ) ??
        false;

    if (!confirmed) return;

    setState(() {
      _isUploading = true;
    });

    try {
      await ProfileService.removeProfilePhoto();
      if (mounted) {
        setState(() {
          _photoUrl = null;
        });
      }
      await _refreshUser();
      _showMessage('Foto removida com sucesso.');
    } catch (_) {
      _showMessage(
        'Não foi possível remover a foto. Tenta novamente.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _user?.displayName ?? 'Sem nome';
    final email = _user?.email ?? '';
    final photo = _photoUrl;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Perfil',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE8E8E8),
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 32),
              _buildProfileCard(name, email, photo),
              const SizedBox(height: 24),
              _buildSection('Conta', [
                _buildTile(
                  icon: Icons.photo_camera_outlined,
                  label: 'Foto de perfil',
                  value: photo == null ? 'Sem foto' : 'Alterar',
                  onTap: () async {
                    final source = await _showPhotoSourceDialog();
                    if (source != null) {
                      await _pickProfilePhoto(source);
                    }
                  },
                ),
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
                    valueColor: const Color(0xFFC8FF00),
                    onTap: () async {
                      await _user?.sendEmailVerification();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Email de verificação enviado!'),
                            backgroundColor: Color(0xFF1A1A1A),
                          ),
                        );
                      }
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
              const Spacer(),
              Center(
                child: Text(
                  'strk v1.0.0',
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color.fromRGBO(255, 255, 255, 0.15),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(String name, String email, String? photo) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final source = await _showPhotoSourceDialog();
              if (source != null) {
                await _pickProfilePhoto(source);
              }
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
                              color: Color(0xFFC8FF00),
                            ),
                          ),
                        )
                      : null,
                ),
                if (_isUploading)
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(0, 0, 0, 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Color(0xFFC8FF00),
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
                      color: const Color(0xFF0D0D0D),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFC8FF00),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      _isUploading
                          ? Icons.hourglass_top_rounded
                          : Icons.photo_camera_rounded,
                      size: 16,
                      color: const Color(0xFFC8FF00),
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
                    color: Color(0xFFE8E8E8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color.fromRGBO(255, 255, 255, 0.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color.fromRGBO(255, 255, 255, 0.3),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
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
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: const Color.fromRGBO(255, 255, 255, 0.05),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: const Color.fromRGBO(255, 255, 255, 0.35),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color.fromRGBO(255, 255, 255, 0.7),
                ),
              ),
            ),
            if (value != null)
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color:
                      valueColor ?? const Color.fromRGBO(255, 255, 255, 0.25),
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: const Color.fromRGBO(255, 255, 255, 0.15),
              ),
          ],
        ),
      ),
    );
  }

  void _editName(BuildContext context) {
    final controller = TextEditingController(text: _user?.displayName ?? '');
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Editar nome',
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
                style: const TextStyle(color: Color(0xFFE8E8E8), fontSize: 15),
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
                      onTap: () async {
                        final newName = controller.text.trim();
                        if (newName.isEmpty) return;
                        await ProfileService.updateDisplayName(newName);
                        _refreshUser();
                        if (context.mounted) {
                          Navigator.pop(context);
                          _showMessage('Nome atualizado com sucesso.');
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
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
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
                  color: Color(0xFFE8E8E8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Os teus hábitos ficam guardados na cloud.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: const Color.fromRGBO(255, 255, 255, 0.35),
                ),
              ),
              const SizedBox(height: 24),
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
                      onTap: () async {
                        Navigator.pop(context);
                        await FirebaseAuth.instance.signOut();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(255, 59, 48, 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color.fromRGBO(255, 59, 48, 0.3),
                          ),
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
