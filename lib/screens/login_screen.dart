import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../main.dart';
import '../services/push_service.dart';
import '../core/api_exception.dart';
import '../utils/ui_utils.dart';
import '../utils/storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;
  bool rememberMe = false;

  final Color goldColor = const Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _checkRememberedCredentials();
  }

  Future<void> _checkRememberedCredentials() async {
    final creds = await Storage.getSavedCredentials();
    if (creds['isRemembered'] == 'true') {
      setState(() {
        emailCtrl.text = creds['email'] ?? '';
        passCtrl.text = creds['password'] ?? '';
        rememberMe = true;
      });
    }
  }

  Future<void> submit() async {
    if (emailCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty) {
      UiUtils.showError(context, 'Ju lutem shënoni emailin dhe fjalëkalimin');
      return;
    }

    setState(() => loading = true);

    try {
      final success = await AuthService.login(
        emailCtrl.text.trim(),
        passCtrl.text.trim(),
      );

      if (success && mounted) {
        if (rememberMe) {
          await Storage.saveCredentials(emailCtrl.text.trim(), passCtrl.text.trim());
        } else {
          await Storage.clearSavedCredentials();
        }

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
      if (mounted) UiUtils.showError(context, 'Një gabim i papritur ndodhi');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _launchRegisterUrl() async {
    final Uri url = Uri.parse('https://m.classtours.al/register');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) UiUtils.showError(context, 'Nuk mund të hapej faqja e regjistrimit');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A1A), // Dark Black
              Color(0xFF2D2D2D), // Midnight Grey
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Hero(
                    tag: 'logo',
                    child: Image.asset('assets/images/taxy.png', height: 120),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Mirësevini në Class Tours',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                  ),
                  const SizedBox(height: 40),
                  
                  // INPUT FIELDS
                  _buildTextField(
                    controller: emailCtrl,
                    label: 'Email',
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: passCtrl,
                    label: 'Fjalëkalimi',
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  
                  // REMEMBER ME
                  Theme(
                    data: ThemeData(unselectedWidgetColor: Colors.white54),
                    child: Row(
                      children: [
                        Checkbox(
                          value: rememberMe,
                          activeColor: goldColor,
                          checkColor: Colors.black,
                          onChanged: (v) => setState(() => rememberMe = v!),
                        ),
                        const Text('Më mbaj mend', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  
                  // LOGIN BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: loading ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: goldColor,
                        foregroundColor: Colors.black,
                        elevation: 5,
                        shadowColor: goldColor.withOpacity(0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text(
                              'VASHDO',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // REGISTER INFO
                  Text(
                    'Nuk keni një llogari?',
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                  TextButton(
                    onPressed: _launchRegisterUrl,
                    child: Text(
                      'REGJISTROHUNI KËTU',
                      style: TextStyle(
                        color: goldColor,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Kontaktoni administratorin për të aktivizuar llogarinë tuaj.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: goldColor),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: goldColor, width: 1.5),
        ),
      ),
    );
  }
}
