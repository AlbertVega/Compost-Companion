import 'package:flutter/material.dart';
import 'package:compost_companion/core/theme/app_theme.dart';
import 'package:compost_companion/features/auth/presentation/screens/login_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Compost Companion',
      theme: AppTheme.lightTheme(),
      home: const LoginScreen(),
    );
  }
}
