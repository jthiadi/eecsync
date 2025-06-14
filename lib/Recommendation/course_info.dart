import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_scaffold.dart';
import '../Home/HomePage.dart';
import '../main.dart';
import '../Data/CourseData.dart';
import 'package:provider/provider.dart';
import '../widgets/theme.dart';

class CourseDetailPage extends StatelessWidget {
  final String courseCode;
  final String courseName;
  final String professor;
  final int credits;
  final String department;
  final String? syllabus;
  final String? grading;
  final String? location;
  final String time;

  const CourseDetailPage({
    Key? key,
    required this.courseCode,
    required this.courseName,
    required this.professor,
    required this.credits,
    required this.department,
    this.syllabus,
    this.grading,
    this.location,
    required this.time,
  }) : super(key: key);

  String generate_time(String schedule) {
    String ret = '';
    if (schedule.contains('M')) {
      if (ret == '')
        ret += 'MON';
      else
        ret += ', MON';
    }
    if (schedule.contains('T')) {
      if (ret == '')
        ret += 'TUE';
      else
        ret += ', TUE';
    }
    if (schedule.contains('W')) {
      if (ret == '')
        ret += 'WED';
      else
        ret += ', WED';
    }
    if (schedule.contains('R')) {
      if (ret == '')
        ret += 'THR';
      else
        ret += ', THR';
    }
    if (schedule.contains('F')) {
      if (ret == '')
        ret += 'FRI';
      else
        ret += ', FRI';
    }
    if (schedule.contains('S')) {
      if (ret == '')
        ret += 'SAT';
      else
        ret += ', SAT';
    }
    if (schedule.contains('U')) {
      if (ret == '')
        ret += 'SUN';
      else
        ret += ', SUN';
    }

    return ret;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return AppScaffold(
      currentIndex: 1,
      backgroundGradient: isDarkMode? LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF100729),
          Color(0xFF2B2141),
          MyTheme.getSettingsTextColor(isDarkMode),
        ],
        stops: [0.0, 0.39, 0.74],
      ) : LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF2B1735),
          Color(0xFF582A6D),
          MyTheme.getSettingsTextColor(isDarkMode) 
        ],
        stops: [0.0, 0.39, 0.74],
      ),
      showBottomNav: false,
      onNavItemTapped: (index) {
        homePageKey.currentState?.setCurrentIndex(index);
        Navigator.of(context).pop();
      },
      body: Stack(
        children: [
          Positioned(
            top: 3,
            left: 3,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: MyTheme.getSettingsTextColor(isDarkMode)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Main content 
          Padding(
            padding: const EdgeInsets.only(top: 0),
            child: Stack(
              children: [
                // Curved white bg
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: MyTheme.getSettingsTextColor(isDarkMode),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(166),
                      topRight: Radius.circular(0),
                    ),
                  ),
                ),

                Positioned(
                  top: 260,
                  right: -10,
                  child: Image.asset(
                    'assets/images/panda_sit.png',
                    height: 350,
                    width: 300,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Container(
                                width: double.infinity,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end, 
                                  children: [
                                    _buildRightAlignedText(
                                      courseCode,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFC8C8C8),
                                    ),

                                    _buildRightAlignedText(
                                      courseName,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF904F91),
                                    ),

                                    _buildRightAlignedText(
                                      professor,
                                      fontSize: 14,
                                      color: const Color(0xFFD6A8D7),
                                    ),

                                    Padding(
                                      padding: const EdgeInsets.only(top: 2), 
                                      child: _buildRightAlignedText(
                                        '$credits CREDITS  CLASS  ${generate_time(time)}  $location',
                                        fontSize: 12,
                                        color: const Color(0xFF8F7B8B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),


                      const SizedBox(height: 30),

                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader('Grading Criteria'),
                                if (grading != null && grading!.isNotEmpty)
                                  ...grading!
                                      .split('\n')
                                      .where(
                                        (grading) => grading.trim().isNotEmpty,
                                      )
                                      .map(
                                        (grading) =>
                                            _buildSyllabusItem(grading.trim()),
                                      )
                                      .toList()
                                else
                                  _buildSyllabusItem('No grading available'),

                                const SizedBox(height: 30),

                                _buildSectionHeader('Syllabus'),
                                if (syllabus != null && syllabus!.isNotEmpty)
                                  ...syllabus!
                                      .split('\n')
                                      .where(
                                        (chapter) => chapter.trim().isNotEmpty,
                                      )
                                      .map(
                                        (chapter) =>
                                            _buildSyllabusItem(chapter.trim()),
                                      )
                                      .toList()
                                else
                                  _buildSyllabusItem('No syllabus available'),

                                const SizedBox(height: 60),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
  Widget _buildRightAlignedText(String text, {
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.black,
  }) {
    return Text(
      text,
      textAlign: TextAlign.end,
      style: GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: 1.1, 
      ),
    );
  }
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF813BA1),
        ),
      ),
    );
  }

  Widget _buildSyllabusItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity, 
        alignment: Alignment.centerLeft, 
        child: Text(
          text,
          textAlign: TextAlign.left,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildGradingItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity, 
        alignment: Alignment.centerLeft, 
        child: Text(
          text,
          textAlign: TextAlign.left, 
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
