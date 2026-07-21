import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_provider.dart';

enum SesiActionStatus { initial, loading, success, error }

class SesiActionState {
  final SesiActionStatus status;
  final String? message;
  SesiActionState({required this.status, this.message});
}

class SesiDosenActionNotifier extends StateNotifier<SesiActionState> {
  final Dio _dio;
  SesiDosenActionNotifier(this._dio) : super(SesiActionState(status: SesiActionStatus.initial));

  /// Reschedule SATU pertemuan, sesuai API_CONTRACT2.md bagian 7:
  /// PATCH /mobile/dosen/sesi/{sesi}.
  ///
  /// CATATAN: nama field body ("tanggal") ini tebakan terbaik -- kontrak
  /// belum kasih contoh JSON persis untuk endpoint ini (cuma dijelaskan
  /// naratif: "geser 1 pertemuan itu saja, harus dalam periode semester,
  /// ditolak jika ruangan bentrok"). Kalau nanti pas hookup ke backend
  /// asli field-nya beda nama, cukup ganti key di sini -- UI tidak perlu
  /// diubah.
  Future<void> reschedule(String sesiId, DateTime tanggalBaru) async {
    state = SesiActionState(status: SesiActionStatus.loading);
    try {
      final tanggalStr = '${tanggalBaru.year.toString().padLeft(4, '0')}-'
          '${tanggalBaru.month.toString().padLeft(2, '0')}-'
          '${tanggalBaru.day.toString().padLeft(2, '0')}';

      final response = await _dio.patch(
        '/mobile/dosen/sesi/$sesiId',
        data: {'tanggal': tanggalStr},
        options: Options(headers: {'x-mock-response-name': 'Reschedule Sesi'}),
      );

      state = SesiActionState(
        status: SesiActionStatus.success,
        message: response.data['message'] ?? 'Sesi berhasil dijadwal ulang',
      );
    } on DioException catch (e) {
      state = SesiActionState(
        status: SesiActionStatus.error,
        message: e.response?.data['message']?.toString() ?? 'Gagal menjadwal ulang sesi.',
      );
    } catch (e) {
      state = SesiActionState(status: SesiActionStatus.error, message: e.toString());
    }
  }

  /// Batalkan SATU pertemuan, sesuai POST /mobile/dosen/sesi/{sesi}/cancel.
  Future<void> cancel(String sesiId, {String? alasan}) async {
    state = SesiActionState(status: SesiActionStatus.loading);
    try {
      final response = await _dio.post(
        '/mobile/dosen/sesi/$sesiId/cancel',
        data: {if (alasan != null && alasan.isNotEmpty) 'alasan': alasan},
        options: Options(headers: {'x-mock-response-name': 'Cancel Sesi'}),
      );

      state = SesiActionState(
        status: SesiActionStatus.success,
        message: response.data['message'] ?? 'Sesi berhasil dibatalkan',
      );
    } on DioException catch (e) {
      state = SesiActionState(
        status: SesiActionStatus.error,
        message: e.response?.data['message']?.toString() ?? 'Gagal membatalkan sesi.',
      );
    } catch (e) {
      state = SesiActionState(status: SesiActionStatus.error, message: e.toString());
    }
  }
}

final sesiDosenActionProvider = StateNotifierProvider<SesiDosenActionNotifier, SesiActionState>((ref) {
  final dio = ref.watch(dioClientProvider);
  return SesiDosenActionNotifier(dio);
});