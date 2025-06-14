import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/nthu_background.dart';
import 'fill_info.dart';
import 'package:provider/provider.dart';
import '../widgets/theme.dart';

class RecommendationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Stack(
      children: [
        const NthuBackground(),
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 30, 30, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  textAlign: TextAlign.left,
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                    ),
                    children: const [
                      TextSpan(
                          text: 'GET ',
                          style: TextStyle(color: Color(0xFFFFE7F4))),
                      TextSpan(
                          text: 'PERSONAL\nCOURSE\nRECOMMENDATION\n',
                          style: TextStyle(color: Color(0xFFE8FFE7))),
                      TextSpan(
                          text: 'INSTANTLY',
                          style: TextStyle(color: Color(0xFFFFE7F4))),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          transitionDuration: Duration(milliseconds: 300),
                          pageBuilder: (context, animation, secondaryAnimation) => const ResultPage(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                        ),
                      );
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Color(0xFFE8E0E8) : Color(0xFFFFFFFF),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(38),
                      ),
                      padding:
                      const EdgeInsets.symmetric(horizontal: 135, vertical: 24),
                      elevation: 20,
                      shadowColor: Colors.black,
                    ),
                    child: const Text("Next"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}