import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Transcript/transcript.dart';
import '../Search/search.dart';
import '../Data/UserData.dart';
import 'package:provider/provider.dart';
import 'package:finalproject/widgets/theme.dart';

class TopSection extends StatelessWidget {
  final int currentIndex;
  final LinearGradient backgroundGradient;
  final ValueChanged<int>? onNavItemTapped;

  const TopSection({
    Key? key,
    required this.currentIndex,
    required this.backgroundGradient,
    this.onNavItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(15),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 19),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          print(UserData().buildSemesterData());

                          if (onNavItemTapped != null) {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                ) {
                                  return Transcript(
                                    currentIndex: currentIndex,
                                    onNavItemTapped: onNavItemTapped!,
                                  );
                                },
                                transitionsBuilder:
                                    (_, animation, __, child) => FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                transitionDuration: Duration(milliseconds: 300),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/Panda_back.png',
                                  width: 40,
                                  height: 40,
                                ),
                                CircleAvatar(
                                  radius: 13,
                                  backgroundColor: Colors.white,
                                  child: ClipOval(
                                    child:
                                        UserData().profile == ''
                                            ? Icon(
                                              Icons.person,
                                              color: Color(0xFF6F4F7E),
                                              size: 20,
                                            )
                                            : Image.network(
                                              UserData().profile ?? '',
                                              width: 26,
                                              height: 26,
                                              fit: BoxFit.cover,
                                            ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 8),
                            Text(
                              '${UserData().chinese_name}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: MyTheme.getSettingsSectionTitleColor(
                                  isDarkMode,
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${UserData().id} ${UserData().name}',
                        style: GoogleFonts.poppins(
                          color: MyTheme.getSettingsTextColor(isDarkMode),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(bottom: 14),
                    child: Stack(
                      children: [
                        Center(
                          child: ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback:
                                (bounds) => LinearGradient(
                                  colors: [
                                    Color(0xFFFBFBFB),
                                    Color(0xFFE1ADFF),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ).createShader(bounds),
                            child: Text(
                              'eecsync',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 2,
                          top: 0,
                          bottom: 0,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                  ) {
                                    return SearchPage(
                                      currentIndex: currentIndex,
                                      backgroundGradient: backgroundGradient,
                                      onNavItemTapped: onNavItemTapped!,
                                    );
                                  },
                                  transitionsBuilder:
                                      (_, animation, __, child) =>
                                          FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          ),
                                  transitionDuration: Duration(
                                    milliseconds: 300,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: MyTheme.getSettingsTextColor(
                                    isDarkMode,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.search,
                                color: MyTheme.getSettingsTextColor(isDarkMode),
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Text(
                      '${UserData().gpa.toStringAsFixed(1)} GPA   |   ${UserData().rank[UserData().semester - 2]} RANK   |   ${UserData().passed + UserData().withdrawals} COURSES',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color:
                            isDarkMode ? Color(0xFFF6E1FF) : Color(0xFF6F4F7E),
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
