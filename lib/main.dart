import 'package:flutter/material.dart';

void main() {
  runApp(const StructFlowApp());
}

class StructFlowApp extends StatelessWidget {
  const StructFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StructFlow',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('StructFlow'),
        ),
        body: const Center(
          child: Text(
            'StructFlow V1',
            style: TextStyle(fontSize: 28),
          ),
        ),
      ),
    );
  }
}