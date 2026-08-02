import 'package:flutter/material.dart';
import 'features/splash/splash_screen.dart';

class StructFlowApp extends StatelessWidget {
  const StructFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StructFlow',
      home: const SplashScreen(),
    );
  }
}