import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../sesi_kelas/data/sesi_model.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/widgets/face_camera_capture.dart';
import '../../../devices/data/device_registration_service.dart';

enum _PresensiStep { permission, scanBle, captureFace, verifying, submitting, success, error }

class PresensiFlowScreen extends ConsumerStatefulWidget {
  final Sesi sesi;
  const PresensiFlowScreen({super.key, required this.sesi});

  @override
  ConsumerState<PresensiFlowScreen> createState() => _PresensiFlowScreenState();
}

class _PresensiFlowScreenState extends ConsumerState<PresensiFlowScreen> {
  _PresensiStep _step = _PresensiStep.permission;
  String? _errorMessage;
  Position? _position;
  String? _faceVerificationToken;

  bool _attendanceRecorded = false;
  bool _doorUnlockRequested = false;
  final bool _doorUnlockConfirmed = false;

  @override
  void initState() {
    super.initState();
    _startFlow();
  }

  Future<void> _startFlow() async {
    await _checkPermissions();
  }

  Future<PermissionStatus> _requestWithTimeout(Permission permission) async {
    try {
      return await permission.request().timeout(
        const Duration(seconds: 6),
        onTimeout: () => PermissionStatus.denied,
      );
    } catch (_) {
      return PermissionStatus.denied;
    }
  }

  // ---------- LANGKAH 1: Cek izin Lokasi & Bluetooth ----------
  Future<void> _checkPermissions() async {
    setState(() => _step = _PresensiStep.permission);

    final locationStatus = await _requestWithTimeout(Permission.locationWhenInUse);
    final bluetoothScanStatus = await _requestWithTimeout(Permission.bluetoothScan);
    await _requestWithTimeout(Permission.bluetoothConnect);
    await _requestWithTimeout(Permission.camera);

    if (!locationStatus.isGranted) {
      setState(() {
        _step = _PresensiStep.error;
        _errorMessage = 'Izin lokasi ditolak. Presensi butuh lokasi untuk memastikan kamu di dalam ruangan.';
      });
      return;
    }
    if (!bluetoothScanStatus.isGranted) {
      setState(() {
        _step = _PresensiStep.error;
        _errorMessage = 'Izin Bluetooth ditolak atau tidak tersedia di perangkat ini.\n\n'
            'Kalau kamu sedang di emulator: banyak emulator Android tidak punya '
            'hardware Bluetooth -- coba di HP fisik untuk tes bagian ini.';
      });
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _step = _PresensiStep.error;
        _errorMessage = 'GPS/Lokasi perangkat kamu sedang mati. Aktifkan dulu, lalu coba lagi.';
      });
      return;
    }

    try {
      _position = await Geolocator.getCurrentPosition();
    } catch (e) {
      setState(() {
        _step = _PresensiStep.error;
        _errorMessage = 'Gagal mengambil lokasi: $e';
      });
      return;
    }

    _startBleScan();
  }

  // ---------- LANGKAH 2: Scan BLE ke smart lock ----------
  // TODO: masih simulasi -- BLE beneran ditunda sampai ada smart lock fisik
  // buat dites, sesuai kesepakatan kita. Langkah: POST /mobile/mahasiswa/ble/challenges
  // -> kirim nonce via BLE -> smart lock POST /hardware/ble-attestations ->
  // pakai ble_proof_token yang didapat untuk submit presensi.
  Future<void> _startBleScan() async {
    setState(() => _step = _PresensiStep.scanBle);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _step = _PresensiStep.captureFace);
  }

  // ---------- LANGKAH 3: Ambil foto wajah (BENERAN, bukan simulasi lagi) ----------
  Future<void> _onFaceCaptured(String imagePath) async {
    setState(() => _step = _PresensiStep.verifying);

    try {
      final dio = ref.read(dioClientProvider);

      final formData = FormData.fromMap({
        'sesi_kelas_id': widget.sesi.id,
        'image': await MultipartFile.fromFile(imagePath, filename: 'face_verify.jpg'),
      });

      final response = await dio.post('/mobile/mahasiswa/face/verify', data: formData);
      final data = response.data;

      // PENTING (dari audit source code backend, FaceRecognitionController::
      // verificationResponse): key-nya "verification_token", dibungkus di
      // dalam "data", BUKAN "face_verification_token"/"token" di level atas
      // seperti yang ditebak sebelumnya. Field "face_verification_token"
      // dipakai lagi nanti sebagai NAMA PAYLOAD saat submit ke
      // /mobile/mahasiswa/presensi (lihat _submitPresensi di bawah) -- dua
      // hal berbeda meski isinya sama (id verifikasi).
      final token = data['data']?['verification_token'];

      if (token == null) {
        throw 'Respons verifikasi wajah tidak berisi token (wajah mungkin tidak cocok / ditolak).';
      }

      _faceVerificationToken = token.toString();

      if (!mounted) return;
      _submitPresensi();
    } catch (e) {
      appLogger.e('❌ ERROR FACE VERIFY: $e');
      if (!mounted) return;
      setState(() {
        _step = _PresensiStep.error;
        _errorMessage = 'Verifikasi wajah gagal: $e';
      });
    }
  }

  // ---------- LANGKAH 4: Submit presensi ----------
  // Catatan: ble_proof_token masih dummy karena BLE beneran belum jalan
  // (lihat _startBleScan). Backend/mock kemungkinan akan menolak field ini
  // sampai BLE diimplementasi -- itu WAJAR untuk tahap ini.
  Future<void> _submitPresensi() async {
    setState(() => _step = _PresensiStep.submitting);

    try {
      final dio = ref.read(dioClientProvider);

      // Kalau karena suatu sebab belum ada device_id tersimpan (misal
      // registrasi background sempat gagal), coba daftarkan sekarang juga
      // sebagai fallback -- daripada kirim dummy string yang pasti ditolak
      // backend asli nanti.
      // Pastikan kamu sudah import device_registration_service.dart di atas file ini
      var deviceId = await DeviceRegistrationService.readStoredId('mahasiswa');
      deviceId = await DeviceRegistrationService.ensureRegistered(dio, role: 'mahasiswa');

      await dio.post('/mobile/mahasiswa/presensi', data: {
        'sesi_kelas_id': widget.sesi.id,
        'mobile_device_id': deviceId,
        'face_verification_token': _faceVerificationToken,
        'ble_proof_token': 'dummy-ble-token', // TODO: ganti setelah BLE beneran jalan
        'latitude': _position?.latitude,
        'longitude': _position?.longitude,
      });

      if (!mounted) return;
      setState(() {
        _attendanceRecorded = true;
        _doorUnlockRequested = true;
        _step = _PresensiStep.success;
      });
    } catch (e) {
      appLogger.e('❌ ERROR SUBMIT PRESENSI: $e');
      if (!mounted) return;
      setState(() {
        _step = _PresensiStep.error;
        _errorMessage = 'Gagal mengirim presensi: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Presensi'),
        leading: (_step == _PresensiStep.success || _step == _PresensiStep.error)
            ? IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop())
            : null,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: _buildStepContent()),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case _PresensiStep.permission:
        return const _LoadingStep(label: 'Memeriksa izin lokasi & Bluetooth...');
      case _PresensiStep.scanBle:
        return _LoadingStep(label: 'Menghubungkan ke ${widget.sesi.namaRuangan}...');
      case _PresensiStep.captureFace:
        return FaceCameraCapture(onCaptured: _onFaceCaptured, captureLabel: 'Ambil Foto');
      case _PresensiStep.verifying:
        return const _LoadingStep(label: 'Memverifikasi wajah...');
      case _PresensiStep.submitting:
        return const _LoadingStep(label: 'Mengirim presensi...');
      case _PresensiStep.success:
        return _SuccessStep(
          attendanceRecorded: _attendanceRecorded,
          doorUnlockRequested: _doorUnlockRequested,
          doorUnlockConfirmed: _doorUnlockConfirmed,
          onDone: () => Navigator.of(context).pop(),
        );
      case _PresensiStep.error:
        return _ErrorStep(message: _errorMessage ?? 'Terjadi kesalahan.', onRetry: _startFlow);
    }
  }
}

