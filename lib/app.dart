import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:carbon_emmision_app/providers/auth_provider.dart';
import 'package:carbon_emmision_app/providers/wallet_provider.dart';
import 'package:carbon_emmision_app/screens/splash_screen.dart';
import 'package:carbon_emmision_app/theme/app_theme.dart';

class EcoWalletApp extends StatelessWidget {
  const EcoWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
          create: (_) => WalletProvider(),
          update: (_, auth, wallet) {
            final provider = wallet ?? WalletProvider();
            provider.bindUser(auth.uid);
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'EcoWallet',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
