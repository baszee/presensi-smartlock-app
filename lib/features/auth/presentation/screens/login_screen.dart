import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../providers/auth_provider.dart';
import '../../../devices/data/device_registration_service.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/google_mark.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
      ref.read(authProvider.notifier).login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan Password wajib diisi!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.success) {
        () async {
          const storage = FlutterSecureStorage();
          final role = await storage.read(key: 'user_role');

          if (role == 'dosen') {
            final dio = ref.read(dioClientProvider);
            DeviceRegistrationService.ensureRegistered(dio, role: 'dosen', nfcSupported: true).then((deviceId) {
              if (deviceId == null) {
                appLogger.e('⚠️ Registrasi HP dosen gagal -- Remote Unlock nanti akan ditolak backend.');
              }
            });
          }

          if (context.mounted) {
            if (role == 'dosen') {
              context.go('/lecturer/home');
            } else {
              context.go('/home');
            }
          }
        }();
      } else if (next.status == AuthStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'Login Gagal'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    });

    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // --- Bagian navy: identity + tagline ---
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.navyLight,
                      borderRadius: AppRadius.smallAll,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'Selamat Datang Kembali',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Masuk untuk mengakses presensi\ndan kontrol akses kampus.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textOnNavyMuted, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),

            // --- Card putih: form ---
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.large),
                    topRight: Radius.circular(AppRadius.large),
                  ),
                ),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.navy))
                    : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email atau NIM', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Masukkan email atau NIM',
                          prefixIcon: Icon(Icons.mail_outline, size: 20),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Password', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      ElevatedButton(
                        onPressed: _submitLogin,
                        child: const Text('Masuk'),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                            child: Text(
                              'atau lanjut dengan',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      OutlinedButton.icon(
                        onPressed: () => ref.read(authProvider.notifier).loginWithGoogle(),
                        icon: const GoogleMark(size: 18),
                        label: const Text('Lanjut dengan Google'),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Center(
                        child: TextButton(
                          onPressed: () async {
                            final box = Hive.box('mock_db_box');
                            await box.clear();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Data Onboarding Hive dibersihkan!')),
                              );
                            }
                          },
                          child: Text(
                            'Reset Data Lokal (Testing)',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}