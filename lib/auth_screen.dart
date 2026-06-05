import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
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

    if (!_isLogin &&
        _passwordController.text != _confirmPasswordController.text) {
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
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );
        await credential.user?.sendEmailVerification();
        setState(() {
          _success =
              'Conta criada! Verifica o teu email para ativares a conta.';
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
        final googleProvider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        final googleUser = await GoogleSignIn.instance.authenticate();
        final idToken = googleUser.authentication.idToken;
        if (idToken == null) {
          setState(() => _error = 'Não foi possível autenticar com o Google.');
          return;
        }

        final credential = GoogleAuthProvider.credential(idToken: idToken);
        await FirebaseAuth.instance.signInWithCredential(credential);
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
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              _buildLogo(),
              const SizedBox(height: 48),
              _buildTitle(),
              const SizedBox(height: 32),
              _buildEmailField(),
              const SizedBox(height: 12),
              _buildPasswordField(),
              if (!_isLogin) ...[
                const SizedBox(height: 12),
                _buildConfirmPasswordField(),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                _buildMessage(_error!, isError: true),
              ],
              if (_success != null) ...[
                const SizedBox(height: 12),
                _buildMessage(_success!, isError: false),
              ],
              const SizedBox(height: 24),
              _buildSubmitButton(),
              const SizedBox(height: 16),
              _buildDivider(),
              const SizedBox(height: 16),
              _buildGoogleButton(),
              const SizedBox(height: 24),
              _buildToggle(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFC8FF00),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.bar_chart_rounded,
            color: Color(0xFF0D0D0D),
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'strk',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFFE8E8E8),
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isLogin ? 'Bem-vindo\nde volta.' : 'Cria a tua\nconta.',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Color(0xFFE8E8E8),
            letterSpacing: -1.5,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin
              ? 'Inicia sessão para continuares os teus hábitos.'
              : 'Regista-te para começares a construir os teus hábitos.',
          style: TextStyle(
            fontSize: 13,
            color: const Color.fromRGBO(255, 255, 255, 0.35),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return _buildField(
      controller: _emailController,
      hint: 'Email',
      icon: Icons.mail_outline_rounded,
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildPasswordField() {
    return _buildField(
      controller: _passwordController,
      hint: 'Password',
      icon: Icons.lock_outline_rounded,
      obscure: _obscurePassword,
      toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
    );
  }

  Widget _buildConfirmPasswordField() {
    return _buildField(
      controller: _confirmPasswordController,
      hint: 'Confirmar password',
      icon: Icons.lock_outline_rounded,
      obscure: _obscureConfirm,
      toggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    VoidCallback? toggleObscure,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(color: Color(0xFFE8E8E8), fontSize: 15),
      cursorColor: const Color(0xFFC8FF00),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: const Color.fromRGBO(255, 255, 255, 0.2)),
        prefixIcon: Icon(
          icon,
          color: const Color.fromRGBO(255, 255, 255, 0.2),
          size: 18,
        ),
        suffixIcon: toggleObscure != null
            ? GestureDetector(
                onTap: toggleObscure,
                child: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color.fromRGBO(255, 255, 255, 0.2),
                  size: 18,
                ),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFC8FF00), width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildMessage(String message, {required bool isError}) {
    final color = isError ? const Color(0xFFFF3B30) : const Color(0xFFC8FF00);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha((0.3 * 255).round())),
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

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _submit,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFC8FF00),
          borderRadius: BorderRadius.circular(14),
        ),
        child: _isLoading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF0D0D0D),
                  ),
                ),
              )
            : Text(
                _isLogin ? 'Entrar' : 'Criar conta',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D0D0D),
                  letterSpacing: -0.3,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: const Color.fromRGBO(255, 255, 255, 0.1)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'ou',
            style: TextStyle(
              color: const Color.fromRGBO(255, 255, 255, 0.25),
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: const Color.fromRGBO(255, 255, 255, 0.1)),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _signInWithGoogle,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: const Text(
                'G',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFE8E8E8),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _isLogin ? 'Entrar com Google' : 'Registar com Google',
              style: const TextStyle(
                color: Color(0xFFE8E8E8),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? 'Não tens conta? ' : 'Já tens conta? ',
          style: TextStyle(
            color: const Color.fromRGBO(255, 255, 255, 0.3),
            fontSize: 13,
          ),
        ),
        GestureDetector(
          onTap: () => setState(() {
            _isLogin = !_isLogin;
            _error = null;
            _success = null;
          }),
          child: Text(
            _isLogin ? 'Regista-te' : 'Inicia sessão',
            style: const TextStyle(
              color: Color(0xFFC8FF00),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