class _LoadingStep extends StatelessWidget {
  final String label;
  const _LoadingStep({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 20),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Colors.grey)),
      ],
    );
  }
}

class _SuccessStep extends StatelessWidget {
  final bool attendanceRecorded;
  final bool doorUnlockRequested;
  final bool doorUnlockConfirmed;
  final VoidCallback onDone;

  const _SuccessStep({
    required this.attendanceRecorded,
    required this.doorUnlockRequested,
    required this.doorUnlockConfirmed,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, size: 72, color: Colors.green.shade400),
        const SizedBox(height: 20),
        const Text('Presensi Selesai', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _StatusLine(label: 'Kehadiran tercatat', done: attendanceRecorded),
        const SizedBox(height: 8),
        _StatusLine(
          label: doorUnlockConfirmed ? 'Pintu terkonfirmasi terbuka' : 'Menunggu konfirmasi pintu...',
          done: doorUnlockConfirmed,
          pending: doorUnlockRequested && !doorUnlockConfirmed,
        ),
        const SizedBox(height: 32),
        ElevatedButton(onPressed: onDone, child: const Text('Kembali ke Beranda')),
      ],
    );
  }
}

class _StatusLine extends StatelessWidget {
  final String label;
  final bool done;
  final bool pending;
  const _StatusLine({required this.label, required this.done, this.pending = false});

  @override
  Widget build(BuildContext context) {
    final color = done ? Colors.green : (pending ? Colors.orange : Colors.grey);
    final icon = done ? Icons.check_circle : (pending ? Icons.hourglass_top : Icons.circle_outlined);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ErrorStep extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorStep({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
      ],
    );
  }
}