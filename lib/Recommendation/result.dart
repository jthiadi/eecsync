import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/nthu_background.dart';
import '../main.dart';
import '../Recommendation/chart.dart';
import '../Recommendation/recom_list.dart';
import 'dart:math' as math;
import '../Data/course_rec_data.dart';
import '../Calendar/schedule_data.dart';
import '../Data/UserData.dart';
import 'package:provider/provider.dart';
import '../widgets/theme.dart';
import 'package:hive/hive.dart';
import '../Data/CourseData.dart';

class RecommendationPage extends StatefulWidget {
  final int targetCredits;
  final List<Map<String, dynamic>> selectedCourseTypes;
  final bool randomizeChoices;

  const RecommendationPage({
    Key? key,
    required this.targetCredits,
    required this.selectedCourseTypes,
    required this.randomizeChoices,
  }) : super(key: key);

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage>
    with TickerProviderStateMixin {
  late List<CourseRecommendation> recommendations = [];
  late int currentTotalCredits = 0;
  bool isLoading = true;
  bool noalternative = false;

  late AnimationController? _refreshAnimController;

  @override
  void initState() {
    super.initState();
    _refreshAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadRecommendations();
  }

  Future<void> _findalternative(CourseRecommendation course) async {
    setState(() {
      noalternative = false;
    });
    final response = await generate_alternative(course.id);
    print(response);
    final courseBox = await Hive.openBox<CourseData>('all_courses');
    final course_rec = await format_result(response);
    print(course_rec);
    int index = 0;
    for (int i = 0; i < recommendations.length; i++) {
      if (recommendations[i].code == course.code) {
        index = i;
        break;
      }
    }
    try {
      final alternative = courseBox.values.firstWhere(
        (course) => response[0] == course.id,
      );
      CourseRecommendation tmp = CourseRecommendation(
        id: alternative.id,
        code: alternative.id,
        name: alternative.name,
        professor: alternative.professor,
        status: CourseStatus.available,
        department:
            RegExp(r'[A-Za-z]+')
                .allMatches(alternative.id)
                .map((match) => match.group(0))
                .where((letters) => letters != null)
                .join(),
        credits: alternative.credit,
        syllabus: alternative.syllabus,
        grading: alternative.grading,
        location: alternative.location,
        time: alternative.classTime!,
      );
      int temp = 0;
      for (var i in recommendations) {
        temp += i.credits;
      }
      setState(() {
        recommendations[index] = tmp;
        currentTotalCredits = temp;
        _updateCourseStatus();
      });
    } catch (e) {
      setState(() {
        noalternative = true;
      });
    }
  }

  Future<void> _loadRecommendations() async {
    final response = await start_get_rec(
      widget.targetCredits,
      widget.selectedCourseTypes,
    );
    final course_rec = await format_result(response);
    print(course_rec);
    int temp = 0;
    for (var i in course_rec) {
      temp += i.credits;
    }

    _refreshAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    setState(() {
      //sementaraa
      recommendations = course_rec;
      _updateCourseStatus();
      currentTotalCredits = temp;
      isLoading = false; 
    });
  }

  Future<void> _refreshRecommendations() async {
    final response = await regenerate_rec(
      widget.targetCredits,
      widget.selectedCourseTypes,
    );
    final course_rec = await format_result(response);
    print(course_rec);
    int temp = 0;
    for (var i in course_rec) {
      temp += i.credits;
    }

    _refreshAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    setState(() {
      //sementaraa
      recommendations = course_rec;
      _updateCourseStatus();
      currentTotalCredits = temp;
      _refreshAnimController?.reset();
      _refreshAnimController?.forward();
      isLoading = false;
    });
  }

  @override
  void dispose() {
    print('babiiiii');
    temp = [];
    _refreshAnimController?.dispose();
    super.dispose();
  }

  // void _generateRecommendations() {
  //   // Define several course options with varying credit values
  //   final List<Map<String, dynamic>> courseOptions = [
  //     {
  //       'code': '11320CS 342300',
  //       'name': 'OPERATING SYSTEMS',
  //       'professor': 'PROFESSOR CHOU PAI-HSIANG 周百祥',
  //       'department': 'CS',
  //       'credits': 3,
  //     },
  //     {
  //       'code': '11320CS 342200',
  //       'name': 'COMPUTER ARCHITECTURE',
  //       'professor': 'PROFESSOR CHENG YU-CHIANG 鄭毓強',
  //       'department': 'CS',
  //       'credits': 3,
  //     },
  //     {
  //       'code': '11320EE 221100',
  //       'name': 'ELECTRONIC CIRCUITS',
  //       'professor': 'PROFESSOR HWANG JENG-KUANG 黃正光',
  //       'department': 'EE',
  //       'credits': 4,
  //     },
  //     {
  //       'code': '11320EECS 452300',
  //       'name': 'MACHINE LEARNING',
  //       'professor': 'PROFESSOR LIN SHI-HAO 林士浩',
  //       'department': 'EECS',
  //       'credits': 3,
  //     },
  //     {
  //       'code': '11320ISS 101200',
  //       'name': 'DATA STRUCTURES',
  //       'professor': 'PROFESSOR CHEN YI-HSIN 陳美玲',
  //       'department': 'Others',
  //       'credits': 3,
  //     },
  //     {
  //       'code': '11320CS 340100',
  //       'name': 'DATABASE SYSTEMS',
  //       'professor': 'PROFESSOR WANG CHENG-HSI 王承熙',
  //       'department': 'CS',
  //       'credits': 3,
  //     },
  //     {
  //       'code': '11320CS 320400',
  //       'name': 'ALGORITHM DESIGN',
  //       'professor': 'PROFESSOR LIU CHAO-TSUNG 劉兆宗',
  //       'department': 'CS',
  //       'credits': 4,
  //     },
  //     {
  //       'code': '11320EE 332100',
  //       'name': 'DIGITAL SIGNAL PROCESSING',
  //       'professor': 'PROFESSOR LIN CHIA-FENG 林嘉豐',
  //       'department': 'EE',
  //       'credits': 3,
  //     },
  //     {
  //       'code': '11320EECS 451200',
  //       'name': 'DATA SCIENCE',
  //       'professor': 'PROFESSOR CHANG CHENG-HUNG 張正宏',
  //       'department': 'EECS',
  //       'credits': 3,
  //     },
  //     {
  //       'code': '11320EECS 350600',
  //       'name': 'COMPUTER VISION',
  //       'professor': 'PROFESSOR YU FANG-YI 余芳儀',
  //       'department': 'EECS',
  //       'credits': 4,
  //     },
  //     {
  //       'code': '11320CS 200100',
  //       'name': 'PROGRAMMING SEMINAR',
  //       'professor': 'PROFESSOR CHANG WEI-CHENG 張維正',
  //       'department': 'CS',
  //       'credits': 1,
  //     },
  //     {
  //       'code': '11320EE 110200',
  //       'name': 'CIRCUIT LABORATORY',
  //       'professor': 'PROFESSOR CHIEN LI-WEI 簡立維',
  //       'department': 'EE',
  //       'credits': 2,
  //     },
  //     {
  //       'code': '11320EECS 220100',
  //       'name': 'DIGITAL DESIGN LAB',
  //       'professor': 'PROFESSOR LEE HUNG-YI 李宏毅',
  //       'department': 'EECS',
  //       'credits': 2,
  //     },
  //     {
  //       'code': '11320CS 310100',
  //       'name': 'TECHNICAL WRITING',
  //       'professor': 'PROFESSOR SUN MING-TAI 孫明泰',
  //       'department': 'CS',
  //       'credits': 1,
  //     },
  //   ];

  //   // Create a new list with random status assignments
  //   final random = math.Random();

  //   // Shuffle the course options to get a random selection
  //   final shuffledOptions = List.from(courseOptions)..shuffle(random);

  //   // Initialize lists and counters
  //   List<Map<String, dynamic>> selectedCourses = [];
  //   int currentCredits = 0;

  //   // Select courses until we reach or are close to the target credits
  //   for (var course in shuffledOptions) {
  //     if (currentCredits + course['credits'] <= widget.targetCredits) {
  //       print('tes');
  //       selectedCourses.add(course);
  //       currentCredits += (course['credits'] ?? 0) as int;
  //     }

  //     // If we've reached or exceeded the target, break
  //     if (currentCredits >= widget.targetCredits) {
  //       break;
  //     }
  //   }

  //   // Update the current total credits
  //   currentTotalCredits = currentCredits;

  //   // Create recommendations with ALWAYS available status
  //   List<CourseRecommendation> tempRecommendations = List.generate(
  //     selectedCourses.length,
  //     (index) {
  //       final course = selectedCourses[index];

  //       return CourseRecommendation(
  //         id: (index + 1).toString(),
  //         code: course['code'],
  //         name: course['name'],
  //         professor: course['professor'],
  //         status: course['status'],
  //         department: course['department'],
  //         credits: course['credits'],
  //         syllabus: course['syllabus'],
  //         grading: course['grading'],
  //         location: course['location'],
  //         time: course['time'],
  //       );
  //     },
  //   );

  //   // Generate conflict data for courses with conflict status
  //   recommendations = tempRecommendations;
  // }

  List<String> extractSlots(String time) {
    final slots = <String>[];
    for (int i = 0; i < time.length - 1; i += 2) {
      slots.add('${time[i]}${time[i + 1]}');
    }
    return slots;
  }

  void _updateCourseStatus2(String courseId, CourseStatus newStatus) {
    setState(() {
      final index = recommendations!.indexWhere(
        (course) => course.id == courseId,
      );
      if (index != -1) {
        recommendations![index] = recommendations![index].copyWith(
          status: newStatus,
        );
      }
    });
  }

  //check conflict
  void _updateCourseStatus() {
    if (recommendations == null) return;
    setState(() {
      final Set<String> localUsedSlot = Set.from(UserData().usedslot);

      for (int i = 0; i < recommendations.length; i++) {
        print(UserData().usedslot);
        final current = recommendations[i];
        if (current.status == CourseStatus.selected) continue;
        final currentSlots = extractSlots(current.time);
        //print(currentSlots);
        String? conflictWith;
        bool hasConflict = false;

        for (var r in recommendations) {
          if (r.status != CourseStatus.selected || r == current) continue;
          List<String> tmp = extractSlots(r.time);
          List<String> tmp2 = extractSlots(current.time);
          for (var j in tmp) {
            if (tmp2.contains(j)) {
              print('kontolll');
              hasConflict = true;
              conflictWith = r.name;
            }
          }
        }

        if (!hasConflict) {
          for (final slot in currentSlots) {
            if (localUsedSlot.contains(slot)) {
              print("tess");
              print(slot);
              print('slotnya: ${localUsedSlot}');
              hasConflict = true;
              conflictWith = 'your existing schedule';
              break;
            }
          }
        }

        recommendations[i] = current.copyWith(
          status: hasConflict ? CourseStatus.conflict : CourseStatus.available,
          conflictWith: hasConflict ? conflictWith : null,
        );
      }
    });
  }

  // to get formatted course codes for display
  String _getDisplayedCourseCodes() {
    final Set<String> uniqueCodes =
        recommendations!.map((course) {
          final codePattern = RegExp(r'[A-Z]+');
          final match = codePattern.firstMatch(course.code.split(' ')[0]);
          return match?.group(0) ?? '';
        }).toSet();

    return uniqueCodes.where((code) => code.isNotEmpty).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    // calculate distribution data based on recomm departments
    Map<String, double> distribution = {
      'EECS': 0,
      'CS': 0,
      'EE': 0,
      'Others': 0,
    };

    // count courses by department
    for (var course in recommendations!) {
      if (distribution.containsKey(course.department)) {
        distribution[course.department] =
            (distribution[course.department] ?? 0) + 1.0;
      } else {
        distribution['Others'] = (distribution['Others'] ?? 0) + 1;
      }
    }

    return AppScaffold(
      currentIndex: 1,
      backgroundGradient:
          isDarkMode
              ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF100729),
                  Color(0xFF2B2141),
                  Color(0xFF392A4F),
                ],
                stops: [0.0, 0.39, 0.74],
              )
              : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2B1735),
                  Color(0xFF582A6D),
                  Color(0xFF813BA1),
                ],
                stops: [0.0, 0.39, 0.74],
              ),

      showBottomNav: true,
      onNavItemTapped: (index) {
        homePageKey.currentState?.setCurrentIndex(index);
        Navigator.of(context).pop();
      },
      body: Stack(
        children: [
          const NthuBackground(),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child:
                isLoading
                    ? Center(
                      key: const ValueKey('loading'),
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Text(
                            'HERE ARE THE\nRECOMMENDATIONS\nFOR YOU',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        CourseDistributionChart(distribution: distribution),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TARGET CREDITS: ${widget.targetCredits} (CURRENT: $currentTotalCredits)',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'CODES: ${_getDisplayedCourseCodes()}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: RotationTransition(
                                  turns: Tween(begin: 0.0, end: 1.0).animate(
                                    CurvedAnimation(
                                      parent:
                                          _refreshAnimController ??
                                          AnimationController(vsync: this),
                                      curve: Curves.easeInOut,
                                    ),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.refresh),
                                    padding: EdgeInsets.zero,
                                    color: const Color(0xFF582A6D),
                                    onPressed: () {
                                      setState(() {
                                        isLoading = true;
                                      });
                                      _refreshRecommendations();
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        Expanded(
                          child: RecommendationList(
                            key: const ValueKey('list'),
                            recommendations: recommendations!,
                            onCourseStatusChanged: _updateCourseStatus2,
                            updateCourseStatus: _updateCourseStatus,
                            updatealter: _findalternative,
                          ),
                        ),
                      ],
                    ),
          ),

          // Floating action button at bottom center
          // Positioned(
          //   bottom: 16,
          //   left: 0,
          //   right: 0,
          //   child: Center(
          //     child: FloatingActionButton(
          //       backgroundColor: Colors.white,
          //       foregroundColor: const Color(0xFF582A6D),
          //       onPressed: () {
          //         // Show dialog to confirm selected courses
          //         final selectedCourses =
          //             recommendations!
          //                 .where((r) => r.status == CourseStatus.selected)
          //                 .toList();
          //         final selectedCredits = selectedCourses.fold(
          //           0,
          //           (sum, course) => sum + course.credits,
          //         );

          //         ScaffoldMessenger.of(context).showSnackBar(
          //           SnackBar(
          //             content: Text(
          //               '${selectedCourses.length} courses added to calendar (${selectedCredits} credits)',
          //             ),
          //             behavior: SnackBarBehavior.floating,
          //           ),
          //         );
          //       },
          //       child: const Icon(Icons.edit_note),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
