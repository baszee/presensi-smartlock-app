import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../sesi_kelas/data/sesi_model.dart';
import '../../../sesi_kelas/providers/sesi_dosen_provider.dart';
import '../../../smart_lock/presentation/screens/lecturer_room_unlock_screen.dart';
import '../../../smart_lock/presentation/widgets/remote_unlock_dialog.dart';

/// Selaras dengan HomeScreen milik mahasiswa (AppBar putih + Card bahasa
/// desain yang sama), warna aksen oranye untuk membedakan role dosen.
class LecturerHomeScreen extends ConsumerWidget {
  const LecturerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesiAsync = ref.watch(sesiDosenProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Beranda'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: sesiAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Gagal memuat: $error')),
        data: (sesiList) {
          Sesi? sesiBerjalan;
          for (final s in sesiList) {
            if (s.status == 'berjalan') {
              sesiBerjalan = s;
              break;
            }
          }
          final sesiBerikutnya = sesiBerjalan == null && sesiList.isNotEmpty ? sesiList.first : null;

          return RefreshIndicator(
            onRefresh: () async {
              return ref.refresh(sesiDosenProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  sesiBerjalan != null
                      ? 'Sesi Mengajar Saat Ini'
                      : (sesiBerikutnya != null ? 'Sesi Berikutnya' : 'Sesi Mengajar'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (sesiBerjalan != null)
                  _SesiAktifCard(sesi: sesiBerjalan)
                else if (sesiBerikutnya != null)
                  _SesiPasifCard(sesi: sesiBerikutnya)
                else
                  const _TidakAdaSesiCard(),

                const SizedBox(height: 28),
                const Text(
                  'Akses Lain',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _BukaRuanganLainCard(),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Card untuk sesi yang BENERAN sedang berjalan -- tombol Remote Unlock aktif.
class _SesiAktifCard extends ConsumerWidget {
  final Sesi sesi;
  const _SesiAktifCard({required this.sesi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      color: Colors.white,
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
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Berjalan',
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.lock_open),
                label: const Text('Buka Pintu (Remote Unlock)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () => showRemoteUnlockDialog(context, ref, ruanganId: sesi.ruanganId),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card info pasif untuk sesi yang belum berjalan -- selaras dengan
/// _SesiPasifCard milik mahasiswa, TIDAK ada tombol aktif.
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
              'Buka Pintu akan aktif begitu sesi ini berjalan.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state kalau dosen memang tidak punya sesi sama sekali hari ini.
class _TidakAdaSesiCard extends StatelessWidget {
  const _TidakAdaSesiCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Tidak ada sesi mengajar hari ini,\nnikmati harimu! 🎉',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

/// Entry point ke LecturerRoomUnlockScreen -- dipakai untuk kasus mahasiswa
/// bimbingan sudah di depan ruangan tapi dosen belum sampai, dosen bisa
/// buka pintu ruangan manapun yang terhubung dengan jadwalnya, TANPA harus
/// menunggu sesi itu berstatus "berjalan".
class _BukaRuanganLainCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LecturerRoomUnlockScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
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
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Buka Ruangan Lain', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(height: 2),
                  Text(
                    'Untuk mahasiswa bimbingan yang menunggu di ruangan',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}