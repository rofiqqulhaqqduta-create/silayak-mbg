import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'admin/admin_main_screen.dart';
import 'petugas/petugas_main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _cekSesi();
  }

  Future<void> _cekSesi() async {
    final auth = context.read<AuthProvider>();
    await auth.loadSession();
    if (!mounted) return;

    if (auth.isLoggedIn) {
      final user = auth.user!;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => user.isAdmin ? const AdminMainScreen() : const PetugasMainScreen(),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 72),
            SizedBox(height: 16),
            Text(
              'SI-LAYAK MBG',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 0.5),
            ),
            SizedBox(height: 8),
            Text(
              'Pelaporan Kelayakan Makanan Program MBG',
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
