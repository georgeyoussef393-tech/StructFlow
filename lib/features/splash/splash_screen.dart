import 'dart:async';

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(
      const Duration(seconds: 3),
      () {
        // هنضيف التنقل بعدين
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xff071A2E),

      body: Stack(
        children: [
          // ==========================================================
          // BACKGROUND
          // ==========================================================

          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_background.png',
              fit: BoxFit.cover,
            ),
          ),

          // ==========================================================
          // DARK OVERLAY
          // ==========================================================

          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(
                alpha: 0.25,
              ),
            ),
          ),

          // ==========================================================
          // CONTENT
          // ==========================================================

          Center(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/sf_logo.png',
                  width: 180,
                ),

                const SizedBox(height: 30),

                const Text(
                  'StructFlow',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Construction Management System',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 50),

                SizedBox(
                  width: 220,
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(30),
                    child:
                        const LinearProgressIndicator(
                      minHeight: 6,
                      backgroundColor:
                          Colors.white24,
                      valueColor:
                          AlwaysStoppedAnimation<
                              Color>(
                        Color(0xffFF7A00),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}