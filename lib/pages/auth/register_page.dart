import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../home/home.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bankCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final pass2 = _pass2Ctrl.text;
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final bank = _bankCtrl.text.trim();

    if (email.isEmpty ||
        pass.isEmpty ||
        pass2.isEmpty ||
        name.isEmpty ||
        phone.isEmpty ||
        bank.isEmpty) {
      _showSnack('Uzupełnij wszystkie pola');
      return;
    }

    if (pass.length < 6) {
      _showSnack('Hasło musi mieć minimum 6 znaków');
      return;
    }

    if (pass != pass2) {
      _showSnack('Hasła nie są takie same');
      return;
    }

    setState(() => _loading = true);

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      final user = cred.user;
      if (user == null) {
        throw Exception('Nie udało się utworzyć konta (brak user)');
      }

      // Ustawianie displayName w Auth
      await user.updateDisplayName(name);
      await user.reload();

      final refreshed = FirebaseAuth.instance.currentUser;
      final uid = refreshed?.uid ?? user.uid;

      // Zapis do Firestore - docelowe pola
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': email,
        'displayName': name,
        'name': name,
        'phone': phone,
        'bankAccount': bank,
        'photoUrl': refreshed?.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _showSnack(_mapAuthError(e));
    } catch (e) {
      _showSnack('Błąd rejestracji: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Ten e-mail jest już zajęty';
      case 'invalid-email':
        return 'Niepoprawny format e-mail';
      case 'weak-password':
        return 'Hasło jest zbyt słabe';
      case 'operation-not-allowed':
        return 'Rejestracja e-mail/hasło nie jest włączona w Firebase';
      default:
        return 'Błąd rejestracji (${e.code})';
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              left: 16,
              top: 16,
              child: Text(
                'splitUp',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'rejestracja',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _LabeledField(
                      label: 'e-mail',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_loading,
                    ),
                    const SizedBox(height: 12),
                    _LabeledField(
                      label: 'hasło',
                      controller: _passCtrl,
                      keyboardType: TextInputType.visiblePassword,
                      enabled: !_loading,
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    _LabeledField(
                      label: 'potwierdź hasło',
                      controller: _pass2Ctrl,
                      keyboardType: TextInputType.visiblePassword,
                      enabled: !_loading,
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    _LabeledField(
                      label: 'imię/ksywa',
                      controller: _nameCtrl,
                      keyboardType: TextInputType.name,
                      enabled: !_loading,
                    ),
                    const SizedBox(height: 12),
                    _LabeledField(
                      label: 'nr tel.',
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      enabled: !_loading,
                    ),
                    const SizedBox(height: 12),
                    _LabeledField(
                      label: 'nr konta',
                      controller: _bankCtrl,
                      keyboardType: TextInputType.number,
                      enabled: !_loading,
                      onSubmitted: (_) => _register(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 240,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD9D9D9),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                ),
                              )
                            : const Text(
                                'ZAREJESTRUJ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text(
                        'Wróć',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool enabled;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;

  const _LabeledField({
    required this.label,
    required this.controller,
    required this.keyboardType,
    required this.enabled,
    this.obscureText = false,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 115,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 38,
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              enabled: enabled,
              obscureText: obscureText,
              textInputAction: onSubmitted != null
                  ? TextInputAction.done
                  : TextInputAction.next,
              onSubmitted: onSubmitted,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Color(0xFFD9D9D9),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.zero,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
