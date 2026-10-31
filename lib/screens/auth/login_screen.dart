import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/fastfit_auth_shell.dart';
import '../../widgets/fastfit_motion.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final service = AuthService();
  bool loading = false;
  bool showPassword = false;

  void notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6)));
  }

  Future<void> login() async {
    if (loading || !formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      await service.login(emailController.text, passwordController.text);
      // Firebase AuthGate handles navigation.
    } catch (error) {
      notice(AuthErrorMessages.from(error));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> resetPassword() async {
    if (loading) return;
    final email = emailController.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      notice('Enter your email address first, then select Forgot password.');
      return;
    }
    setState(() => loading = true);
    try {
      await service.sendPasswordReset(email);
      notice('If an account exists, a password reset email has been sent.');
    } catch (error) {
      notice(AuthErrorMessages.from(error));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FastFitAuthShell(
      title: 'Welcome back!',
      subtitle: 'Log in to continue your FastFit journey.',
      form: Form(
        key: formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextFormField(
            controller: emailController,
            enabled: !loading,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: FastFitStyle.field('Email address', Icons.alternate_email_rounded,
              hint: 'you@example.com'),
            validator: (v) => v == null ||
                !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())
                ? 'Enter a valid email address' : null,
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: passwordController,
            enabled: !loading,
            obscureText: !showPassword,
            autofillHints: const [AutofillHints.password],
            decoration: FastFitStyle.field('Password', Icons.lock_outline_rounded,
              suffix: IconButton(
                tooltip: showPassword ? 'Hide password' : 'Show password',
                onPressed: () => setState(() => showPassword = !showPassword),
                icon: Icon(showPassword ? Icons.visibility_rounded : Icons.visibility_off_rounded),
              )),
            validator: (v) => v == null || v.isEmpty ? 'Password is required' : null,
            onFieldSubmitted: (_) => login(),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: loading ? null : resetPassword,
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 13),
          FastFitButton(label: 'Log in', icon: Icons.arrow_forward_rounded,
            onPressed: loading ? null : login,
            fillWidth: true, loading: loading),
          const SizedBox(height: 19),
          Row(children: [
            const Expanded(child: Divider(color: FastFitStyle.line)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11),
              child: Text('New to FastFit?', style: TextStyle(
                fontSize: 12, color: Colors.grey.shade600)),
            ),
            const Expanded(child: Divider(color: FastFitStyle.line)),
          ]),
          const SizedBox(height: 16),
          FastFitButton(
            label: 'Create an account', outlined: true,
            onPressed: loading ? null : () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RegisterScreen())),
            fillWidth: true,
          ),
        ]),
      ),
    );
  }
}
