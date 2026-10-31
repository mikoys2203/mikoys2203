import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/fastfit_auth_shell.dart';
import '../../widgets/fastfit_motion.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final service = AuthService();
  String selectedRole = 'user';
  bool loading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  void notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 7)));
  }

  Future<void> register() async {
    if (loading || !formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      await service.register(
        name: nameController.text,
        email: emailController.text,
        password: passwordController.text,
        role: selectedRole,
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on ProfileSetupException {
      if (!mounted) return;
      // AuthGate shows CompleteProfileScreen rather than re-registering.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      notice(AuthErrorMessages.from(error));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FastFitAuthShell(
      title: 'Create your account',
      subtitle: 'Get started with better food and fitness insights.',
      showBack: true,
      form: Form(key: formKey, child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: nameController,
            enabled: !loading,
            textCapitalization: TextCapitalization.words,
            decoration: FastFitStyle.field('Full name', Icons.person_outline_rounded),
            validator: (v) => v == null || v.trim().isEmpty
              ? 'Full name is required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: emailController,
            enabled: !loading,
            keyboardType: TextInputType.emailAddress,
            decoration: FastFitStyle.field('Email address', Icons.alternate_email_rounded),
            validator: (v) => v == null ||
              !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())
              ? 'Enter a valid email address' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: passwordController,
            enabled: !loading,
            obscureText: !showPassword,
            decoration: FastFitStyle.field('Password', Icons.lock_outline_rounded,
              suffix: IconButton(
                tooltip: showPassword ? 'Hide password' : 'Show password',
                icon: Icon(showPassword ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                onPressed: () => setState(() => showPassword = !showPassword),
              )),
            validator: (v) => v == null || v.length < 6
              ? 'Password must have at least 6 characters' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: confirmController,
            enabled: !loading,
            obscureText: !showConfirmPassword,
            decoration: FastFitStyle.field('Confirm password', Icons.verified_user_outlined,
              suffix: IconButton(
                tooltip: showConfirmPassword ? 'Hide password' : 'Show password',
                icon: Icon(showConfirmPassword ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                onPressed: () => setState(() => showConfirmPassword = !showConfirmPassword),
              )),
            validator: (v) => v != passwordController.text
              ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: selectedRole,
            decoration: FastFitStyle.field('Account type', Icons.badge_outlined),
            items: const [
              DropdownMenuItem(value: 'user', child: Text('Normal user')),
              DropdownMenuItem(value: 'restaurant', child: Text('Restaurant representative')),
            ],
            onChanged: loading ? null : (value) {
              if (value != null) setState(() => selectedRole = value);
            },
          ),
          const SizedBox(height: 23),
          FastFitButton(label: 'Create account', icon: Icons.arrow_forward_rounded,
            loading: loading, fillWidth: true,
            onPressed: loading ? null : register),
          const SizedBox(height: 12),
          TextButton(
            onPressed: loading ? null : () => Navigator.maybePop(context),
            child: const Text('Already registered? Log in to finish setup'),
          ),
          const SizedBox(height: 5),
          const Text('Restaurant accounts require administrator approval.',
            style: TextStyle(color: FastFitStyle.muted, fontSize: 12),
            textAlign: TextAlign.center),
        ],
      )),
    );
  }
}
