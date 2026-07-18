import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/jadwal_model.dart';
import '../../../riwayat_presensi/providers/riwayat_provider.dart';

class JadwalDetailScreen extends ConsumerWidget {
  final Jadwal jadwal;
  const JadwalDetailScreen({super.key, required this.jadwal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riwayatAsync = ref.watch(riwayatPresensiProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(jadwal.mataKuliah, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(Icons.person_outline, 'Dosen', jadwal.namaDosen),
                const SizedBox(height: 8),
                _infoRow(Icons.location_on_outlined, 'Ruangan', jadwal.namaRuangan),
                const SizedBox(height: 8),
                _infoRow(Icons.schedule, 'Jam', '${jadwal.jamMulai} - ${jadwal.jamSelesai}'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Riwayat Presensi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          riwayatAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
            error: (e, _) => const Text('Gagal memuat riwayat.', style: TextStyle(color: Colors.grey)),
            data: (riwayatList) {
              final filtered = riwayatList.where((r) => r.mataKuliah == jadwal.mataKuliah).toList();

              if (filtered.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Belum ada riwayat presensi untuk mata kuliah ini.',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return Column(
                children: filtered.map((r) {
                  final isHadir = r.status.toLowerCase() == 'hadir';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(isHadir ? Icons.check_circle : Icons.cancel, color: isHadir ? Colors.green : Colors.red, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(r.tanggal)),
                        Text(
                          isHadir ? 'Hadir${r.waktuPresensi != null ? ' (${r.waktuPresensi})' : ''}' : 'Tidak Hadir',
                          style: TextStyle(color: isHadir ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(color: Colors.grey.shade600)),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
      ],
    );
  }
}