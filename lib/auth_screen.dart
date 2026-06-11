import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'theme_provider.dart';
import 'strk_logo.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;
  String? _success;

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });
    if (!_isLogin && _passwordController.text != _confirmController.text) {
      setState(() {
        _error = 'As passwords não coincidem.';
        _isLoading = false;
      });
      return;
    }
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        await cred.user?.sendEmailVerification();
        setState(() {
          _success = 'Conta criada! Verifica o teu email.';
          _isLogin = true;
          _isLoading = false;
        });
        return;
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(e.code));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      } else {
        final googleUser = await GoogleSignIn.instance.authenticate();
        final idToken = googleUser.authentication.idToken;
        if (idToken == null) {
          setState(() => _error = 'Não foi possível autenticar com o Google.');
          return;
        }
        await FirebaseAuth.instance.signInWithCredential(
          GoogleAuthProvider.credential(idToken: idToken),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(e.code));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Nenhuma conta com este email.';
      case 'wrong-password':
        return 'Password incorreta.';
      case 'email-already-in-use':
        return 'Este email já está registado.';
      case 'weak-password':
        return 'A password deve ter pelo menos 6 caracteres.';
      case 'invalid-email':
        return 'Email inválido.';
      case 'invalid-credential':
        return 'Email ou password incorretos.';
      default:
        return 'Ocorreu um erro. Tenta novamente.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProviderScope.of(context);
    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const StrkLogo(height: 28),
              const SizedBox(height: 48),
              _buildTitle(theme),
              const SizedBox(height: 32),
              _buildField(
                theme,
                controller: _emailController,
                hint: 'Email',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _buildField(
                theme,
                controller: _passwordController,
                hint: 'Password',
                icon: Icons.lock_outline_rounded,
                obscure: _obscurePassword,
                toggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              if (!_isLogin) ...[
                const SizedBox(height: 12),
                _buildField(
                  theme,
                  controller: _confirmController,
                  hint: 'Confirmar password',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscureConfirm,
                  toggleObscure: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                _buildMessage(_error!, isError: true, theme: theme),
              ],
              if (_success != null) ...[
                const SizedBox(height: 12),
                _buildMessage(_success!, isError: false, theme: theme),
              ],
              const SizedBox(height: 24),
              _buildSubmitButton(theme),
              const SizedBox(height: 16),
              _buildDivider(theme),
              const SizedBox(height: 16),
              _buildGoogleButton(theme),
              const SizedBox(height: 24),
              _buildToggle(theme),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(ThemeProvider theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        _isLogin ? 'Bem-vindo\nde volta.' : 'Cria a tua\nconta.',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: theme.textPrimary,
          letterSpacing: -1.5,
          height: 1.1,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        _isLogin
            ? 'Inicia sessão para continuares os teus hábitos.'
            : 'Regista-te para começares a construir os teus hábitos.',
        style: TextStyle(fontSize: 13, color: theme.textSecondary, height: 1.4),
      ),
    ],
  );

  Widget _buildField(
    ThemeProvider theme, {
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    VoidCallback? toggleObscure,
  }) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    obscureText: obscure,
    style: TextStyle(color: theme.textPrimary, fontSize: 15),
    cursorColor: theme.accent,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: theme.textHint),
      prefixIcon: Icon(icon, color: theme.textHint, size: 18),
      suffixIcon: toggleObscure != null
          ? GestureDetector(
              onTap: toggleObscure,
              child: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: theme.textHint,
                size: 18,
              ),
            )
          : null,
      filled: true,
      fillColor: theme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.accent, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );

  Widget _buildMessage(
    String message, {
    required bool isError,
    required ThemeProvider theme,
  }) {
    final color = isError ? const Color(0xFFFF3B30) : theme.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(ThemeProvider theme) => GestureDetector(
    onTap: _isLoading ? null : _submit,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.accent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: _isLoading
          ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          : Text(
              _isLogin ? 'Entrar' : 'Criar conta',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
    ),
  );

  Widget _buildDivider(ThemeProvider theme) => Row(
    children: [
      Expanded(child: Divider(color: theme.divider)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          'ou',
          style: TextStyle(color: theme.textHint, fontSize: 12),
        ),
      ),
      Expanded(child: Divider(color: theme.divider)),
    ],
  );

  Widget _buildGoogleButton(ThemeProvider theme) => GestureDetector(
    onTap: _isLoading ? null : _signInWithGoogle,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'G',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _isLogin ? 'Entrar com Google' : 'Registar com Google',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildToggle(ThemeProvider theme) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        _isLogin ? 'Não tens conta? ' : 'Já tens conta? ',
        style: TextStyle(color: theme.textSecondary, fontSize: 13),
      ),
      GestureDetector(
        onTap: () => setState(() {
          _isLogin = !_isLogin;
          _error = null;
          _success = null;
        }),
        child: Text(
          _isLogin ? 'Regista-te' : 'Inicia sessão',
          style: TextStyle(
            color: theme.accent,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}
