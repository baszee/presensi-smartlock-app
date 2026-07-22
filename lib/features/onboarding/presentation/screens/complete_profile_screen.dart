import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/dio_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/providers/profile_provider.dart';
import '../../../jadwal/providers/jadwal_provider.dart';
import '../../../sesi_kelas/providers/sesi_provider.dart';
import '../../../riwayat_presensi/providers/riwayat_provider.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nimController = TextEditingController();
  final _namaController = TextEditingController();
  final _prodiController = TextEditingController();
  final _angkatanController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final dio = ref.read(dioClientProvider);
      await dio.patch('/mobile/mahasiswa/profile', data: {
        'nim': _nimController.text.trim(),
        'nama_lengkap': _namaController.text.trim(),
        'program_studi': _prodiController.text.trim(),
        'angkatan': int.tryParse(_angkatanController.text.trim()) ?? _angkatanController.text.trim(),
      });

      const storage = FlutterSecureStorage();
      await storage.write(key: 'profile_completed', value: 'true');

      // Router yang akan otomatis lempar ke tahap onboarding berikutnya
      // (Daftarkan Wajah), karena flag face_enrolled masih false.
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan profil: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Sama seperti tombol logout di waiting_rombel_screen.dart (step 3) --
  /// "back" di sini secara arsitektur SAMA DENGAN logout, karena token
  /// akses sudah didapat sejak login. Selama token masih ada, router
  /// (app_router.dart) akan selalu memaksa balik ke step onboarding yang
  /// sesuai, jadi tombol back "ke step sebelumnya" saja tidak akan
  /// pernah kepakai. Makanya di sini "back" = "kembali ke halaman login",
  /// bukan back antar-step.
  Future<void> _confirmBackToLogin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kembali ke Login?'),
        content: const Text(
          'Data yang belum kamu simpan di form ini akan hilang. '
              'Kamu tetap bisa login lagi kapan saja dan melanjutkan dari sini.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya, Kembali')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    const storage = FlutterSecureStorage();
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'user_role');
    await storage.delete(key: 'profile_completed');
    await storage.delete(key: 'face_enrolled');
    await storage.delete(key: 'assigned_to_rombel');
    ref.invalidate(profileProvider);
    ref.invalidate(semuaJadwalProvider);
    ref.invalidate(jadwalHariIniProvider);
    ref.invalidate(sesiHariIniProvider);
    ref.invalidate(sesiHariIniDenganPresensiProvider);
    ref.invalidate(riwayatPresensiProvider);
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Lengkapi Profil'),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali ke Login',
          onPressed: _confirmBackToLogin,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('Langkah 1 dari 3', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 4),
              const Text(
                'Lengkapi data akademik kamu sebelum bisa presensi.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nimController,
                decoration: const InputDecoration(labelText: 'NIM', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'NIM wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _prodiController,
                decoration: const InputDecoration(labelText: 'Program Studi', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Program studi wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _angkatanController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Angkatan', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Angkatan wajib diisi' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Simpan & Lanjut'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}