import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => _showLogoutDialog(context),
          )
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (profile) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Foto Profil Dummy
              const Center(
                child: CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 50),
                ),
              ),
              const SizedBox(height: 32),

              // Data Diri
              _buildProfileItem('Nama Lengkap', profile.namaLengkap),
              _buildProfileItem('NIM / NIP', profile.nim),
              _buildProfileItem('Email', profile.email),
              _buildProfileItem('Program Studi', profile.programStudi),
              _buildProfileItem('Role', profile.role.toUpperCase()),

              const SizedBox(height: 40),

              // Tombol Logout Merah
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout),
                label: const Text('Keluar (Logout)'),
              )
            ],
          );
        },
      ),
    );
  }

  // Widget bantuan untuk menghemat baris kode
  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(),
        ],
      ),
    );
  }

  // Dialog konfirmasi agar user tidak tidak sengaja kepencet logout
  void _showLogoutDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Logout'),
          content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                // 1. Hapus token dan role dari memori penyimpanan HP
                const storage = FlutterSecureStorage();
                await storage.delete(key: 'access_token');
                await storage.delete(key: 'user_role');

                // 2. Tendang user kembali ke halaman Login
                if (context.mounted) {
                  context.go('/login');
                }
              },
              child: const Text('Ya, Keluar', style: TextStyle(color: Colors.red)),
            ),
          ],
        )
    );
  }
}