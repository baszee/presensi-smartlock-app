import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/jadwal_model.dart';
import '../../providers/jadwal_provider.dart';

// Daftar nama hari, index 1-7 supaya cocok sama field `hari` di ERD
// (1 = Senin, ..., 7 = Minggu). Index 0 sengaja dikosongkan.
const List<String> _namaHari = [
  '', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'
];

class JadwalScreen extends ConsumerWidget {
  const JadwalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semuaJadwalAsync = ref.watch(semuaJadwalProvider);
    final selectedHari = ref.watch(selectedHariProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Kuliah'),
      ),
      body: Column(
        children: [
          // Baris tab hari (Senin - Minggu), bisa discroll horizontal
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 5, // Senin - Minggu
              itemBuilder: (context, index) {
                final hariValue = index + 1; // 1 - 7
                final isSelected = hariValue == selectedHari;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(_namaHari[hariValue]),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(selectedHariProvider.notifier).state = hariValue;
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),

          // Daftar jadwal, difilter sesuai hari yang dipilih
          Expanded(
            child: semuaJadwalAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text('Gagal memuat jadwal: $error'),
              ),
              data: (jadwalList) {
                final filtered = jadwalList
                    .where((jadwal) => jadwal.hari == selectedHari)
                    .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text('Tidak ada jadwal di hari ${_namaHari[selectedHari]}.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _JadwalCard(jadwal: filtered[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget terpisah untuk 1 card jadwal, biar JadwalScreen gak kepanjangan.
class _JadwalCard extends StatelessWidget {
  final Jadwal jadwal;

  const _JadwalCard({required this.jadwal});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kolom jam di kiri
            Column(
              children: [
                Text(jadwal.jamMulai, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Icon(Icons.more_vert, size: 14, color: Colors.grey),
                const SizedBox(height: 4),
                Text(jadwal.jamSelesai, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(width: 12),
            Container(width: 3, height: 70, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),

            // Detail matkul di kanan
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jadwal.mataKuliah,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(jadwal.namaRuangan),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(jadwal.namaDosen),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}