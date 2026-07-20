import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../jadwal/providers/jadwal_dosen_provider.dart';

/// Ruangan yang bisa di-remote-unlock dosen -- SEMENTARA diturunkan dari
/// GET /mobile/dosen/jadwal (dedupe per ruangan_id), karena API_CONTRACT2.md
/// dan Postman belum punya endpoint khusus "list ruangan milik dosen".
///
/// Ini bukan solusi final -- begitu backend merilis endpoint resmi untuk
/// ini, provider ini yang diganti sumber datanya, tanpa perlu ubah UI
/// (lecturer_room_unlock_screen.dart) karena bentuk datanya (DosenRuangan)
/// tetap sama.
class DosenRuangan {
  final String id;
  final String namaRuangan;

  DosenRuangan({required this.id, required this.namaRuangan});
}

final dosenRuanganListProvider = FutureProvider.autoDispose<List<DosenRuangan>>((ref) async {
  final jadwalList = await ref.watch(jadwalDosenProvider.future);

  final Map<String, DosenRuangan> unik = {};
  for (final j in jadwalList) {
    if (j.ruanganId.isEmpty) continue;
    unik[j.ruanganId] = DosenRuangan(id: j.ruanganId, namaRuangan: j.namaRuangan);
  }

  return unik.values.toList();
});