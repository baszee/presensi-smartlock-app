import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/dosen_ruangan_provider.dart';
import '../widgets/remote_unlock_dialog.dart';

/// Full screen daftar ruangan yang bisa di-remote-unlock dosen -- dibuka dari
/// card "Buka Ruangan Lain" di lecturer_home_screen.dart.
///
/// SEMENTARA: daftar ruangan diturunkan dari jadwal mengajar dosen sendiri
/// (lihat dosen_ruangan_provider.dart), karena backend belum punya endpoint
/// resmi "list ruangan milik dosen". Begitu endpoint itu ada, cukup provider
/// yang diganti sumbernya, screen ini tidak perlu diubah.
class LecturerRoomUnlockScreen extends ConsumerWidget {
  const LecturerRoomUnlockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ruanganAsync = ref.watch(dosenRuanganListProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Buka Ruangan Lain'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: ruanganAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Gagal memuat: $error')),
        data: (ruanganList) {
          if (ruanganList.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Belum ada ruangan yang terhubung dengan jadwal mengajar kamu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(dosenRuanganListProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: ruanganList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ruangan = ruanganList[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.meeting_room_outlined, color: Colors.orange.shade600),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ruangan.namaRuangan,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange.shade700,
                          backgroundColor: Colors.orange.shade50,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onPressed: () => showRemoteUnlockDialog(
                          context,
                          ref,
                          ruanganId: ruangan.id,
                          alasan: 'Remote unlock dari luar sesi',
                        ),
                        icon: const Icon(Icons.lock_open, size: 18),
                        label: const Text('Buka', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}