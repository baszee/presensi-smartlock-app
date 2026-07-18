import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/jadwal_provider.dart';
import '../widgets/hari_picker.dart';
import '../widgets/jadwal_card.dart';
import 'jadwal_detail_screen.dart';

const List<String> _namaHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];
const Map<String, int> _hariToInt = {
  'Senin': 1, 'Selasa': 2, 'Rabu': 3, 'Kamis': 4, 'Jumat': 5,
};

class JadwalScreen extends ConsumerWidget {
  const JadwalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semuaJadwalAsync = ref.watch(semuaJadwalProvider);
    final selectedHariInt = ref.watch(selectedHariProvider);
    final selectedHariNama = _namaHari[selectedHariInt - 1];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Jadwal Kuliah', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          HariPicker(
            hariList: _namaHari,
            selectedHari: selectedHariNama,
            onSelected: (hari) {
              ref.read(selectedHariProvider.notifier).state = _hariToInt[hari]!;
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: semuaJadwalAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Gagal memuat jadwal: $error')),
              data: (jadwalList) {
                final filtered = jadwalList.where((j) => j.hari == selectedHariInt).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text('Tidak ada jadwal di hari $selectedHariNama.', style: const TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final jadwal = filtered[index];
                    return JadwalCard(
                      jadwal: jadwal,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => JadwalDetailScreen(jadwal: jadwal)),
                        );
                      },
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
}