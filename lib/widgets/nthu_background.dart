import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NthuBackground extends StatelessWidget {
  final double bottom;

  const NthuBackground({this.bottom = 10, super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottom,
      left: 0,
      right: 0,
      child: Opacity(
        opacity: 0.02,
        child: Text(
          'NTHU\nNTHU\nNTHU',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 98,
            color: const Color(0xFFF0EEEE),
            height: 1.27,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}