import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'course_info.dart';
import '../Data/UserData.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Calendar/schedule_data.dart';
import '../Data/course_rec_data.dart';
import 'result.dart';
import 'package:hive/hive.dart';
import '../Data/CourseData.dart';
import 'package:provider/provider.dart';
import '../widgets/theme.dart';

enum CourseStatus { available, selected, conflict }

class CourseRecommendation {
  final String id;
  final String code;
  final String name;
  final String professor;
  final CourseStatus status;
  final String department;
  final String? conflictReason;
  final String? conflictWith;
  final int credits;
  final String? syllabus;
  final String? grading;
  final String? location;
  final String time;

  CourseRecommendation({
    required this.id,
    required this.code,
    required this.name,
    required this.professor,
    this.status = CourseStatus.available,
    required this.department,
    this.conflictReason,
    this.conflictWith,
    this.credits = 3, 
    this.syllabus,
    this.grading,
    this.location,
    required this.time,
  });

  CourseRecommendation copyWith({
    String? id,
    String? code,
    String? name,
    String? professor,
    CourseStatus? status,
    String? department,
    String? conflictReason,
    String? conflictWith,
    int? credits,
    String? syllabus,
    String? grading,
    String? location,
    String? time,
  }) {
    return CourseRecommendation(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      professor: professor ?? this.professor,
      status: status ?? this.status,
      department: department ?? this.department,
      conflictReason: conflictReason ?? this.conflictReason,
      conflictWith: conflictWith ?? this.conflictWith,
      credits: credits ?? this.credits,
      syllabus: syllabus ?? this.syllabus,
      grading: grading ?? this.grading,
      location: location ?? this.location,
      time: time ?? this.time,
    );
  }
}

// Generate dummy conflict data for testing
// List<CourseRecommendation> generateConflictData(
//   List<CourseRecommendation> recommendations,
// ) {
//   // Sample conflict reasons

//   // Create a new list with some random conflicts
//   final result = List<CourseRecommendation>.from(recommendations);

//   // Simulate some conflicts (for demonstration)
//   // In a real app, this would be calculated based on actual schedules
//   for (int i = 0; i < result.length; i++) {
//     if (result[i].status == CourseStatus.conflict) {
//       // Find another course to conflict with
//       final conflictWithIndex = (i + 2) % result.length;
//       final conflictWith = result[conflictWithIndex].name;

//       // Update with conflict information
//       result[i] = result[i].copyWith(conflictWith: conflictWith);
//     }
//   }

//   return result;
// }

List<CourseRecommendation> resetRecommendationsStatus(
    List<CourseRecommendation> recommendations,
    ) {
  return recommendations
      .map(
        (course) =>
        course.copyWith(status: CourseStatus.available, conflictWith: null),
  )
      .toList();
}

class RecommendationList extends StatefulWidget {
  final List<CourseRecommendation> recommendations;
  final Function(String courseId, CourseStatus newStatus) onCourseStatusChanged;
  final VoidCallback updateCourseStatus;
  final Function(CourseRecommendation) updatealter;

  const RecommendationList({
    Key? key,
    required this.recommendations,
    required this.onCourseStatusChanged,
    required this.updateCourseStatus,
    required this.updatealter,
  }) : super(key: key);

  @override
  State<RecommendationList> createState() => _RecommendationListState();
}

