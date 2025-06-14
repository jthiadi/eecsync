import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Home/HomePage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Data/UserData.dart';
import '../Calendar/CalendarPage.dart';
import 'dart:async';
import 'package:hive/hive.dart';
import 'package:flutter/cupertino.dart';
import '../Data/UserData.dart';
import 'package:provider/provider.dart';
import '../widgets/theme.dart';

class GradientText extends StatelessWidget {
  const GradientText({
    Key? key,
    required this.text,
    this.style,
    required this.gradient,
  }) : super(key: key);
  final String text;
  final TextStyle? style;
  final Gradient gradient;
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return gradient.createShader(
          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
        );
      },
      blendMode: BlendMode.srcIn,
      child: Text(text, style: style),
    );
  }
}

List<Map<String, dynamic>> getCoursesBySemester(int semester) {
  print(
    UserData().coursestaken
        .where((course) => course['semester'] == semester)
        .toList(),
  );
  return UserData().coursestaken
      .where((course) => course['semester'] == semester)
      .toList();
}

class PreviewPage extends StatefulWidget {
  const PreviewPage({super.key});

  @override
  _PreviewPage createState() => _PreviewPage();
}

class _PreviewPage extends State<PreviewPage>
    with SingleTickerProviderStateMixin {
  final double gpa = UserData().gpa;
  final int credits = UserData().credits;
  final int withdrawals = UserData().withdrawals;
  final int coursesPassed = UserData().passed;
  final int rank = UserData().rank[UserData().semester-2];

  late AnimationController _controller;
  late Animation<Offset> _slideGPA;
  late Animation<Offset> _slideCredits;
  late Animation<Offset> _slideWithdrawals;
  late Animation<Offset> _slideCoursesPassed;
  late Animation<Offset> _slideRank;
  late Animation<double> _fadeAnimation;

  final scrollController = ScrollController();

  List<Map<String, dynamic>> courses = getCoursesBySemester(
    UserData().semester - 1,
  );

  @override
  void initState() {
    super.initState();
    //_scrollController = ScrollController();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    );

    _slideGPA = Tween<Offset>(
      begin: Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );

    _slideCredits = Tween<Offset>(
      begin: Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.2, 0.4, curve: Curves.easeOut),
      ),
    );

    _slideWithdrawals = Tween<Offset>(
      begin: Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.4, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideCoursesPassed = Tween<Offset>(
      begin: Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.6, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideRank = Tween<Offset>(
      begin: Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.8, 1.0, curve: Curves.easeOut),
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Start the animation after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    //_scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [Color(0xFF422E5A), Color(0xFF1C1B33)]  // dark
              : [Color(0xFF3B1E45), Color(0xFF7D459A)], // light
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
      ),),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Stack(
            children: [
              // Align(alignment: Alignment(0, 1),
              //   child: Image.asset('assets/loadingbg2.png',scale: 0.9,),
              // ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Align(
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/loadingbg2.png',
                      width: constraints.maxWidth,
                      fit: BoxFit.fitWidth,
                    ),
                  );
                },
              ),
              Align(
                alignment: Alignment(0.9, -0.88),
                child: Padding(
                  padding: EdgeInsets.only(right: 11),
                  child: Text(
                    '114-${UserData().id} ${UserData().name}',
                    style: GoogleFonts.battambang(
                      fontSize: 12,
                      color: Color(0xFFEBEAEC),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment(-1, -0.75),
                child: Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: Text(
                    'Hello,',
                    style: GoogleFonts.poppins(
                      fontSize: 23.98,
                      color: MyTheme.getSettingsTextColor(isDarkMode),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment(-1, -0.7),
                child: Padding(
                  padding: EdgeInsets.only(left: 15),
                  child: GradientText(
                    text: UserData().chinese_name,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF9F9F9), Color(0xFFF0FF9A)],
                      stops: [0, 1],
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 96,
                      color: Color(0xFFDFDFDF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // === GRAPH SECTION ===
              Align(
                alignment: Alignment(-10, 0.32),
                child: Padding(
                  padding: EdgeInsets.only(top: 300, bottom: 270, right: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ==>> GPA GRAPH
                      SlideTransition(
                        position: _slideGPA,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final maxBarWidth = constraints.maxWidth * 0.5;
                            final gpaWidth = (gpa / 4.3) * maxBarWidth;
                            return Row(
                              children: [
                                Container(
                                  width: gpaWidth,
                                  height: 15,
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Color(0xFFC8C1F2):Color(0xFF7151A3),
                                    borderRadius: BorderRadius.horizontal(
                                      right: Radius.circular(10),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        //spreadRadius: 5,
                                        blurRadius: 5,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  '${gpa.toStringAsFixed(1)}/4.3 GPA',
                                  style: GoogleFonts.poppins(
                                    color: Color(0xFFC4B9F1),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 15),

                      // ==>> CREDITS GRAPH
                      SlideTransition(
                        position: _slideCredits,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final maxBarWidth = constraints.maxWidth * 0.5;
                            final creditsWidth = (credits / 128) * maxBarWidth;
                            return Row(
                              children: [
                                Container(
                                  width: creditsWidth,
                                  height: 15,
                                  decoration: BoxDecoration(
                                    color: isDarkMode? Color(0xFFBAC5EC):Color(0xFF4559B7),
                                    borderRadius: BorderRadius.horizontal(
                                      right: Radius.circular(10),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        //spreadRadius: 5,
                                        blurRadius: 5,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  '${credits.toStringAsFixed(0)}/128 Credits',
                                  style: GoogleFonts.poppins(
                                    color: Color(0xFFACC5F5),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 15),

                      // ==>> WITHDRAWALS GRAPH
                      SlideTransition(
                        position: _slideWithdrawals,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final maxBarWidth = constraints.maxWidth * 0.5;
                            final withdrawalWidth =
                                (withdrawals / 128) * maxBarWidth;
                            return Row(
                              children: [
                                Container(
                                  width: withdrawalWidth,
                                  height: 15,
                                  decoration: BoxDecoration(
                                    color: isDarkMode? Color(0xFF8ECADA): Color(0xFF4699B1),
                                    borderRadius: BorderRadius.horizontal(
                                      right: Radius.circular(10),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        //spreadRadius: 5,
                                        blurRadius: 5,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  '${withdrawals.toStringAsFixed(0)} Withdrawals',
                                  style: GoogleFonts.poppins(
                                    color: Color(0xFF6FD8D6),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 15),

                      // ==>> COURSES PASSED GRAPH
                      SlideTransition(
                        position: _slideCoursesPassed,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final maxBarWidth = constraints.maxWidth * 0.5;
                            final coursesPassedWidth =
                                (coursesPassed / 128) * maxBarWidth;
                            return Row(
                              children: [
                                Container(
                                  width: coursesPassedWidth,
                                  height: 15,
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Color(0xFF9FD1BC) : Color(0xFF5D9A53),
                                    borderRadius: BorderRadius.horizontal(
                                      right: Radius.circular(10),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        //spreadRadius: 5,
                                        blurRadius: 5,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  '${coursesPassed.toStringAsFixed(0)} Courses Passed',
                                  style: GoogleFonts.poppins(
                                    color: Color(0xFF9BCC90),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 15),

                      // ==>> RANK GRAPH
                      SlideTransition(
                        position: _slideRank,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final maxBarWidth = constraints.maxWidth * 0.5;
                            final rankWidth =
                                ((101 - rank) / 100) * maxBarWidth;
                            return Row(
                              children: [
                                Container(
                                  width: rankWidth,
                                  height: 15,
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Color(0xFFFBB887): Color(0xFFB37055),
                                    borderRadius: BorderRadius.horizontal(
                                      right: Radius.circular(10),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        //spreadRadius: 0,
                                        blurRadius: 5,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Rank ${rank.toStringAsFixed(0)}/113',
                                  style: GoogleFonts.poppins(
                                    color: Color(0xFFE3B07C),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ==== RECENT COURSES ====
              Align(
                alignment: Alignment(-1, 0.2),
                child: Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: Text(
                    'RECENT COURSES',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      color: MyTheme.getSettingsTextColor(isDarkMode),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // ==== RECENT COURSES ====
              Align(
                alignment: Alignment(0, 1.1),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 100),
                  child: Container(
                    height: 63,
                    width: 294,

                    //=== SHADOW BOX ===
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: Offset(0, 3),
                          spreadRadius: -3.5,
                        ),
                      ],
                    ),
                    //=== CONTINUE BUTTON ===
                    child: Padding(
                      padding: EdgeInsets.all(5),
                      child: Container(
                        decoration: BoxDecoration(
                          color: MyTheme.getSettingsTextColor(isDarkMode),
                          borderRadius: BorderRadius.circular(38),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Timer(Duration(seconds: 1), () {
                              Navigator.pushReplacement(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => HomePage(),
                                  transitionsBuilder: (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                  transitionDuration: Duration(
                                    milliseconds: 600,
                                  ),
                                ),
                              );
                            });
                          },
                          child: Text(
                            'Continue',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color:
                              Color(0xFF1E1C1F),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ==== RECENT COURSE BOXES & BLUR EFFECT ====
              // Inside your PreviewPage build method
              Align(
                alignment: Alignment(0, 0.5),
                child: Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: SizedBox(
                    height: 165,
                    child: Stack(
                      children: [
                        // LIST
                        RawScrollbar(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          thumbVisibility: true,
                          trackVisibility: true,
                          trackRadius: const Radius.circular(20),
                          radius: const Radius.circular(16),
                          crossAxisMargin: -10,
                          thickness: 12,
                          interactive: true,
                          child: ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.all(10),
                            scrollDirection: Axis.horizontal,
                            itemCount: courses.length,
                            separatorBuilder:
                                (_, _) => const SizedBox(width: 4),
                            itemBuilder: (context, index) {
                              final course = courses[index];
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 160,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.19),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Stack(
                                  children: [
                                    // Title aligned to top-right
                                    Align(
                                      // alignment: Alignment.topRight,
                                      alignment: Alignment.topRight,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          top: 12,
                                          right: 15,
                                          left: 35,
                                        ),
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            return ConstrainedBox(
                                              constraints: BoxConstraints(
                                                maxWidth: 350,
                                              ),
                                              child: Text(
                                                course["name"]!,
                                                textAlign: TextAlign.right,
                                                style: GoogleFonts.dmSans(
                                                  fontSize: 22,
                                                  color: Color(0xFFFFFFFF),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),

                                    // Grade positioned at bottom-left
                                    Positioned(
                                      left: 15,
                                      bottom: -6,
                                      child: Text(
                                        course["gpa"]!,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 64,
                                          color: isDarkMode ? Color(0xFFFBB887): Color(0xFFB37055),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        // RECENT COURSES RIGHT SIDE BLUR EFFECT
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: IgnorePointer(
                            child: Container(
                              width: 70, // Width of the blur effect
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(
                                      0.05,
                                    ), //tambah gelap
                                  ],
                                ),
                              ),
                              child: ClipRect(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 2,
                                    sigmaY: 2,
                                  ),
                                  child: Container(color: Colors.transparent),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
