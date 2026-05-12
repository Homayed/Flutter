import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:carbon_emmision_app/home_screen.dart';
import 'package:carbon_emmision_app/providers/auth_provider.dart';
import 'package:carbon_emmision_app/services/firebase_connection.dart';
import 'package:carbon_emmision_app/sign_in_screen.dart';
import 'package:carbon_emmision_app/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => auth.isAuthenticated ? const HomeScreen() : const SignInScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusText = FirebaseConnection.isEnabled
        ? 'Firebase connected. Loading your EcoWallet data.'
        : 'Prototype mode. Configure Firebase to store live data.';

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.background, AppTheme.primaryDeep],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.14),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppTheme.primary.withOpacity(0.45)),
              ),
              child: const Center(
                child: Text('🌍', style: TextStyle(fontSize: 44)),
              ),
            ),
            const SizedBox(height: 24),
            Text('EcoWallet', style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 8),
            const Text(
              'Track money. Estimate carbon. Build greener habits.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 38),
              child: Text(
                statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.35),
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
