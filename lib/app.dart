import 'package:flutter/material.dart';
import 'package:structflow/core/routing/app_router.dart';

class StructFlowApp extends StatelessWidget {
  const StructFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'StructFlow',
      routerConfig: appRouter,
    );
  }
}