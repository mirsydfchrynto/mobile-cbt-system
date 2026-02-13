import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startBootSequence();
  }

  Future<void> _startBootSequence() async {
    // Memberikan waktu tampilan logo yang cukup sebelum masuk ke Home
    await Future.delayed(2500.ms);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Utama dengan animasi Fade dan Scale
            Image.asset(
              'assets/images/logo.png',
              width: 220,
              fit: BoxFit.contain,
            ).animate()
             .fadeIn(duration: 800.ms, curve: Curves.easeOut)
             .scale(begin: const Offset(0.8, 0.8), duration: 800.ms, curve: Curves.easeOutBack),
            
            const SizedBox(height: 48),
            
            // Indikator loading minimalis agar tidak kaku
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            ).animate().fadeIn(delay: 1.seconds),
          ],
        ),
      ),
    );
  }
}
