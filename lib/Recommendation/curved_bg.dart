import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/theme.dart';

class CurvedBackground extends StatelessWidget {
  const CurvedBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return  CustomPaint(
        painter: CurvedBackgroundPainter(isDarkMode: isDarkMode),  
    );
  }
}

class CurvedBackgroundPainter extends CustomPainter {
  final bool isDarkMode;  

  CurvedBackgroundPainter({required this.isDarkMode});  

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: isDarkMode ? [
          Color(0xFF100729),
          Color(0xFF745BAF),
          Color(0xFF9E79E3),
        ] : [
          Color(0xFF3E1F4D),
          Color(0xFF9048B3),
          Color(0xFFC282E0),
        ],
        stops: const [0.12, 0.48, 0.91],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    final path = Path()
      ..lineTo(0, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.85,
        size.width,
        size.height * 0.55,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}