import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
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

  /// Reschedule SATU pertemuan: PATCH /mobile/dosen/sesi/{sesi}.
  ///
  /// PENTING (dari audit source code backend, DosenSessionController::
  /// update): field "catatan" itu WAJIB (required, string, max 1000) --
  /// bukan opsional. Tanpa ini request selalu 422.
  Future<void> reschedule(String sesiId, DateTime tanggalBaru, String catatan) async {
    state = SesiActionState(status: SesiActionStatus.loading);
    try {
      final tanggalStr = '${tanggalBaru.year.toString().padLeft(4, '0')}-'
          '${tanggalBaru.month.toString().padLeft(2, '0')}-'
          '${tanggalBaru.day.toString().padLeft(2, '0')}';

      final response = await _dio.patch(
        '/mobile/dosen/sesi/$sesiId',
        data: {'tanggal': tanggalStr, 'catatan': catatan},
        options: Options(headers: {if (AppConfig.useMockBackend) 'x-mock-response-name': 'Reschedule Sesi'}),
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

  /// Batalkan SATU pertemuan: POST /mobile/dosen/sesi/{sesi}/cancel.
  ///
  /// PENTING (dari audit source code backend, DosenSessionController::
  /// cancel): field wajibnya "catatan" (required, string, max 1000) --
  /// BUKAN "alasan" seperti tebakan sebelumnya. Nama field yang salah ini
  /// yang bikin cancel selalu gagal 422.
  Future<void> cancel(String sesiId, {required String catatan}) async {
    state = SesiActionState(status: SesiActionStatus.loading);
    try {
      final response = await _dio.post(
        '/mobile/dosen/sesi/$sesiId/cancel',
        data: {'catatan': catatan},
        options: Options(headers: {if (AppConfig.useMockBackend) 'x-mock-response-name': 'Cancel Sesi'}),
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