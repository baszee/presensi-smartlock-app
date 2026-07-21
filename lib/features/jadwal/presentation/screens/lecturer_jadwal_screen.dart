import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/jadwal_model.dart';
import '../../providers/jadwal_dosen_provider.dart';
import '../../../sesi_kelas/data/sesi_model.dart';
import '../../../sesi_kelas/providers/sesi_dosen_provider.dart';
import '../../../sesi_kelas/providers/sesi_dosen_action_provider.dart';
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
                      onTap: () => _openDetailSesi(context, ref, jadwal),
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

  /// Cari pertemuan (Sesi) konkret yang cocok dengan jadwal ini, karena
  /// reschedule/cancel itu target-nya SESI (satu pertemuan bertanggal),
  /// bukan Jadwal (pola mingguan). Kalau tidak ketemu, kasih pesan jujur
  /// -- bukan pura-pura sukses.
  Future<void> _openDetailSesi(BuildContext context, WidgetRef ref, Jadwal jadwal) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    Sesi? sesiTerkait;
    try {
      final sesiList = await ref.read(sesiDosenProvider.future);
      for (final s in sesiList) {
        if (s.jadwalId == jadwal.id) {
          sesiTerkait = s;
          break;
        }
      }
    } catch (_) {
      // biarkan sesiTerkait tetap null, ditangani di bawah
    }

    if (context.mounted) Navigator.of(context, rootNavigator: true).pop(); // tutup loading

    if (!context.mounted) return;

    if (sesiTerkait == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Belum Ada Data Pertemuan'),
          content: Text(
            'Belum ada data pertemuan (sesi) untuk "${jadwal.mataKuliah}" yang bisa diambil dari server saat ini. '
                'Reschedule/batalkan hanya bisa dilakukan untuk pertemuan yang datanya sudah tersedia.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
          ],
        ),
      );
      return;
    }

    _showDetailSesiSheet(context, ref, jadwal, sesiTerkait);
  }

  void _showDetailSesiSheet(BuildContext context, WidgetRef ref, Jadwal jadwal, Sesi sesi) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(jadwal.mataKuliah, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('${jadwal.namaRuangan} • Pertemuan tanggal ${sesi.tanggal}', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('Reschedule Pertemuan Ini'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _pickRescheduleDate(context, ref, sesi);
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.event_busy),
                  label: const Text('Batalkan Pertemuan Ini'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmCancel(context, ref, sesi);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickRescheduleDate(BuildContext context, WidgetRef ref, Sesi sesi) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Pilih tanggal baru untuk pertemuan ini',
    );

    if (picked == null || !context.mounted) return;

    await ref.read(sesiDosenActionProvider.notifier).reschedule(sesi.id, picked);
    _handleActionResult(context, ref);
  }

  void _confirmCancel(BuildContext context, WidgetRef ref, Sesi sesi) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Pertemuan?'),
        content: const Text(
          'Pertemuan ini akan dibatalkan dan aksi ini tidak bisa dibatalkan lagi setelahnya. Yakin lanjut?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tidak', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(sesiDosenActionProvider.notifier).cancel(sesi.id);
              _handleActionResult(context, ref);
            },
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  void _handleActionResult(BuildContext context, WidgetRef ref) {
    final result = ref.read(sesiDosenActionProvider);
    if (!context.mounted) return;

    final isSuccess = result.status == SesiActionStatus.success;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message ?? (isSuccess ? 'Berhasil' : 'Gagal')),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );

    if (isSuccess) {
      // Refresh data supaya perubahan langsung kelihatan.
      ref.invalidate(sesiDosenProvider);
      ref.invalidate(jadwalDosenProvider);
    }
  }
}