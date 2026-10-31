import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/fastfit_auth_shell.dart';
import '../../widgets/fastfit_motion.dart';

/// Recovery for an existing Auth account with no users/{uid} profile.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});
  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  String role = 'user';
  bool working = false;
  String? saveError;

  @override
  void dispose() { name.dispose(); super.dispose(); }

  Future<void> complete() async {
    if (working || !formKey.currentState!.validate()) return;
    setState(() { working = true; saveError = null; });
    try {
      await AuthService().completeMissingProfile(name: name.text, role: role);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully.')),
      );
    } catch (error) {
      if (mounted) setState(() => saveError = AuthErrorMessages.from(error));
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FastFitAuthShell(
      title: 'Almost there!',
      subtitle: 'Your account is ready. Finish your profile to continue.',
      form: Form(key: formKey, child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: FastFitStyle.softRed,
              borderRadius: BorderRadius.circular(15)),
            child: const Row(children: [
              Icon(Icons.check_circle_outline_rounded, color: FastFitStyle.red),
              SizedBox(width: 10),
              Expanded(child: Text('You don\'t need to register again. Just add your details.',
                style: TextStyle(fontSize: 13, color: FastFitStyle.ink))),
            ]),
          ),
          if (saveError != null) ...[
            const SizedBox(height: 14),
            Text(saveError!, style: const TextStyle(color: FastFitStyle.deepRed)),
          ],
          const SizedBox(height: 20),
          TextFormField(
            controller: name,
            enabled: !working,
            decoration: FastFitStyle.field('Full name', Icons.person_outline_rounded),
            validator: (value) => value == null || value.trim().isEmpty
              ? 'Enter your full name' : null,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: role,
            decoration: FastFitStyle.field('Account type', Icons.badge_outlined),
            items: const [
              DropdownMenuItem(value: 'user', child: Text('Normal user')),
              DropdownMenuItem(value: 'restaurant', child: Text('Restaurant representative')),
            ],
            onChanged: working ? null : (value) {
              if (value != null) setState(() => role = value);
            },
          ),
          const SizedBox(height: 22),
          FastFitButton(label: 'Complete profile', icon: Icons.check_rounded,
            loading: working, fillWidth: true,
            onPressed: working ? null : complete),
          const SizedBox(height: 10),
          TextButton(
            onPressed: working ? null : () => FirebaseAuth.instance.signOut(),
            child: const Text('Log out / use another account'),
          ),
          const SizedBox(height: 4),
          const Text('If you have trouble saving, try again later or contact FastFit support.',
            textAlign: TextAlign.center,
            style: TextStyle(color: FastFitStyle.muted, fontSize: 12)),
        ],
      )),
    );
  }
}
