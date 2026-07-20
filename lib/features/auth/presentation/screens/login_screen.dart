import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Tambahan import untuk storage

// Sesuaikan path import ini jika letak auth_provider.dart milikmu berbeda
import '../../providers/auth_provider.dart';
import '../../../devices/data/device_registration_service.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/utils/app_logger.dart';

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

          if (role == 'dosen') {
            // Dosen tidak lewat alur onboarding kayak mahasiswa (tidak ada
            // layar lengkapi profil/enroll wajah), jadi ini titik SATU-
            // SATUNYA yang pasti kelewat setiap kali dosen login. Silent,
            // di background, tidak menghalangi navigasi ke Home -- sesuai
            // API_CONTRACT2.md Bagian 7 & ADR_V3.txt Bagian 9.5 [CONFIRMED]:
            // "POST /mobile/devices dengan nfc_supported: true wajib agar
            // HP tersebut memenuhi syarat dipakai untuk Remote Unlock."
            final dio = ref.read(dioClientProvider);
            DeviceRegistrationService.ensureRegistered(dio, role: 'dosen', nfcSupported: true).then((deviceId) {
              if (deviceId == null) {
                appLogger.e('⚠️ Registrasi HP dosen gagal -- Remote Unlock nanti akan ditolak backend.');
              }
            });
          }

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