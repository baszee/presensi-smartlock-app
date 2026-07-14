/// Model ini merepresentasikan satu data Jadwal kuliah.
/// Field-field ini masih perkiraan berdasarkan ERD, nanti bisa
/// disesuaikan lagi setelah API contract dari backend final.
class Jadwal {
  final String id;
  final String mataKuliah;
  final String namaRuangan;
  final String namaDosen;
  final String jamMulai;
  final String jamSelesai;
  final int hari; // 1 = Senin, 2 = Selasa, dst (sesuai ERD: hari int)

  const Jadwal({
    required this.id,
    required this.mataKuliah,
    required this.namaRuangan,
    required this.namaDosen,
    required this.jamMulai,
    required this.jamSelesai,
    required this.hari,
  });
}