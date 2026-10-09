import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import 'admin/admin_main_screen.dart';
import 'petugas/petugas_main_screen.dart';
import 'registrasi_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final berhasil = await auth.login(_usernameController.text.trim(), _passwordController.text);

    if (!mounted) return;

    if (berhasil) {
      final user = auth.user!;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => user.isAdmin ? const AdminMainScreen() : const PetugasMainScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Login gagal')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 42),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'SI-LAYAK MBG',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sistem Pelaporan Kelayakan Makanan\nProgram Makan Bergizi Gratis',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 36),
                CustomTextField(
                  label: 'Username',
                  controller: _usernameController,
                  icon: Icons.person_outline,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Username wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Password',
                  controller: _passwordController,
                  obscureText: _obscure,
                  icon: Icons.lock_outline,
                  validator: (v) => (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                    label: Text(_obscure ? 'Tampilkan' : 'Sembunyikan'),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: auth.isLoading ? null : _submit,
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Masuk'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Gunakan akun yang diberikan oleh Admin/Koordinator SPPG.\nAkun contoh: admin/admin123 (Admin) atau petugas1/petugas123 (Petugas).',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegistrasiScreen()),
                  ),
                  child: const Text('Belum punya akun? Daftar sebagai Petugas Sekolah'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
