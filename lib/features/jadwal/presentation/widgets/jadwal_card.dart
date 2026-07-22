import 'package:flutter/material.dart';
import '../../data/jadwal_model.dart';

/// Card jadwal — dipakai bareng mahasiswa & dosen.
class JadwalCard extends StatelessWidget {
  final Jadwal jadwal;
  final VoidCallback? onTap;
  final Color accentColor;

  const JadwalCard({
    super.key,
    required this.jadwal,
    this.onTap,
    this.accentColor = const Color(0xFF6750A4),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 52,
              child: Column(
                children: [
                  Text(jadwal.jamMulai, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Icon(Icons.more_vert, size: 14, color: Colors.grey.shade400),
                  const SizedBox(height: 4),
                  Text(jadwal.jamSelesai, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 3,
              height: 68,
              decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(jadwal.namaRombel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 15, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(child: Text(jadwal.namaRuangan, style: TextStyle(color: Colors.grey.shade700, fontSize: 13))),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 15, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(child: Text(jadwal.namaDosen, style: TextStyle(color: Colors.grey.shade700, fontSize: 13))),
                    ],
                  ),
                ],
              ),
            ),
            if (onTap != null) Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}