import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../sesi_kelas/data/sesi_model.dart';
import '../../../sesi_kelas/providers/sesi_provider.dart';
import '../../../presensi/presentation/screens/presensi_flow_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesiAsync = ref.watch(sesiHariIniProvider);
    final currentMockHeader = ref.watch(mockSesiHeaderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: [
          // Tombol dev buat gonta-ganti Example Postman -- hapus nanti
          // begitu sudah pindah ke backend asli.
          IconButton(
            icon: const Icon(Icons.developer_mode),
            tooltip: 'Ganti Status Sesi (Mock)',
            onPressed: () {
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
          if (sesiList.isEmpty) {
            return const Center(
              child: Text(
                'Tidak ada kelas hari ini,\nnikmati harimu! 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // Cari sesi yang BENERAN berjalan -- jangan fallback diam-diam
          // ke sesi lain lalu dipaksa dikasih badge "Berjalan".
          Sesi? sesiBerjalan;
          for (final s in sesiList) {
            if (s.status == 'berjalan') {
              sesiBerjalan = s;
              break;
            }
          }

          // Kalau tidak ada yang berjalan, ambil sesi paling awal sebagai
          // info pasif "sesi berikutnya" (sesuai Flow_Navigasi.md 1.2 Tab 1).
          final sesiBerikutnya = sesiBerjalan == null ? sesiList.first : null;

          return RefreshIndicator(
            onRefresh: () async {
              return ref.refresh(sesiHariIniProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  sesiBerjalan != null ? 'Sesi Berjalan' : 'Sesi Berikutnya',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (sesiBerjalan != null)
                  _SesiAktifCard(sesi: sesiBerjalan)
                else if (sesiBerikutnya != null)
                  _SesiPasifCard(sesi: sesiBerikutnya),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Card untuk sesi yang BENERAN sedang berjalan -- tombol Presensi aktif.
class _SesiAktifCard extends StatelessWidget {
  final Sesi sesi;
  const _SesiAktifCard({required this.sesi});

  @override
  Widget build(BuildContext context) {
    final isHadir = sesi.sudahPresensi;

    return Card(
      elevation: 0,
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Presensi Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PresensiFlowScreen(sesi: sesi),
                        fullscreenDialog: true,
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

/// Card info pasif untuk sesi yang belum berjalan -- TIDAK ada tombol aktif,
/// sesuai Flow_Navigasi.md 1.2: "tombol presensi disabled/tersembunyi".
class _SesiPasifCard extends StatelessWidget {
  final Sesi sesi;
  const _SesiPasifCard({required this.sesi});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    sesi.namaRuangan,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    sesi.status,
                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12),
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
            const SizedBox(height: 8),
            const Text(
              'Tombol presensi akan aktif begitu sesi ini berjalan.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}