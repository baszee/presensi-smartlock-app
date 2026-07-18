import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Tambahan import untuk storage

// Sesuaikan path import ini jika letak auth_provider.dart milikmu berbeda
import '../../providers/auth_provider.dart';

// Gunakan ConsumerWidget agar bisa membaca state dari Riverpod
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // Dengarkan perubahan status Auth secara reaktif
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.success) {
        // Bungkus dengan anonymous async function agar bisa await baca storage
        () async {
          const storage = FlutterSecureStorage();
          final role = await storage.read(key: 'user_role');

          if (context.mounted) {
            // Gerbang tol: Lempar sesuai role
            if (role == 'dosen') {
              context.go('/lecturer/home');
            } else {
              context.go('/home');
            }
          }
        }();
      } else if (next.status == AuthStatus.error) {
        // Jika login gagal, tampilkan Snackbar pesan error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'Login Gagal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    // Pantau state saat ini untuk merubah UI (misal nampilin loading)
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Lock Login'),
      ),
      body: Center(
        child: authState.status == AuthStatus.loading
            ? const CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tombol 1: Tes Login Mahasiswa
            ElevatedButton(
              onPressed: () {
                ref.read(authProvider.notifier).login(
                  'mahasiswa1@smartlock.test', // Email ini akan dibaca sbg mahasiswa
                  'DemoSmartlock123!',
                );
              },
              child: const Text('Login Dummy (Mahasiswa)'),
            ),
            const SizedBox(height: 16),

            // Tombol 2: Tes Login Dosen
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: () {
                ref.read(authProvider.notifier).login(
                  'dosen@smartlock.test', // Email ini akan dibaca sbg dosen
                  'DemoSmartlock123!',
                );
              },
              child: const Text('Login Dummy (Dosen)'),
            ),
          ],
        ),
      ),
    );
  }
}