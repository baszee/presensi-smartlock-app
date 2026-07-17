import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Pastikan path import ini sesuai dengan struktur foldermu
import '../../../sesi_kelas/data/sesi_model.dart';
import '../../../sesi_kelas/providers/sesi_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Memantau data sesi dari API (Postman Mock)
    final sesiAsync = ref.watch(sesiHariIniProvider);
    // Memantau status header untuk tombol rahasia developer
    final currentMockHeader = ref.watch(mockSesiHeaderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: [
          // 🛠️ TOMBOL RAHASIA DEVELOPER (Untuk kemudahan testing/demo)
          IconButton(
            icon: const Icon(Icons.developer_mode),
            tooltip: 'Ganti Status Sesi (Mock)',
            onPressed: () {
              // Logika saklar (toggle) untuk ganti JSON response dari Postman
              final newState = currentMockHeader == 'Sesi Aktif - Belum Presensi'
                  ? 'Sesi Aktif - Sudah Presensi'
                  : 'Sesi Aktif - Belum Presensi';

              ref.read(mockSesiHeaderProvider.notifier).state = newState;
            },
          ),
        ],
      ),
      body: sesiAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Gagal memuat: $error')),
        data: (sesiList) {
          // Jika tidak ada data dari Postman
          if (sesiList.isEmpty) {
            return const Center(
              child: Text(
                'Tidak ada kelas hari ini,\nnikmati harimu! 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // Kita ambil sesi yang statusnya "berjalan"
          final sesiAktif = sesiList.firstWhere(
                (s) => s.status == 'berjalan',
            orElse: () => sesiList.first,
          );

          return RefreshIndicator(
            onRefresh: () async {
              // Tarik ke bawah untuk refresh data dari API
              return ref.refresh(sesiHariIniProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Sesi Berjalan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Panggil Widget Card Ajaib kita di sini
                _SesiAktifCard(sesi: sesiAktif),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Widget Terpisah khusus untuk merender Card Presensi
class _SesiAktifCard extends StatelessWidget {
  final Sesi sesi;

  const _SesiAktifCard({required this.sesi});

  @override
  Widget build(BuildContext context) {
    // Inilah variabel penentu dari UI/UX flow kita
    final isHadir = sesi.sudahPresensi;

    return Card(
      elevation: 0,
      // ✨ The Magic: Warna card berubah hijau jika sudah hadir
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isHadir ? Colors.green : Colors.grey.shade300,
          width: isHadir ? 2 : 1,
        ),
      ),
      color: isHadir ? Colors.green.shade50 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    sesi.namaRuangan,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Berjalan',
                    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(sesi.tanggal, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 20),

            // ✨ The Magic Part 2: Pergantian Tombol / Label
            if (isHadir)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '✅ Hadir (${sesi.waktuPresensi ?? "-"})',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.fingerprint),
                  label: const Text(
                    'Presensi Sekarang',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    // TODO: Nanti kita hubungkan ini ke alur Camera / BLE
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Memulai alur verifikasi presensi...'),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}