import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'package:splitup/theme/app_colors.dart';
import 'package:splitup/pages/auth/auth_gate.dart';

const bool kDevHudEnabled = false;

final ValueNotifier<String> _devHudLast = ValueNotifier<String>('none');

void devHudAction(String value) {
  if (!kDevHudEnabled) return;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_devHudLast.value == value) return;
    _devHudLast.value = value;
  });
}

Widget wrapWithDevHud(Widget child) {
  if (!kDevHudEnabled) return child;
  return Stack(children: [child, const _DevHudOverlay()]);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      home: const AuthGate(),
      builder: (context, child) => wrapWithDevHud(child ?? const SizedBox()),
    );
  }
}

class _DevHudOverlay extends StatefulWidget {
  const _DevHudOverlay();

  @override
  State<_DevHudOverlay> createState() => _DevHudOverlayState();
}

class _DevHudOverlayState extends State<_DevHudOverlay> {
  StreamSubscription<User?>? _sub;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _sub = FirebaseAuth.instance.authStateChanges().listen((u) {
      if (!mounted) return;
      setState(() => _user = u);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  String _routeName(BuildContext context) {
    final r = ModalRoute.of(context);
    return r?.settings.name ?? r.runtimeType.toString();
  }

  @override
  Widget build(BuildContext context) {
    final u = _user;
    final lines = <String>[
      'AUTH: ${u == null ? "logged out" : "logged in"}',
      'uid: ${u?.uid ?? "-"}',
      'anon: ${u?.isAnonymous ?? "-"}',
      'email: ${u?.email ?? "-"}',
      'route: ${_routeName(context)}',
    ];

    return IgnorePointer(
      child: Align(
        alignment: Alignment.topLeft,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: ValueListenableBuilder<String>(
              valueListenable: _devHudLast,
              builder: (context, last, _) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      height: 1.2,
                      fontFamily: 'monospace',
                    ),
                    child: Text('${lines.join('\n')}\nlast: $last'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
