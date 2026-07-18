import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/jadwal_dosen_provider.dart';
import '../widgets/hari_picker.dart';
import '../widgets/jadwal_card.dart';

const List<String> _hariList = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];
const Map<String, int> _hariToInt = {
  'Senin': 1, 'Selasa': 2, 'Rabu': 3, 'Kamis': 4, 'Jumat': 5,
};

class LecturerJadwalScreen extends ConsumerWidget {
  const LecturerJadwalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          HariPicker(
            hariList: _hariList,
            selectedHari: selectedHari,
            accentColor: Colors.orange.shade600,
            onSelected: (hari) {
              ref.read(selectedHariDosenProvider.notifier).state = hari;
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: jadwalAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (jadwalSemua) {
                final targetHari = _hariToInt[selectedHari];
                final jadwalHariIni = jadwalSemua.where((j) => j.hari == targetHari).toList();

                if (jadwalHariIni.isEmpty) {
                  return Center(
                    child: Text('Tidak ada jadwal di hari $selectedHari.', style: const TextStyle(color: Colors.grey, fontSize: 16)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: jadwalHariIni.length,
                  itemBuilder: (context, index) {
                    final jadwal = jadwalHariIni[index];
                    return JadwalCard(
                      jadwal: jadwal,
                      accentColor: Colors.orange.shade600,
                      onTap: () => _showRescheduleStub(context, jadwal.mataKuliah),
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

  void _showRescheduleStub(BuildContext context, String mataKuliah) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reschedule Sesi'),
        content: Text(
          '$mataKuliah\n\nFitur geser/batalkan pertemuan masih dalam pengembangan — menunggu data sesi per pertemuan terhubung.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }
}