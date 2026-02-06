import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:splitup/pages/auth/auth_choice_page.dart';
import 'package:splitup/pages/home/home.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final currentUser = FirebaseAuth.instance.currentUser;
        final user = snapshot.data ?? currentUser;

        if (snapshot.connectionState == ConnectionState.waiting &&
            user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (user == null) {
          return const AuthChoicePage();
        }

        return const HomePage();
      },
    );
  }
}
