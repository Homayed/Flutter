import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/firebase_connection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF07140D),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await _initializeFirebaseIfConfigured();

  runApp(const EcoWalletApp());
}

Future<void> _initializeFirebaseIfConfigured() async {
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    final hasRealOptions = !options.apiKey.contains('REPLACE_WITH') &&
        !options.projectId.contains('replace-with') &&
        !options.appId.contains('replacewith');

    if (!hasRealOptions) {
      FirebaseConnection.markDisabled('Firebase is not configured yet.');
      return;
    }

    await Firebase.initializeApp(options: options);
    FirebaseConnection.markEnabled();
  } catch (error) {
    FirebaseConnection.markDisabled(error);
  }
}
