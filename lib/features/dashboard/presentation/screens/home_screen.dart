import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../jadwal/data/jadwal_model.dart';
import '../../../jadwal/providers/jadwal_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jadwalHariIniAsync = ref.watch(jadwalHariIniProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dsolve Smart Lock'),
      ),
      body: RefreshIndicator(
        // Swipe ke bawah untuk refresh data (nanti berguna banget
        // pas sudah pakai API asli)
        onRefresh: () async {
          ref.invalidate(jadwalHariIniProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Sapaan sederhana, nanti nama user bisa diambil dari
            // auth state setelah Login jadi
            const Text(
              'Halo!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _getTodayLabel(),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            const Text(
              'Jadwal Hari Ini',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            jadwalHariIniAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stackTrace) => Center(
                child: Text('Gagal memuat jadwal: $error'),
              ),
              data: (jadwalList) {
                if (jadwalList.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('Tidak ada jadwal hari ini. Selamat istirahat!'),
                      ),
                    ),
                  );
                }

                return Column(
                  children: jadwalList
                      .map((jadwal) => _HomeJadwalCard(jadwal: jadwal))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getTodayLabel() {
    const namaHari = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final today = DateTime.now();
    return '${namaHari[today.weekday]}, ${today.day}/${today.month}/${today.year}';
  }
}

/// Card jadwal khusus di Home, ada tombol aksi (Presensi/Unlock)
/// di bagian bawahnya.
class _HomeJadwalCard extends StatelessWidget {
  final Jadwal jadwal;

  const _HomeJadwalCard({required this.jadwal});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              jadwal.mataKuliah,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${jadwal.jamMulai} - ${jadwal.jamSelesai}'),
                const SizedBox(width: 16),
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(jadwal.namaRuangan),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: nanti ini akan navigasi ke flow presensi
                  // (state machine PresensiStep) atau remote unlock
                  // tergantung role user.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Mulai presensi untuk ${jadwal.mataKuliah} (belum diimplementasi)'),
                    ),
                  );
                },
                icon: const Icon(Icons.fingerprint),
                label: const Text('Mulai Presensi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}