import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../main.dart';
import '../services/push_service.dart';
import '../core/api_exception.dart';
import '../utils/ui_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;

  Future<void> submit() async {
    if (emailCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty) {
      UiUtils.showError(context, 'Please enter email and password');
      return;
    }

    setState(() => loading = true);

    try {
      final success = await AuthService.login(
        emailCtrl.text.trim(),
        passCtrl.text.trim(),
      );

      if (success && mounted) {
        // Start PushService in background - DON'T await it
        // This ensures the user is redirected even if Firebase fails
        PushService.init();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainHome()),
        );
      } else {
        if (mounted) UiUtils.showError(context, 'Login failed');
      }
    } on ApiException catch (e) {
      if (mounted) UiUtils.showError(context, e.message);
    } catch (e) {
      if (mounted) UiUtils.showError(context, 'An unexpected error occurred');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Driver Login',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: emailCtrl..text = 'shofer@e4.al',
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl..text = 'Saxyr@mailinator.com2026',
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : submit,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('LOGIN'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
