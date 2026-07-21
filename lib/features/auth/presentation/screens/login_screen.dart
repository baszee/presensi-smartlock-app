import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../providers/auth_provider.dart';
import '../../../devices/data/device_registration_service.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/utils/app_logger.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Tambahkan controller untuk menangkap ketikan keyboard
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Lock Login')),
      body: Center(
        child: authState.status == AuthStatus.loading
            ? const CircularProgressIndicator()
            : Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- FORM LOGIN SUNGGUHAN ---
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),

              // --- TOMBOL LOGIN UTAMA ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Pastikan tidak kosong sebelum menembak API
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
                  },
                  child: const Text('Login'),
                ),
              ),

              const SizedBox(height: 32),
              const Divider(),

              // --- TOMBOL RESET HIVE (Untuk kemudahan testing) ---
              TextButton(
                onPressed: () async {
                  final box = Hive.box('mock_db_box');
                  await box.clear();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Data Onboarding Hive dibersihkan!')),
                    );
                  }
                },
                child: const Text(
                  'Reset Data Lokal (Testing)',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}