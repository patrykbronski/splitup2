import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../groups/group_service.dart';

class JoinByCodePage extends StatefulWidget {
  const JoinByCodePage({super.key});

  @override
  State<JoinByCodePage> createState() => _JoinByCodePageState();
}

class _JoinByCodePageState extends State<JoinByCodePage> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  String _normalize(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    return cleaned.length <= 4 ? cleaned : cleaned.substring(0, 4);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _join() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack('Musisz być zalogowany');
      return;
    }

    final code = _normalize(_codeCtrl.text.trim());
    if (code.length != 4) {
      _showSnack('Kod musi mieć 4 znaki');
      return;
    }

    setState(() => _loading = true);
    try {
      await GroupService().joinByCode(code: code, userId: user.uid);

      if (!mounted) return;
      _showSnack('Dołączono do grupy');
      Navigator.of(context).pop();
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Dołącz do grupy')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Wpisz kod grupy',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 240,
                  child: TextField(
                    controller: _codeCtrl,
                    enabled: !_loading,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    keyboardType: TextInputType.text,
                    onChanged: (v) {
                      final normalized = _normalize(v);
                      if (normalized != v) {
                        _codeCtrl.value = TextEditingValue(
                          text: normalized,
                          selection: TextSelection.collapsed(
                            offset: normalized.length,
                          ),
                        );
                      }
                    },
                    onSubmitted: (_) => _join(),
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: 'AB12',
                      filled: true,
                      fillColor: Color(0xFFD9D9D9),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.zero,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: 240,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _join,
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
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : const Text(
                            'DOŁĄCZ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Kod ma 4 znaki: litery i cyfry.',
                  style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
