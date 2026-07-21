import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

/// Kamera real-time buat capture wajah -- dipakai BERSAMA oleh presensi
/// (presensi_flow_screen.dart) dan pendaftaran wajah pertama kali
/// (face_enroll_screen.dart), supaya logic kamera cuma ada di 1 tempat.
class FaceCameraCapture extends StatefulWidget {
  final void Function(String imagePath) onCaptured;
  final String captureLabel;

  const FaceCameraCapture({
    super.key,
    required this.onCaptured,
    this.captureLabel = 'Ambil Foto',
  });

  @override
  State<FaceCameraCapture> createState() => _FaceCameraCaptureState();
}

class _FaceCameraCaptureState extends State<FaceCameraCapture> {
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isCapturing = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    setState(() {
      _cameraError = null;
      _isInitializing = true;
    });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _cameraError = 'Tidak ada kamera yang terdeteksi di perangkat ini.';
          _isInitializing = false;
        });
        return;
      }

      final frontCamera = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(frontCamera, ResolutionPreset.medium, enableAudio: false);
      await _controller!.initialize();

      if (mounted) setState(() => _isInitializing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = 'Gagal membuka kamera: $e';
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);
    try {
      final XFile file = await controller.takePicture();
      widget.onCaptured(file.path);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _cameraError = 'Gagal mengambil foto: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Membuka kamera...', style: TextStyle(fontSize: 15, color: Colors.grey)),
        ],
      );
    }

    if (_cameraError != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam_off, size: 56, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          Text(_cameraError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _initCamera, child: const Text('Coba Lagi')),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: SizedBox(
            width: 260,
            height: 260,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.previewSize?.height ?? 260,
                height: _controller!.value.previewSize?.width ?? 260,
                child: CameraPreview(_controller!),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Posisikan wajah di tengah', style: TextStyle(fontSize: 15, color: Colors.grey)),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: _isCapturing ? null : _capture,
          icon: _isCapturing
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.camera_alt),
          label: Text(_isCapturing ? 'Memproses...' : widget.captureLabel),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
        ),
      ],
    );
  }
}