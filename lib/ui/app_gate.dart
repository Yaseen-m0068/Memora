import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'welcome_screen.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class AppGate extends StatelessWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _decide(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data!;
      },
    );
  }

  Future<Widget> _decide() async {
    final prefs = await SharedPreferences.getInstance();
    final welcomeSeen = prefs.getBool('welcome_seen') ?? false;
    final user = FirebaseAuth.instance.currentUser;

    if (!welcomeSeen) {
      return const WelcomeScreen();
    }

    if (user == null) {
      return const LoginScreen();
    }

    return const HomeScreen();
  }
}
