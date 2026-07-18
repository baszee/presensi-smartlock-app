import 'package:flutter/material.dart';

/// Widget pemilih hari — dipakai bareng mahasiswa & dosen.
/// Full custom (bukan ChoiceChip), jadi tidak ada icon centang otomatis.
class HariPicker extends StatelessWidget {
  final List<String> hariList;
  final String selectedHari;
  final ValueChanged<String> onSelected;
  final Color accentColor;

  const HariPicker({
    super.key,
    required this.hariList,
    required this.selectedHari,
    required this.onSelected,
    this.accentColor = const Color(0xFF6750A4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: hariList.length,
        itemBuilder: (context, index) {
          final hari = hariList[index];
          final isSelected = hari == selectedHari;

          return GestureDetector(
            onTap: () => onSelected(hari),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? accentColor : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                hari,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}