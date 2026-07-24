import 'package:flutter/material.dart';

/// Pendekatan ringan untuk logo "G" Google tanpa nambah asset/svg
/// dependency baru. Bukan reproduksi pixel-perfect logo resmi -- kalau
/// butuh akurasi brand penuh, ganti dengan asset resmi (svg/png) dari
/// Google Identity nanti di lib/assets.
class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _GoogleMarkPainter(),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    final stroke = r * 0.42;
    final rect = Rect.fromCircle(center: center, radius: r - stroke / 2);

    void arc(double startDeg, double sweepDeg, Color color) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startDeg * 3.1415926535 / 180, sweepDeg * 3.1415926535 / 180, false, paint);
    }

    arc(-90, 90, const Color(0xFF4285F4)); // blue
    arc(0, 90, const Color(0xFF34A853)); // green
    arc(90, 90, const Color(0xFFFBBC05)); // yellow
    arc(180, 82, const Color(0xFFEA4335)); // red

    // Bar horizontal khas huruf G
    final barPaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(center.dx, center.dy - stroke / 2, r - stroke * 0.15, stroke),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}