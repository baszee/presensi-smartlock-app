import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../sesi_kelas/providers/sesi_dosen_provider.dart';
// IMPORT PROVIDER BARU KITA
import '../../../sesi_kelas/providers/remote_unlock_provider.dart';

class LecturerHomeScreen extends ConsumerWidget {
  const LecturerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesiAsync = ref.watch(sesiDosenProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Beranda Dosen',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Sesi Mengajar Saat Ini',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              sesiAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Gagal memuat jadwal: $error', style: const TextStyle(color: Colors.red)),
                ),
                data: (sesiList) {
                  if (sesiList.isEmpty) {
                    return const Center(child: Text('Tidak ada sesi kelas yang berjalan saat ini.'));
                  }

                  final sesi = sesiList.first;

                  return _buildSesiCard(
                    context,
                    ref,
                    sesiId: sesi.id, // KITA BUTUH ID INI UNTUK DITEMBAK KE API
                    ruangan: sesi.namaRuangan,
                    mataKuliah: 'Sistem Embedded',
                    status: sesi.status.toUpperCase(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSesiCard(BuildContext context, WidgetRef ref, {
    required String sesiId,
    required String ruangan,
    required String mataKuliah,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(ruangan, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: Colors.blue.shade600, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.book, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(mataKuliah, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade500,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () => _showUnlockDialog(context, ref, sesiId),
              icon: const Icon(Icons.lock_open, size: 20),
              label: const Text('Buka Pintu (Remote Unlock)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // FUNGSI UNTUK MENAMPILKAN DIALOG PASSWORD
  void _showUnlockDialog(BuildContext context, WidgetRef ref, String sesiId) {
    final passwordController = TextEditingController();
    bool isLoading = false;

    showDialog(
        context: context,
        barrierDismissible: false, // Tidak bisa ditutup dengan klik luar kotak
        builder: (ctx) {
          return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: const Text('Keamanan Smart Lock', style: TextStyle(fontWeight: FontWeight.bold)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Masukkan password Anda untuk mengonfirmasi akses pembukaan pintu.'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: true, // Sensor ketikan jadi bintang/titik
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: isLoading ? null : () => Navigator.pop(ctx),
                      child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      onPressed: isLoading ? null : () async {
                        if (passwordController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password tidak boleh kosong!')),
                          );
                          return;
                        }

                        // 1. Ubah state jadi loading
                        setState(() => isLoading = true);

                        // 2. Tembak API
                        await ref.read(remoteUnlockProvider.notifier).unlockDoor(sesiId, passwordController.text);

                        // 3. Ambil hasil respons API
                        final unlockState = ref.read(remoteUnlockProvider);

                        setState(() => isLoading = false);

                        // 4. Tutup dialog dan tampilkan notifikasi sesuai hasil
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          if (unlockState.status == UnlockStatus.success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(unlockState.message ?? 'Pintu berhasil dibuka!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(unlockState.message ?? 'Gagal membuka pintu'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Buka Pintu', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                );
              }
          );
        }
    );
  }
}