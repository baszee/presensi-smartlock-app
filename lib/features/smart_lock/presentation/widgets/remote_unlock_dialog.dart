import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../sesi_kelas/providers/remote_unlock_provider.dart';

/// Dialog konfirmasi password sebelum remote unlock -- dipakai bareng oleh
/// card sesi di Home dan list ruangan (lecturer_room_unlock_screen.dart),
/// supaya nggak dobel kode dan perilakunya selalu konsisten.
void showRemoteUnlockDialog(
    BuildContext context,
    WidgetRef ref, {
      required String ruanganId,
      String alasan = 'Membuka kelas',
    }) {
  final passwordController = TextEditingController();
  bool isLoading = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Keamanan Smart Lock', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Masukkan password Anda untuk mengonfirmasi akses pembukaan pintu.'),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(ctx),
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                  if (passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password tidak boleh kosong!')),
                    );
                    return;
                  }

                  setState(() => isLoading = true);
                  await ref.read(remoteUnlockProvider.notifier).unlockDoor(
                    ruanganId,
                    passwordController.text,
                    alasan: alasan,
                  );
                  final unlockState = ref.read(remoteUnlockProvider);
                  setState(() => isLoading = false);

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    if (unlockState.status == UnlockStatus.success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(unlockState.message ?? 'Pintu berhasil dibuka!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(unlockState.message ?? 'Gagal membuka pintu'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text('Buka Pintu'),
              ),
            ],
          );
        },
      );
    },
  );
}