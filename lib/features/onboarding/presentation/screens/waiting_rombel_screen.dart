import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WaitingRombelScreen extends StatelessWidget {
  const WaitingRombelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Menunggu Admin'),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          // Logout tetap disediakan di sini -- satu-satunya aksi yang
          // masuk akal selain menunggu, sesuai Flow_Navigasi.md 1.1.
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              const storage = FlutterSecureStorage();
              await storage.delete(key: 'access_token');
              await storage.delete(key: 'user_role');
              await storage.delete(key: 'profile_completed');
              await storage.delete(key: 'face_enrolled');
              await storage.delete(key: 'assigned_to_rombel');
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Langkah 3 dari 3', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),
              Icon(Icons.hourglass_top, size: 72, color: Colors.orange.shade400),
              const SizedBox(height: 20),
              const Text(
                'Akun kamu belum dimasukkan ke rombel manapun.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hubungi admin untuk dimasukkan ke rombel. Halaman ini akan otomatis lanjut begitu admin memprosesnya.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}