class _RecommendationListState extends State<RecommendationList>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _createAnimations();

    _animationController.forward();
  }

  @override
  void didUpdateWidget(RecommendationList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.recommendations != oldWidget.recommendations) {
      _createAnimations();
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _createAnimations() {
    final count = widget.recommendations.length;

    _animationController.duration = Duration(seconds: count);

    _slideAnimations = List.generate(count, (index) {
      final begin = const Offset(1.0, 0.0);
      final end = Offset.zero;

      final startInterval = index / count;
      final endInterval = (index + 1) / count;

      return Tween(begin: begin, end: end).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(startInterval, endInterval, curve: Curves.easeInOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.recommendations.isEmpty) {
      return Center(
        child: Text(
          'No courses found',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(30, 0, 0, 70),
        itemCount: widget.recommendations.length,
        itemBuilder: (context, index) {
          final course = widget.recommendations[index];
          final rank = index + 1;

          return SlideTransition(
            position: _slideAnimations[index],
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RecommendationCard(
                rank: rank,
                course: course,
                onStatusChanged: (newStatus) {
                  widget.onCourseStatusChanged(course.id, newStatus);
                  widget.updateCourseStatus();
                },
                updatealter: widget.updatealter,
              ),
            ),
          );
        },
      );
    }
  }
}

class RecommendationCard extends StatefulWidget {
  final int rank;
  CourseRecommendation course;
  final Function(CourseStatus) onStatusChanged;
  final Function(CourseRecommendation) updatealter;

  RecommendationCard({
    Key? key,
    required this.rank,
    required this.course,
    required this.onStatusChanged,
    required this.updatealter,
  }) : super(key: key);

  @override
  State<RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<RecommendationCard>
    with SingleTickerProviderStateMixin {
  // Animation controller for the + button
  late AnimationController _addButtonAnimController;
  bool _isAnimating = false;
  bool _showConflictDetails = false;
  bool isloading = false;

  @override
  void initState() {
    super.initState();

    _addButtonAnimController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _addButtonAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isAnimating = false;
        });

        if (widget.course.status == CourseStatus.available) {
          widget.onStatusChanged(CourseStatus.selected);
        }
      }
    });
  }

  // Future<void> _findalternative() async {
  //   final response = await generate_alternative(widget.course.id);
  //   print(response);
  //   final courseBox = await Hive.openBox<CourseData>('all_courses');
  //   final alternative = courseBox.values.firstWhere(
  //     (course) => response[0] == course.id,
  //   );
  //   final course_rec = await format_result(response);
  //   print(course_rec);
  //   setState(() {
  //     //sementaraa
  //     widget.course = CourseRecommendation(
  //       id: alternative.id,
  //       code: alternative.id,
  //       name: alternative.name,
  //       professor: alternative.professor,
  //       status: CourseStatus.available,
  //       department:
  //           RegExp(r'[A-Za-z]+')
  //               .allMatches(alternative.id)
  //               .map((match) => match.group(0))
  //               .where((letters) => letters != null)
  //               .join(),
  //       credits: alternative.credit,
  //       syllabus: alternative.syllabus,
  //       grading: alternative.grading,
  //       location: alternative.location,
  //       time: alternative.classTime!,
  //     );

  //   });
  // }

  @override
  void dispose() {
    _addButtonAnimController.dispose();
    super.dispose();
  }

  Color _getDepartmentColor() {
    switch (widget.course.department) {
      case 'EECS':
        return const Color(0xFF9BAEFF); // blue for EECS
      case 'CS':
        return const Color(0xFF73B679); // green for CS
      case 'EE':
        return const Color(0xFFFFA978); // orange for EE
      default:
        return const Color(0xFFB89FDA); // light purple others
    }
  }

  void _toggleConflictDetails() {
    setState(() {
      _showConflictDetails = !_showConflictDetails;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget actionButton;

    switch (widget.course.status) {
      case CourseStatus.available:
        actionButton = _buildAddButton();
        break;
      case CourseStatus.selected:
        actionButton = _buildSelectedButton();
        break;
      case CourseStatus.conflict:
        actionButton = _buildConflictButton();
        break;
    }

    Color cardColor = _getDepartmentColor();

    if (widget.course.status == CourseStatus.conflict) {
      cardColor = const Color(0xFF9F9F9F); // Red
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 36,
              child: Column(
                children: [
                  Text(
                    '${widget.rank}.',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  actionButton,
                ],
              ),
            ),

            const SizedBox(width: 8),

            // course card 
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // course details
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.course.code,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${widget.course.credits} cr',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                widget.course.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                widget.course.professor,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              if (widget.course.status == CourseStatus.conflict)
                                GestureDetector(
                                  onTap: _toggleConflictDetails,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      Container(
                        width: 36,
                        child: IconButton(
                          icon: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => CourseDetailPage(
                                  courseCode: widget.course.code,
                                  courseName: widget.course.name,
                                  professor: widget.course.professor,
                                  credits: widget.course.credits,
                                  department: widget.course.department,
                                  syllabus: widget.course.syllabus,
                                  grading: widget.course.grading,
                                  location: widget.course.location,
                                  time: widget.course.time,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        if (_showConflictDetails &&
            widget.course.status == CourseStatus.conflict)
          isloading
              ? Center(
            key: const ValueKey('loading'),
            child: CircularProgressIndicator(color: Colors.white),
          )
              : AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(left: 44, top: 8, right: 30),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conflict Details:',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.course.conflictWith != null
                      ? 'This course conflicts with ${widget.course.conflictWith}'
                      : 'This course conflicts with your current schedule.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // show alternatives or open a resolution dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Showing alternative courses...',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          setState(() {
                            isloading = true;
                          });
                          await widget.updatealter(widget.course);
                          setState(() {
                            isloading = false;
                            _showConflictDetails = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF582A6D),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'FIND ALTERNATIVE',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAddButton() {
    return RotationTransition(
      turns: Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _addButtonAnimController,
          curve: Curves.easeInOut,
        ),
      ),
      child: IconButton(
        icon: const Icon(Icons.add, color: Colors.white),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        iconSize: 20,
        onPressed:
        _isAnimating
            ? null
            : () {
          if (!UserData().recommended.contains(widget.course.id)) {
            FirebaseFirestore.instance
                .collection('Student')
                .doc(UserData().id)
                .collection('RECOMMENDED')
                .doc(widget.course.id)
                .set({});
          }
          UserData().recommended.add(widget.course.code);
          print(widget.course.time);
          addusedslot(widget.course.time);
          print(UserData().usedslot);
          print(UserData().recommended);
          Map<String, dynamic> temp = {
            'title': widget.course.name,
            'code': widget.course.code,
            'location': widget.course.location,
            'scheduleString': widget.course.time,
            'referenceDate': 1,
            'isWeekly': true,
            'isRecommended': true,
          };
          addNewCourse(temp);
          print(scheduleData);
          setState(() {
            _isAnimating = true;
          });
          _addButtonAnimController.reset();
          _addButtonAnimController.forward();
        },
      ),
    );
  }

  Widget _buildSelectedButton() {
    return IconButton(
      icon: const Icon(Icons.check, color: Colors.green),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      iconSize: 20,
      onPressed: () {
        try {
          FirebaseFirestore.instance
              .collection('Student')
              .doc(UserData().id)
              .collection('RECOMMENDED')
              .doc(widget.course.id)
              .delete();
          print('deleted from recommended.');
        } catch (e) {
          print('Error deleting recommended course: $e');
        }
        var tmp = extractSlots(widget.course.time);
        for(var i in tmp){
          removeusedslot(i);
        }
        if (UserData().recommended.contains(widget.course.id))
          UserData().recommended.remove(widget.course.id);
        print(UserData().usedslot);
        Map<String, dynamic> temp = {
          'title': widget.course.name,
          'code': widget.course.code,
          'location': widget.course.location,
          'scheduleString': widget.course.time,
          'referenceDate': 1,
          'isWeekly': true,
          'isRecommended': true,
        };
        removeOldCourse(temp);
        widget.onStatusChanged(CourseStatus.available);
      },
    );
  }

  Widget _buildConflictButton() {
    return IconButton(
      icon: const Icon(
        Icons.close, 
        color: Colors.red, 
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      iconSize: 20,
      tooltip: 'Schedule conflict',
      onPressed: () {
        print(widget.course.time);
        print(scheduleData);
        print(UserData().usedslot);
        _toggleConflictDetails();
      },
    );
  }
}
