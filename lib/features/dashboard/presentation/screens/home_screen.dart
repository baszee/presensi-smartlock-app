import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../sesi_kelas/data/sesi_model.dart';
import '../../../sesi_kelas/providers/sesi_provider.dart';
import '../../../riwayat_presensi/providers/riwayat_provider.dart';
import '../../../presensi/presentation/screens/presensi_flow_screen.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_chip.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // PENTING: pakai provider gabungan, bukan sesiHariIniProvider mentah --
    // backend tidak menghitung sudah_presensi/waktu_presensi per sesi sama
    // sekali, jadi ini yang men-derive-nya di mobile dari riwayat-presensi
    // (lihat sesi_provider.dart).
    final sesiAsync = ref.watch(sesiHariIniDenganPresensiProvider);
    final currentMockHeader = ref.watch(mockSesiHeaderProvider);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Refresh sumber datanya (sesi mentah + riwayat), lalu provider
            // gabungan otomatis kebaca ulang lewat ref.watch di atas.
            ref.invalidate(sesiHariIniProvider);
            ref.invalidate(riwayatPresensiProvider);
            ref.invalidate(profileProvider);
            return ref.refresh(sesiHariIniDenganPresensiProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
            children: [
              // --- Greeting ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_greeting()}, ${profileAsync.valueOrNull?.namaLengkap.split(' ').first ?? 'Mahasiswa'}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Siap untuk sesi akademik hari ini?',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  // Tombol dev buat gonta-ganti Example Postman -- hapus nanti
                  // begitu sudah pindah ke backend asli.
                  IconButton(
                    icon: const Icon(Icons.developer_mode, size: 20),
                    tooltip: 'Ganti Status Sesi (Mock)',
                    color: AppColors.textSecondary,
                    onPressed: () {
                      final newState = currentMockHeader == 'Sesi Aktif - Belum Presensi'
                          ? 'Sesi Aktif - Sudah Presensi'
                          : 'Sesi Aktif - Belum Presensi';
                      ref.read(mockSesiHeaderProvider.notifier).state = newState;
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // --- Hero Card: sesi hari ini ---
              sesiAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: Center(child: CircularProgressIndicator(color: AppColors.navy)),
                ),
                error: (error, stack) => AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.danger),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text('Gagal memuat: $error', style: Theme.of(context).textTheme.bodySmall)),
                    ],
                  ),
                ),
                data: (sesiList) {
                  if (sesiList.isEmpty) {
                    return const _EmptyTodayCard();
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

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sesiBerjalan != null ? 'SESI BERJALAN' : 'SESI BERIKUTNYA',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (sesiBerjalan != null)
                        _SesiAktifCard(sesi: sesiBerjalan)
                      else if (sesiBerikutnya != null)
                        _SesiPasifCard(sesi: sesiBerikutnya),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
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

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  sesi.namaRuangan,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusChip(
                label: isHadir ? 'Sudah Presensi' : 'Berjalan',
                type: isHadir ? StatusType.success : StatusType.info,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Text(sesi.tanggal, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (isHadir)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: AppRadius.smallAll,
              ),
              child: Center(
                child: Text(
                  'Hadir (${sesi.waktuPresensi ?? "-"})',
                  style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.fingerprint, size: 20),
                label: const Text('Presensi Sekarang'),
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sesi.namaRuangan,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusChip(label: sesi.status, type: StatusType.neutral),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Text(sesi.tanggal, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tombol presensi akan aktif begitu sesi ini berjalan.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Empty state -- ikuti pola MD: Icon -> Title -> Description.
class _EmptyTodayCard extends StatelessWidget {
  const _EmptyTodayCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl, horizontal: AppSpacing.lg),
      child: Column(
        children: [
          const Icon(Icons.event_available_outlined, size: 36, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.md),
          Text('Tidak Ada Kelas Hari Ini', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Nikmati harimu, jadwal berikutnya bisa dicek di tab Jadwal.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}