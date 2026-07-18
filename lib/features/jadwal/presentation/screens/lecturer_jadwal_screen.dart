import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../jadwal/providers/jadwal_dosen_provider.dart';

class LecturerJadwalScreen extends ConsumerWidget {
  const LecturerJadwalScreen({super.key});

  // Daftar hari untuk filter
  final List<String> hariList = const ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pantau API dan Hari yang sedang dipilih
    final jadwalAsync = ref.watch(jadwalDosenProvider);
    final selectedHari = ref.watch(selectedHariDosenProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Jadwal Mengajar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. WIDGET FILTER HARI (SCROLL HORIZONTAL)
          Container(
            color: Colors.white,
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: hariList.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemBuilder: (context, index) {
                final hari = hariList[index];
                final isSelected = hari == selectedHari;

                return GestureDetector(
                  onTap: () {
                    // Update state hari yang dipilih saat diklik
                    ref.read(selectedHariDosenProvider.notifier).state = hari;
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        hari,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // 2. WIDGET LIST JADWAL
          Expanded(
            child: jadwalAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (jadwalSemua) {

                // FILTERING: Hanya tampilkan jadwal yang harinya sama dengan yang sedang diklik
                // Ubah bagian filtering di dalam 'data' (sekitar baris 76)
                final jadwalHariIni = jadwalSemua.where((j) {
                  // Jika j.hari adalah int (1, 2, 3), kita konversi ke String
                  final hariJadwal = j.hari.toString().toLowerCase();
                  return hariJadwal == selectedHari.toLowerCase();
                }).toList();

                // Jika kosong
                if (jadwalHariIni.isEmpty) {
                  return Center(
                    child: Text(
                      'Tidak ada jadwal di hari $selectedHari.',
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                // Render Card Jadwal
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: jadwalHariIni.length,
                  itemBuilder: (context, index) {
                    final jadwal = jadwalHariIni[index];

                    // PERHATIAN: Sesuaikan variabel ini (namaRuangan, jamMulai, dll)
                    // dengan penamaan yang ada di dalam model Jadwal milikmu!
                    // Di dalam ListView.builder (sekitar baris 99):
                    return _buildJadwalCard(
                      ruangan: jadwal.namaRuangan, // Hapus ?? 'Ruang Kelas'
                      jamMulai: jadwal.jamMulai,   // Hapus ?? '00:00'
                      jamSelesai: jadwal.jamSelesai, // Hapus ?? '00:00'
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Desain Kotak Jadwal
  Widget _buildJadwalCard({required String ruangan, required String jamMulai, required String jamSelesai}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.schedule, color: Colors.orange),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ruangan, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('$jamMulai - $jamSelesai', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}