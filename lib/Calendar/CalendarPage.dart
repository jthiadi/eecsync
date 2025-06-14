//package imports

import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:marquee/marquee.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../widgets/theme.dart';
//file imports
import 'schedule_data.dart';
import 'Course_Recommender.dart';
import 'CourseType_Box.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Data/UserData.dart';
import '../Recommendation/course_info.dart';
import '../Data/CourseData.dart';
import '../MainJobs/announcement_infopage.dart';

// ======== DEFAULT SETTINGS/PAGE INIT ========
// void main() {
//   runApp(const MyApp());
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const CalendarPage(title: 'Flutter Demo Home Page'),
    );
  }
}
// ===========================================

//TEXT SHRINKER DO NOT TOUCH (experimental)
String forceBreakable(String text) {
  return text.replaceAll(' ', ' \u200B');
}
//======================================

// ============= SIDE PANEL =============
class ScheduleDetailsPanel extends StatefulWidget {
  final ScheduleBox schedule;
  final Animation<double> animation;
  final Function(ScheduleBox?, ScheduleBox?) onClose;
  final Set<String> usedSlots;
  final Set<String> selectedSlots;
  final bool isDragSelection;
  final Function(ScheduleBox) onRemoveOldCourse;

  const ScheduleDetailsPanel({
    required this.schedule,
    required this.animation,
    required this.onClose,
    required this.usedSlots,
    this.selectedSlots = const {},
    required this.isDragSelection,
    required this.onRemoveOldCourse,
    super.key,
  });

  @override
  State<ScheduleDetailsPanel> createState() => _ScheduleDetailsPanelState();
}

//NOTE: JANGAN PAKE SINGLEMIXIN FOR MULTIPLE ANIMATIONS!!!
class _ScheduleDetailsPanelState extends State<ScheduleDetailsPanel>
    with TickerProviderStateMixin {
  // Course type options - with unique IDs
  final List<Map<String, dynamic>> _courseTypes = [
    {'id': 'MT', 'name': 'Mathematics', 'color': Colors.blue},
    {'id': 'PY', 'name': 'Physics', 'color': Colors.amber},
    {'id': 'CE', 'name': 'Circuits and Electronics', 'color': Colors.orange},
    {
      'id': 'DA',
      'name': 'Digital Logic and Computer Architecture',
      'color': Colors.red,
    },
    {
      'id': 'SC',
      'name': 'Signals, Systems, and Communications',
      'color': Colors.purple,
    },
    {'id': 'SR', 'name': 'Control Systems and Robotics', 'color': Colors.teal},
    {'id': 'AL', 'name': 'Algorithms', 'color': Colors.indigo},
    {'id': 'PR', 'name': 'Programming', 'color': Colors.green},
    {
      'id': 'SD',
      'name': 'Software Engineering and Design',
      'color': Colors.cyan,
    },
    {
      'id': 'OS',
      'name': 'Operating Systems and Systems Programming',
      'color': Colors.deepOrange,
    },
    {
      'id': 'CN',
      'name': 'Computer Networks and Telecommunications',
      'color': Colors.brown,
    },
    {
      'id': 'DI',
      'name': 'Database and Information Systems',
      'color': Colors.lightBlue,
    },
    {
      'id': 'AI',
      'name': 'Artificial Intelligence and Machine Learning',
      'color': Colors.pink,
    },
    {'id': 'CS', 'name': 'Cybersecurity', 'color': Colors.deepPurple},
  ];

  //Lists & bools
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _selectedCourseTypes =
  []; //Stores the course types selected by the user
  List<Map<String, dynamic>> _recommendations =
  []; //holds on to final course selection from alternatives list, when generate is pressed, this will be the reference
  bool _randomizeChoices = false;
  bool _isGenerated = false;
  bool generating = false;

  //GENERATE / SAVE PREFERENCES BUTTON ANIMATION
  late AnimationController _buttonController;
  late Animation<Color?> _buttonColorAnimation;

  //STAGGER ANIMATION FOR GENERATED LIST
  late AnimationController _recommendationController;
  final List<Animation<Offset>> _recommendationAnimations = [];
  final List<Animation<double>> _recommendationOpacityAnimations = [];

  //FADE IN/OUT FOR TEXT & COURSE TYPE PREF BOX
  late AnimationController _fadeInOutController;
  late Animation<double> _textAnimation;
  late Animation<double> _boxAnimation;

  @override
  void initState() {
    super.initState();
    loadScheduleData();
    //"generate" button animation init
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _buttonColorAnimation = ColorTween(
      begin: Colors.grey[400],
      end: const Color(0xFF582A6D),
    ).animate(_buttonController);
    //5 generated recommended courses button animation init
    _recommendationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    //fade in/out animation
    _fadeInOutController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    //text fade in / out
    _textAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeInOutController, curve: Curves.easeIn),
    );
    //box fade in / out
    _boxAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeInOutController, curve: Curves.easeIn),
    );

    _fadeInOutController
        .forward(); //drives animation to directly play when panel slides in
  }

  //ANIMATION CONTROLLER DISPOSAL
  @override
  void dispose() {
    _buttonController.dispose();
    _recommendationController.dispose();
    _fadeInOutController.dispose();
    super.dispose();
  }

  // >>> FUNCTIONS
  // STAGGER ANIMATION SPEED SETTINGS
  void _setupRecommendationAnimations({bool reverse = false}) {
    //note: reverse is exit animation
    _recommendationAnimations.clear();
    _recommendationOpacityAnimations.clear();

    //for the amount of recommendations available
    for (int i = 0; i < _recommendations.length; i++) {
      // exit animation: animate from current position to right
      final positionAnimation = Tween<Offset>(
        begin: reverse ? Offset.zero : const Offset(1, 0),
        end: reverse ? const Offset(1, 0) : Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _recommendationController,
          curve: Interval(
            reverse ? (0.15 * i) : (0.15 * i),
            reverse ? (0.35 + 0.15 * i) : (0.35 + 0.15 * i),
            curve: reverse ? Curves.easeIn : Curves.easeOut,
          ),
        ),
      );

      final opacityAnimation = Tween<double>(
        begin: reverse ? 1 : 0,
        end: reverse ? 0 : 1,
      ).animate(
        CurvedAnimation(
          parent: _recommendationController,
          curve: Interval(
            reverse ? (0.15 * i) : (0.15 * i),
            reverse ? (0.35 + 0.15 * i) : (0.35 + 0.15 * i),
            curve: reverse ? Curves.easeIn : Curves.easeOut,
          ),
        ),
      );

      _recommendationAnimations.add(positionAnimation);
      _recommendationOpacityAnimations.add(opacityAnimation);
    }
  }

  Future<void> _animateRecommendationsOut() async {
    // Setup exit animations
    _setupRecommendationAnimations(reverse: true);

    // Play the reverse animation
    await _recommendationController.reverse(from: 1.0);

    // Reset the controller for next use
    _recommendationController.reset();
  }

  //ALTERNATIVE COURSE SELECTION
  int? _selectedRecommendationIdx;
  void _selectRecommendation(int idx) {
    setState(() {
      //if tapped item is already selected, it deselects
      if (_selectedRecommendationIdx == idx) {
        _selectedRecommendationIdx = null;
      }
      //if not, it selects
      else {
        _selectedRecommendationIdx = idx;
      }
    });
  }

  // >> SELECT DROPDOWN COURSE TYPE
  void _selectCourseType(Map<String, dynamic> courseType) {
    setState(() {
      // Check if already selected
      final existingIndex = _selectedCourseTypes.indexWhere(
            (item) => item['id'] == courseType['id'],
      );
      if (existingIndex == -1) {
        // Add to selected list if not already there
        _selectedCourseTypes.add(courseType);
      } else {
        // If already in list, don't add again (handled by _removeCourseType)
        _removeCourseType(courseType);
        return;
      }
      _searchController.clear();
    });
  }

  // >> REMOVE DROPDOWN COURSE TYPE
  void _removeCourseType(Map<String, dynamic> courseType) {
    setState(() {
      _selectedCourseTypes.removeWhere(
            (item) => item['id'] == courseType['id'],
      );
    });
  }

  void _actuallyRemoveSchedule() {
    String code = widget.schedule.scheduleCode;
    String prefix = code[0];
    String schedule = '';
    for (int i = 1; i < code.length; i++) {
      schedule += prefix + code[i];
    }
    ScheduleBox oldCourse = ScheduleBox(
      title: '',
      code: '',
      location: '',
      scheduleCode: '',
      startHour: 0,
      durationSlots: 0,
      date: 0,
      isWeekly: false,
      endDate: 0,
      isRecommended: true,
    );
    for (var i in scheduleData) {
      print('tex:${i['scheduleString']}');
      print('extract:${extractSlots(i['scheduleString'])},${schedule}');
      if (extractSlots(
        i['scheduleString'],
      ).toSet().intersection(extractSlots(schedule).toSet()).isNotEmpty) {
        print('helloooo:${i['title']}');
        oldCourse = ScheduleBox(
          title: i['title'],
          code: i['code'],
          location: i['location'],
          scheduleCode: i['scheduleString'],
          startHour: _getStartHourFromScheduleString(i['scheduleString']),
          durationSlots: _getDurationFromScheduleString(i['scheduleString']),
          date: i['referenceDate'] ?? widget.schedule.date,
          isWeekly: i['isWeekly'] ?? widget.schedule.isWeekly,
          endDate: i['endDate'] ?? widget.schedule.endDate,
          isRecommended: true,
        );
        final oldCourseData = {
          'title': i['title'],
          'code': i['code'],
          'location': i['location'],
          'scheduleString': i['scheduleString'],
          'referenceDate': i['referenceDate'] ?? widget.schedule.date,
          'isWeekly': i['isWeekly'] ?? widget.schedule.isWeekly,
          'isRecommended': true, // Mark as recommended
        };
        removeOldCourse(oldCourseData);
        print('haha:${scheduleData}');
        break;
      }
    }
    widget.onRemoveOldCourse(oldCourse);
  }

  void _handleRemoveSchedule() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirm Deletion',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF582A6D),
            ),
          ),
          content: Text(
            'Are you sure you want to remove this course?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _actuallyRemoveSchedule();
                widget.onClose(null, null);
              },
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  color: Colors.red[400],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleGenerateCourses() async {
    // Get the selected course type IDs and explicitly cast to List<String>
    var toberemovedslots;
    String code = widget.schedule.scheduleCode;
    String prefix = code[0];
    String schedule = '';
    for (int i = 1; i < code.length; i++) {
      schedule += prefix + code[i];
    }
    for (var i in scheduleData) {
      if (extractSlots(
        i['scheduleString'],
      ).toSet().intersection(extractSlots(schedule).toSet()).isNotEmpty) {
        toberemovedslots = extractSlots(i['scheduleString']);
        break;
      }
    }
    final usedSlots = _getUsedSlotsFromCurrentSchedule(
      toberemovedslots.toSet(), // This is the tapped course
    );
    print('usedslot1:${usedSlots}');

    final selectedTypes =
    _selectedCourseTypes.map((t) => t['id'] as String).toList();
    final recommendations = await CourseRecommender().generateRecommendations(
      usedSlots,
      selectedTypes,
    );
    print('recommendations: ${recommendations}');

    //animation settings for generated alternative courses
    _fadeInOutController.reverse().then((_) {
      if (mounted) {
        setState(() {
          generating = false;
          _isGenerated = true;
          _recommendations = recommendations;
        });

        // Then fade in the new content
        _fadeInOutController.forward();

        // Setup and start animations
        _setupRecommendationAnimations(reverse: false);
        _recommendationController.forward(from: 0);
      }
    });
    debugPrint('Tapped course slots: ${widget.schedule.scheduleCode}');
    debugPrint('All used slots EXCLUDING tapped course: $usedSlots');
  }

  void _handleGenerateCourses2() async {
    // Get the selected course type IDs and explicitly cast to List<String>

    print(widget.selectedSlots);

    final selectedTypes =
    _selectedCourseTypes.map((t) => t['id'] as String).toList();
    final recommendations = await CourseRecommender().generateRecommendations2(
      widget.selectedSlots,
      selectedTypes,
    );
    print('recommendations: ${recommendations}');

    //animation settings for generated alternative courses
    _fadeInOutController.reverse().then((_) {
      if (mounted) {
        setState(() {
          generating = false;
          _isGenerated = true;
          _recommendations = recommendations;
        });

        // Then fade in the new content
        _fadeInOutController.forward();

        // Setup and start animations
        _setupRecommendationAnimations(reverse: false);
        _recommendationController.forward(from: 0);
      }
    });
    debugPrint('Tapped course slots: ${widget.schedule.scheduleCode}');
  }

  //SCHEDULE STRING HELPER FUNCTIONS
  int _getStartHourFromScheduleString(String scheduleString) {
    // Get the first slot's hour
    if (scheduleString.length >= 2) {
      final slotCode = scheduleString[1];
      return 8 + _CalendarPageState._slotToHour(slotCode);
    }
    return 8; // Default
  }

  int _getDurationFromScheduleString(String scheduleString) {
    // Count how many slots this course occupies
    return scheduleString.length ~/ 2;
  }

  // get used slots from current schedule
  Set<String> _getUsedSlotsFromCurrentSchedule(Set<String> excludeCourse) {
    final slots = UserData().usedslot; // Directly use UserData().usedslot
    if (excludeCourse == null) return slots;

    // Create a copy to avoid modifying the original
    final filteredSlots = Set<String>.from(slots);
    for (var i in excludeCourse) {
      filteredSlots.remove(i);
    }
    return filteredSlots;
  }

  //BUILD THE GENERATED ALTERNATIVE COURSES BOX + PURPLE BORDER
  Widget _buildRecommendationItem(int index) {
    final recommendation = _recommendations[index];
    final isSelected = _selectedRecommendationIdx == index;

    final shouldAnimate = _recommendationAnimations.length > index;

    Widget content = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border:
        isSelected
            ? Border.all(color: const Color(0xFF582A6D), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recommendation['title'],
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF582A6D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Location: ${recommendation['location']}',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
          Text(
            'Time: ${recommendation['scheduleString']}',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
          Text(
            'Professor: ${recommendation['professorName']}',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                isSelected ? Colors.grey[400] : const Color(0xFF582A6D),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                _selectRecommendation(index);
              },
              child: Text(
                isSelected ? 'Selected' : 'Select',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );

    //wrap with animations
    if (shouldAnimate) {
      return SlideTransition(
        position: _recommendationAnimations[index],
        child: FadeTransition(
          opacity: _recommendationOpacityAnimations[index],
          child: content,
        ),
      );
    }

    return GestureDetector(
      onTap: () => _selectRecommendation(index),
      child: content,
    );
  }

  // SAVE PREFERENCES BUTTON HANDLER
  void _handleSavePreferences() {
    print('testttt1');
    if (_selectedRecommendationIdx != null) {
      final recommendation = _recommendations[_selectedRecommendationIdx!];

      // Create the new course data map matching your scheduleData structure
      final newCourseData = {
        'title': recommendation['title'],
        'code': recommendation['code'],
        'location': recommendation['location'],
        'scheduleString': recommendation['scheduleString'],
        'referenceDate':
        recommendation['referenceDate'] ?? widget.schedule.date,
        'isWeekly': recommendation['isWeekly'] ?? widget.schedule.isWeekly,
        'isRecommended': true, // Mark as recommended
      };

      if (!UserData().recommended.contains(recommendation['code'])) {
        FirebaseFirestore.instance
            .collection('Student')
            .doc(UserData().id)
            .collection('RECOMMENDED')
            .doc(recommendation['code'])
            .set({});
      }
      addusedslot(recommendation['scheduleString']);
      UserData().recommended.add(recommendation['code']);
      // Add to scheduleData
      addNewCourse(newCourseData);

      // Create the ScheduleBox for the new course
      final newCourse = ScheduleBox(
        title: recommendation['title'],
        code: recommendation['code'],
        location: recommendation['location'],
        scheduleCode: recommendation['scheduleString'],
        startHour: _getStartHourFromScheduleString(
          recommendation['scheduleString'],
        ),
        durationSlots: _getDurationFromScheduleString(
          recommendation['scheduleString'],
        ),
        date: recommendation['referenceDate'] ?? widget.schedule.date,
        isWeekly: recommendation['isWeekly'] ?? widget.schedule.isWeekly,
        endDate: recommendation['endDate'] ?? widget.schedule.endDate,
        isRecommended: true,
      );

      ScheduleBox oldCourse = newCourse;
      String code = widget.schedule.scheduleCode;
      String prefix = code[0];
      String schedule = '';
      for (int i = 1; i < code.length; i++) {
        schedule += prefix + code[i];
      }

      for (var i in scheduleData) {
        print('tex:${i['scheduleString']}');
        print('extract:${extractSlots(i['scheduleString'])},${schedule}');
        if (extractSlots(
          i['scheduleString'],
        ).toSet().intersection(extractSlots(schedule).toSet()).isNotEmpty) {
          print('helloooo:${i['title']}');
          oldCourse = ScheduleBox(
            title: i['title'],
            code: i['code'],
            location: i['location'],
            scheduleCode: i['scheduleString'],
            startHour: _getStartHourFromScheduleString(i['scheduleString']),
            durationSlots: _getDurationFromScheduleString(i['scheduleString']),
            date: i['referenceDate'] ?? widget.schedule.date,
            isWeekly: i['isWeekly'] ?? widget.schedule.isWeekly,
            endDate: i['endDate'] ?? widget.schedule.endDate,
            isRecommended: true,
          );
          final oldCourseData = {
            'title': i['title'],
            'code': i['code'],
            'location': i['location'],
            'scheduleString': i['scheduleString'],
            'referenceDate': i['referenceDate'] ?? widget.schedule.date,
            'isWeekly': i['isWeekly'] ?? widget.schedule.isWeekly,
            'isRecommended': true, // Mark as recommended
          };
          removeOldCourse(oldCourseData);

          print('haha:${scheduleData}');
          break;
        }
      }

      // Close the panel and replace the course
      widget.onClose(newCourse, oldCourse);
    }
  }

  void _handleSavePreferences2() {
    print('testttt2');
    if (_selectedRecommendationIdx != null) {
      final recommendation = _recommendations[_selectedRecommendationIdx!];

      // Create the new course data map matching your scheduleData structure
      final newCourseData = {
        'title': recommendation['title'],
        'code': recommendation['code'],
        'location': recommendation['location'],
        'scheduleString': recommendation['scheduleString'],
        'referenceDate':
        recommendation['referenceDate'] ?? widget.schedule.date,
        'isWeekly': recommendation['isWeekly'] ?? widget.schedule.isWeekly,
        'isRecommended': true, // Mark as recommended
      };

      if (!UserData().recommended.contains(recommendation['code'])) {
        FirebaseFirestore.instance
            .collection('Student')
            .doc(UserData().id)
            .collection('RECOMMENDED')
            .doc(recommendation['code'])
            .set({});
      }
      addusedslot(recommendation['scheduleString']);
      UserData().recommended.add(recommendation['code']);
      // Add to scheduleData
      addNewCourse(newCourseData);

      // Create the ScheduleBox for the new course
      final newCourse = ScheduleBox(
        title: recommendation['title'],
        code: recommendation['code'],
        location: recommendation['location'],
        scheduleCode: recommendation['scheduleString'],
        startHour: _getStartHourFromScheduleString(
          recommendation['scheduleString'],
        ),
        durationSlots: _getDurationFromScheduleString(
          recommendation['scheduleString'],
        ),
        date: recommendation['referenceDate'] ?? widget.schedule.date,
        isWeekly: recommendation['isWeekly'] ?? widget.schedule.isWeekly,
        endDate: recommendation['endDate'] ?? widget.schedule.endDate,
        isRecommended: true,
      );
      widget.onClose(newCourse, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(widget.animation),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.65,
        child: Container(
          decoration: BoxDecoration(
            color: MyTheme.getSettingsTextColor(isDarkMode),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(40),
              bottomLeft: Radius.circular(40),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // CLOSE BUTTON
              Container(
                padding: const EdgeInsets.only(top: 8, right: 8),
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 24,
                    color: Color(0xFF582A6D),
                  ),
                  onPressed: () => widget.onClose(null, null),
                ),
              ),

              //THE REST OF THE PANEL PAGE
              Expanded(
                child:
                generating
                    ? Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF582A6D),
                  ),
                )
                    : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Schedule information
                      Text(
                        widget.schedule.title,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF582A6D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.schedule.location,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_CalendarPageState.upperSlots[widget.schedule.startHour - 8]} - '
                            '${_CalendarPageState.lowerSlots[widget.schedule.startHour - 8 + widget.schedule.durationSlots - 1]}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Color(0xFF858585),
                        ),
                      ),
                      const Divider(
                        height: 32,
                        color: Color(0xFF582A6D),
                      ),

                      // Search field
                      if (!_isGenerated) ...[
                        FadeTransition(
                          opacity: _textAnimation,
                          child: Text(
                            'Find Alternative Courses',
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Course type dropdown
                        FadeTransition(
                          opacity: _boxAnimation,
                          child: CourseTypeDropdown(
                            selectedCourseTypes: _selectedCourseTypes,
                            courseTypes: _courseTypes,
                            onSelect: _selectCourseType,
                            onRemove: _removeCourseType,
                            randomizeChoices: _randomizeChoices,
                            maxWidth:
                            MediaQuery.of(context).size.width * 0.6,
                          ),
                        ),
                        const SizedBox(height: 40),
                      ] else ...[
                        FadeTransition(
                          opacity: _textAnimation,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 0,
                              bottom: 15,
                              right: 16,
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    // First animate the recommendations out
                                    await _animateRecommendationsOut();
                                    await _fadeInOutController
                                        .reverse();

                                    // Then reset the state
                                    if (mounted) {
                                      setState(() {
                                        _isGenerated = false;
                                        _selectedRecommendationIdx =
                                        null;
                                      });
                                      _fadeInOutController.forward();
                                    }
                                  },
                                  child: const Icon(
                                    Icons.arrow_back,
                                    color: Color(0xFF582A6D),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Alternative Courses Found',
                                  style: GoogleFonts.poppins(
                                    fontSize:
                                    MediaQuery.of(
                                      context,
                                    ).size.width *
                                        0.03,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // GENERATE 5 SUGGESTIONS
                        if (_recommendations.isNotEmpty) ...[
                          for (
                          int i = 0;
                          i < _recommendations.length;
                          i++
                          )
                            GestureDetector(
                              onTap: () => _selectRecommendation(i),
                              child: _buildRecommendationItem(i),
                            ),
                        ] else ...[
                          FadeTransition(
                            opacity: _textAnimation,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(top: 30),
                              child: Column(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 50,
                                    color: Colors.grey[500],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'No alternative courses available',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'Please adjust your filters',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),

              //GENERATE COURSES / SAVE PREFERENCES BUTTON
              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 13,
                  top: 8,
                ),
                child: Column(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        _isGenerated
                            ? (_recommendations.isNotEmpty
                            ? const Color(0xFF582A6D)
                            : Colors.grey[400]) //klo rec empty jd grey
                            : (_selectedCourseTypes.isNotEmpty
                            ? const Color(0xFF582A6D)
                            : Colors.grey[400]),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed:
                      _isGenerated
                          ? (_recommendations.isNotEmpty
                          ? (widget.isDragSelection
                          ? _handleSavePreferences2
                          : _handleSavePreferences)
                          : null)
                          : (_selectedCourseTypes.isNotEmpty
                          ? () {
                        setState(() => generating = true);
                        if (widget.isDragSelection) {
                          _handleGenerateCourses2();
                        } else {
                          _handleGenerateCourses();
                        }
                      }
                          : null),
                      child: Text(
                        _isGenerated ? 'Save Preferences' : 'Generate Courses',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: MyTheme.getSettingsTextColor(isDarkMode),
                        ),
                      ),
                    ),
                    if (!_isGenerated && !widget.isDragSelection) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[400],
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: _handleRemoveSchedule,
                          child: Text(
                            'Remove Schedule',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: MyTheme.getSettingsTextColor(isDarkMode),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ========================================================

// ============== SCHEDULE BOXES ==============
class ScheduleBox extends StatelessWidget {
  final String title;
  final String code;
  final String scheduleCode;
  final String location;
  final int startHour;
  final int durationSlots;
  final dynamic date; //tanpa tanda '?' dynamic is already nullable
  final Color? backgroundColor; //nullable
  final bool isWeekly; // Add this field
  final bool isRecommended;
  final bool isEvent;
  final dynamic endDate;

  const ScheduleBox({
    required this.title,
    required this.code,
    this.scheduleCode = '',
    required this.location,
    required this.startHour,
    required this.durationSlots,
    this.date,
    this.backgroundColor,
    this.isWeekly = false, // Default to false
    this.endDate,
    this.isRecommended = false,
    this.isEvent = true,
    super.key,
  });

  static List<ScheduleBox> fromScheduleString({
    required String title,
    required String code,
    required String location,
    required String scheduleString,
    required dynamic referenceDate, //SEMESTER STARTS WHEN??
    required Set<String> usedSlots,
    Color? backgroundColor,
    bool isWeekly = false,
    dynamic endDate,
    bool isRecommended = false,
    bool isEvent = false,
  }) {
    // === TRANSLATING REFERENCE DATE (SEMESTERS) ===
    DateTime _semStartDate(int semester) {
      final now = DateTime.now();
      final year = now.year;
      if (semester % 2 == 1) {
        return DateTime(year, 1, 10); //spring sem
      } else {
        return DateTime(year, 9, 1); //fall sem
      }
    }

    DateTime _semEndDate(int semester) {
      final now = DateTime.now();
      final year = now.year;
      if (semester % 2 == 1) {
        return DateTime(year, 8, 10); //spring sem
      } else {
        return DateTime(year, 12, 31); //fall sem
      }
    }

    DateTime conv_referenceDate;
    DateTime? conv_endDate;

    // REFERENCE DATE CONVERSION
    if (referenceDate is int) {
      conv_referenceDate = _semStartDate(referenceDate);
      debugPrint(
        "[DEBUG] Reference semester: $referenceDate => Start: $conv_referenceDate, End: $conv_endDate",
      );
      // If endDate is not provided, use semester end date
      conv_endDate = endDate ?? _semEndDate(referenceDate);
    } else {
      conv_referenceDate = referenceDate as DateTime;
      conv_endDate = endDate as DateTime?;
      debugPrint(
        "[DEBUG] Provided DateTime: Start: $conv_referenceDate, End: $conv_endDate",
      );
    }

    // Handle case where endDate is an integer (semester number)
    if (endDate is int) {
      conv_endDate = _semEndDate(endDate);
      debugPrint(
        "[DEBUG] Overriding endDate from semester $endDate => $conv_endDate",
      );
    }

    // == PARSING SCHEDULESTRING
    final Map<String, List<String>> dayToSlots = {};

    // SCHEDULE CONFLICT HANDLING
    bool hasConflict = false;
    // Group slots by day
    for (int i = 0; i < scheduleString.length; i += 2) {
      if (i + 1 >= scheduleString.length) break; // Prevent index out of range

      final dayCode = scheduleString[i];
      final slotCode = scheduleString[i + 1];
      final slotKey = '$dayCode$slotCode';

      print('usedslot3:${usedSlots}');

      // if (UserData().usedslot.contains(slotKey)) {
      //   debugPrint("[DEBUG] Skipped $title: slot $slotKey already used");
      //   hasConflict = true;
      //   break;
      // }
    }
    //debugPrint("[DEBUG] Parsed dayToSlots map: $dayToSlots");
    // If there's any conflict, return empty list
    // if (hasConflict) {
    //   debugPrint("[DEBUG] Skipping $title due to conflicts");
    //   return [];
    // }

    // If no conflicts, proceed to parse and add to usedSlots
    for (int i = 0; i < scheduleString.length; i += 2) {
      if (i + 1 >= scheduleString.length) break;

      final dayCode = scheduleString[i];
      final slotCode = scheduleString[i + 1];
      final slotKey = '$dayCode$slotCode';

      usedSlots.add(slotKey); // Add to used slots
      if (isWeekly == true) addusedslot(slotKey);
      print('usedslot4:${usedSlots}');
      debugPrint("[DEBUG] usedSlots: $usedSlots");
      print(UserData().usedslot);
      dayToSlots.putIfAbsent(dayCode, () => []).add(slotCode);
    }
    debugPrint("[DEBUG] Parsed dayToSlots map: $dayToSlots");

    final List<ScheduleBox> boxes = []; //list of schedule boxes

    // Create separate boxes for each day
    dayToSlots.forEach((dayCode, slots) {
      print('daycode:$dayCode');
      final weekday = _CalendarPageState._dayCodeToWeekday(dayCode);
      final date =
      isWeekly
          ? conv_referenceDate
          : _CalendarPageState._findNextWeekday(
        conv_referenceDate,
        weekday,
      );

      debugPrint(
        "[DEBUG] Processing dayCode $dayCode -> weekday $weekday on date $date with slots: $slots",
      );

      // Sort the slots to get continuous blocks
      slots.sort(
            (a, b) => _CalendarPageState._slotToHour(
          a,
        ).compareTo(_CalendarPageState._slotToHour(b)),
      );

      // Process slots in continuous blocks
      int startSlot = _CalendarPageState._slotToHour(slots[0]);
      int prevSlot = startSlot;
      int blockStartIndex = 0;

      for (int i = 1; i < slots.length; i++) {
        final currentSlot = _CalendarPageState._slotToHour(slots[i]);
        // If not continuous, create a box for the previous block
        if (currentSlot != prevSlot + 1) {
          final duration = prevSlot - startSlot + 1;
          final slotGroup = slots.sublist(blockStartIndex, i).join();
          debugPrint(
            "[DEBUG] Creating box for block: $dayCode$slotGroup from hour ${8 + startSlot} for $duration slot(s)",
          );
          boxes.add(
            ScheduleBox(
              title: title,
              code: code,
              scheduleCode: dayCode + slots.sublist(blockStartIndex, i).join(),
              location: location,
              date: date,
              startHour: 8 + startSlot,
              durationSlots: duration,
              backgroundColor: backgroundColor,
              isWeekly: isWeekly,
              endDate: conv_endDate,
              isRecommended: isRecommended,
            ),
          );
          startSlot = currentSlot;
          blockStartIndex = i;
        }
        prevSlot = currentSlot;
      }

      // Add the last block
      final duration = prevSlot - startSlot + 1;
      final slotGroup = slots.sublist(blockStartIndex).join();
      debugPrint(
        "[DEBUG] Creating final box for block: $dayCode$slotGroup from hour ${8 + startSlot} for $duration slot(s)",
      );
      boxes.add(
        ScheduleBox(
          title: title,
          code: code,
          scheduleCode: dayCode + slots.sublist(blockStartIndex).join(),
          location: location,
          date: date,
          startHour: 8 + startSlot,
          durationSlots: duration,
          backgroundColor: backgroundColor,
          isWeekly: isWeekly,
          endDate: conv_endDate,
          isRecommended: isRecommended,
        ),
      );
    });
    debugPrint("[DEBUG] Created ${boxes.length} schedule box(es)");
    return boxes;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            gradient:
            isRecommended
                ? const LinearGradient(
              colors: [Color(0xFFD9AEFF), Color(0xFFFFF3FC)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            )
                : null,
            color: isRecommended ? null : backgroundColor ?? Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(6),
          width: constraints.maxWidth,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AutoSizeText(
                forceBreakable(title),
                wrapWords: true,
                maxLines: durationSlots >= 2 ? 3 : 2,
                minFontSize: 5.5,
                maxFontSize: 7,
                stepGranularity: 0.5,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              // SizedBox(
              //   height: 14,
              //   child: Marquee(
              //     text: forceBreakable(title),
              //     style: GoogleFonts.poppins(
              //       fontWeight: FontWeight.w600,
              //       fontSize: 8,
              //     ),
              //     scrollAxis: Axis.horizontal,
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     blankSpace: 15,
              //     velocity: 10.0,
              //     pauseAfterRound: Duration(seconds: 0),
              //     startPadding: 4.0,
              //     accelerationDuration: Duration(seconds: 1),
              //     accelerationCurve: Curves.linear,
              //     decelerationDuration: Duration(milliseconds: 500),
              //     decelerationCurve: Curves.easeOut,
              //   ),
              // ),
              if (durationSlots >= 2)
                AutoSizeText(
                  location,
                  wrapWords: true,
                  maxLines: 2,
                  minFontSize: 5,
                  maxFontSize: 7,
                  stepGranularity: 0.5,
                  overflow: TextOverflow.clip,
                  textAlign: TextAlign.left,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFA7859A),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
// ========================================================

// ============== MAIN CALENDAR PAGE ==============
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, this.title = ''});
  final String title;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with TickerProviderStateMixin {
  int _colorIndex = 0;
  //ANIMATION
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _fadeOutAnimation;

  late AnimationController _panelController;
  ScheduleBox? _selectedSchedule;
  bool _panelVisible = false;

  DateTime today = DateTime.now();

  DateTime _semEndDate(int semester) {
    final now = DateTime.now();
    final year = now.year;
    if (semester % 2 == 1) {
      return DateTime(year, 6, 10); // Spring semester ends June 10
    } else {
      return DateTime(year, 12, 31); // Fall semester ends Dec 31
    }
  }

  //how does the calendar go from week to week? Ans: This function
  static DateTime _findNextWeekday(DateTime fromDate, int weekday) {
    var date = DateTime(fromDate.year, fromDate.month, fromDate.day);
    while (date.weekday != weekday) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  //>> BRAIN OF CALENDAR (makes schedules show up weekly & monthly)
  bool showCurrent = true; //current/recommended button bool
  bool isAI = false; //scheduleBox recommended/normal bool

  void _nextMonth() {
    setState(() {
      today = DateTime(today.year, today.month + 1, 1);
    });
  }

  void _prevMonth() {
    final now = DateTime.now();
    final targetYear = today.month == 1 ? today.year - 1 : today.year;
    final targetMonth = today.month == 1 ? 12 : today.month - 1;

    final lastDayOfTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
    final newDay =
    now.day <= lastDayOfTargetMonth ? now.day : lastDayOfTargetMonth;

    setState(() {
      today = DateTime(targetYear, targetMonth, newDay);
    });
  }

  String _getMonthYear() {
    return '${_months[today.month - 1]} ${today.year}';
  }

  String _getTimeSlots(int index) {
    return _timeslots[index];
  }

  String _getUpperSlot(int index) {
    return _upperslot[index];
  }

  String _getLowerSlot(int index) {
    return _lowerslot[index];
  }

  DateTime getStartOfWeek(DateTime date) {
    return date.subtract(
      Duration(days: date.weekday - 1),
    ); // Adjusted to start on Monday
  }

  void _nextWeek() {
    setState(() {
      today = today.add(const Duration(days: 7));
    });
  }

  void _prevWeek() {
    setState(() {
      today = today.subtract(const Duration(days: 7));
    });
  }

  //MONTH LIST
  final List<String> _months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  //TIME SLOT CODES
  final List<String> _timeslots = [
    '1',
    '2',
    '3',
    '4',
    'n',
    '5',
    '6',
    '7',
    '8',
    '9',
    'a',
    'b',
    'c',
  ];

  static const List<String> _upperslot = [
    '08:00',
    '09:00',
    '10:10',
    '11:10',
    '12:10',
    '13:20',
    '14:20',
    '15:30',
    '16:30',
    '17:30',
    '18:30',
    '19:30',
    '20:30',
  ];

  static const List<String> _lowerslot = [
    '08:50',
    '09:50',
    '11:00',
    '12:00',
    '13:00',
    '14:10',
    '15:10',
    '16:20',
    '17:20',
    '18:20',
    '19:20',
    '20:20',
    '21:20',
  ];
  static List<String> get upperSlots => _upperslot;
  static List<String> get lowerSlots => _lowerslot;

  //MAPPING COURSE DAY CODE
  static int _dayCodeToWeekday(String code) {
    switch (code.toUpperCase()) {
      case 'M':
        return 1;
      case 'T':
        return 2;
      case 'W':
        return 3;
      case 'R':
        return 4;
      case 'F':
        return 5;
      case 'S':
        return 6;
      case 'U':
        return 7;
      default:
        throw FormatException('Invalid day code: $code');
    }
  }

  String _getDayNameFromCode(String code) {
    switch (code.toUpperCase()) {
      case 'M':
        return 'Monday';
      case 'T':
        return 'Tuesday';
      case 'W':
        return 'Wednesday';
      case 'R':
        return 'Thursday';
      case 'F':
        return 'Friday';
      case 'S':
        return 'Saturday';
      case 'U':
        return 'Sunday';
      default:
        return 'Day';
    }
  }

  //MAPPING TIME SLOT CODE
  static int _slotToHour(String slot) {
    switch (slot.toLowerCase()) {
      case '1':
        return 0;
      case '2':
        return 1;
      case '3':
        return 2;
      case '4':
        return 3;
      case 'n':
        return 4;
      case '5':
        return 5;
      case '6':
        return 6;
      case '7':
        return 7;
      case '8':
        return 8;
      case '9':
        return 9;
      case 'a':
        return 10;
      case 'b':
        return 11;
      case 'c':
        return 12;
      default:
        throw FormatException('Invalid slot code: $slot');
    }
  }

  //COLOR CODE FOR SCHEDULE BOXES
  final List<String> _colorCodes = [
    'FBD6C6',
    'E8E8B1',
    'B1E8B7',
    'B1E5E8',
    'B1BAE8',
    'CDB1E8',
  ];

  late List<ScheduleBox> scheduleBoxes; //LIST OF SCHEDULE BOXES

  @override
  void initState() {
    super.initState();
    print('schedule:${scheduleData}');
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeOutAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _panelController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Helper function to parse color
    Color parseColor(String colorString) {
      String hexColor = colorString.replaceAll("#", "");
      if (hexColor.length == 6) {
        hexColor = "FF$hexColor"; // Add opacity if not provided
      }
      return Color(int.parse(hexColor, radix: 16));
    }

    //final usedSlots = <String>{}; //LISTS OUT COURSE CODES THAT HAVE BEEN USED
    final localUsedSlots = Set<String>.from(UserData().usedslot);

    scheduleBoxes =
        scheduleData
            .map((item) {
          final isRecommended = item['isRecommended'] == true;
          Color? backgroundColor;

          if (isRecommended) {
            backgroundColor = null; // recommended course = will be gradient
          } else if (item['backgroundColor'] is Color) {
            backgroundColor = item['backgroundColor'] as Color;
          } else if (item['backgroundColor'] is String) {
            backgroundColor = parseColor(item['backgroundColor'] as String);
          } else {
            // Color is taken from the list rotation
            backgroundColor = Color(
              int.parse(
                _colorCodes[_colorIndex % _colorCodes.length],
                radix: 16,
              ) +
                  0xFF000000,
            );
            _colorIndex++;
          }
          debugPrint('MASUK SINI GA?');
          print('usedslot5:${UserData().usedslot}');

          return ScheduleBox.fromScheduleString(
            title: item['title'] as String,
            code: item['code'] as String,
            location: item['location'] as String,
            scheduleString: item['scheduleString'] as String,
            referenceDate: item['referenceDate'],
            usedSlots: localUsedSlots,
            isWeekly: item['isWeekly'] as bool,
            endDate: item['endDate'],
            backgroundColor: backgroundColor,
            isRecommended: isRecommended,
          );
        })
            .expand((boxes) => boxes)
            .toList();
  }

  //ANIMATION DISPOSAL
  @override
  void dispose() {
    _fadeController.dispose();
    _panelController.dispose();
    super.dispose();
  }

  //GET USED SLOTS LIST
  // Set<String> _getAllUsedSlots() {
  //   final usedSlots = <String>{};
  //   for (final schedule in scheduleBoxes) {
  //     final code = schedule.scheduleCode;
  //     for (int i = 0; i < code.length; i += 2) {
  //       if (i + 1 >= code.length) break;
  //       usedSlots.add('${code[i]}${code[i + 1]}');
  //     }
  //   }
  //   return usedSlots;
  // }

  // >> SHOW PANEL FUNCTION (states that occur when panel is shown)
  void _showPanel(ScheduleBox schedule) {
    // Get all used slots from current schedule

    setState(() {
      _selectedSchedule = schedule;
      _panelVisible = true;
      //_usedSlotsForPanel = usedSlots; // Store the slots
    });
    _panelController.forward();
  }

  void removeoldcoursedata(ScheduleBox oldCourse) async {
    if (oldCourse != null) {
      final oldCode = (oldCourse.scheduleCode);
      print('oldcode:${oldCode}');
      UserData().recommended.remove(oldCourse.code);
      var temp = extractSlots(oldCourse.scheduleCode);
      for (var i in temp) {
        removeusedslot(i);
      }
      try {
        await FirebaseFirestore.instance
            .collection('Student')
            .doc(UserData().id)
            .collection('RECOMMENDED')
            .doc(oldCourse.code)
            .delete();
        print('deleted from recommended.');
      } catch (e) {
        print('Error deleting recommended course: $e');
      }

      // Remove the old course from Calendar page (UI)
      setState(() {
        scheduleBoxes.removeWhere((c) => c.title == oldCourse.title);
      });
    }
  }

  // >> SHOW PANEL FUNCTION (states that occur when panel is hidden)
  void _hidePanel([ScheduleBox? newCourse, ScheduleBox? oldCourse]) async {
    await _panelController.reverse();
    //NOTE:
    // ADA 3 METODE YANG HARUS DIURUS
    //1. CODE-WISE --> usedSlots
    //2. UI-WISE --> Display in calendar
    //3. DATABASE --> Schedule Data

    if (newCourse != null && oldCourse != null) {
      final oldCode = oldCourse.scheduleCode;
      print('oldcode:${oldCode}');
      UserData().recommended.remove(oldCourse.code);
      var temp = extractSlots(oldCourse.scheduleCode);
      for (var i in temp) {
        removeusedslot(i);
      }
      try {
        await FirebaseFirestore.instance
            .collection('Student')
            .doc(UserData().id)
            .collection('RECOMMENDED')
            .doc(oldCourse.code)
            .delete();
        print('deleted from recommended.');
      } catch (e) {
        print('Error deleting recommended course: $e');
      }

      // Remove the old course from Calendar page (UI)
      setState(() {
        scheduleBoxes.removeWhere((c) => c.title == oldCourse.title);
      });

      // Remove from scheduleData (DATABASE)
      final oldCourseData = {
        'title': oldCourse.title,
        'code': oldCourse.title,
        'location': oldCourse.location,
        'scheduleString': oldCourse.scheduleCode,
        'referenceDate': oldCourse.date ?? DateTime.now(),
        'isWeekly': oldCourse.isWeekly,
        'isRecommended': oldCourse.isRecommended,
        'isEvent': oldCourse.isEvent,
      };

      // Create and add new course
      print(
        'newcoursee:${newCourse.title},${newCourse.code},${newCourse.scheduleCode}',
      );
      final newCourses = ScheduleBox.fromScheduleString(
        title: newCourse.title,
        code: newCourse.code,
        location: newCourse.location,
        scheduleString: newCourse.scheduleCode,
        referenceDate: newCourse.date ?? DateTime.now(),
        usedSlots: UserData().usedslot,
        isWeekly: newCourse.isWeekly,
        endDate: newCourse.endDate,
        isRecommended: true,
      );

      setState(() {
        print('newcourse to add:${newCourses[0]}');
        scheduleBoxes.addAll(newCourses);
        for (var i in scheduleBoxes) {
          print('konnnnn:${i.title}');
        }
        _panelVisible = false;
      });

      // Trigger the existing fade animation
      _fadeController.forward(from: 0);
    } else if (newCourse != null) {
      final newCourses = ScheduleBox.fromScheduleString(
        title: newCourse.title,
        code: newCourse.code,
        location: newCourse.location,
        scheduleString: newCourse.scheduleCode,
        referenceDate: newCourse.date ?? DateTime.now(),
        usedSlots: UserData().usedslot,
        isWeekly: newCourse.isWeekly,
        endDate: newCourse.endDate,
        isRecommended: true,
      );
      setState(() {
        scheduleBoxes.addAll(newCourses);
        _panelVisible = false;
      });
    } else {
      setState(() {
        _panelVisible = false;
      });
    }
    setState(() {
      _isDragSelection = false;
    });
  }

  void removeEventScheduleBox(String eventCode) async {
    // Remove from UserData or internal tracking if needed

    try {
      // await FirebaseFirestore.instance
      //     .collection('Student')
      //     .doc(UserData().id)
      //     .collection('ANNADD') // 👈 where your added events are stored
      //     .doc(eventCode)
      //     .delete();
      print('✅ Event deleted from ANNADD.');
    } catch (e) {
      print('⚠️ Error deleting event: $e');
    }

    // Remove from in-memory list and rebuild UI
    setState(() {
      scheduleBoxes.removeWhere((box) => box.code == eventCode);
      scheduleData.removeWhere((entry) => entry['code'] == eventCode);
    });
  }

  Future<void> _openEventDetail(ScheduleBox schedule) async {
    final eventSnapshot =
    await FirebaseFirestore.instance.collection('News').get();

    final box = await Hive.openBox('userBox');
    Map<String, dynamic>? storedUser = box.get('userData');

    final docSnapshot =
    await FirebaseFirestore.instance
        .collection('Student')
        .doc(storedUser?['id'])
        .get();

    final student = docSnapshot.data()!;
    final eventDoc = eventSnapshot.docs.firstWhere(
          (doc) => doc.data()['code'] == schedule.code,
    );
    final data = eventDoc.data();

    await Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder:
            (context) => AnnouncementInfoPage(
          annData: data,
          student: student,
          onFavoriteChanged: () {},
          onDelete: () {
            removeEventScheduleBox(schedule.code);
          }, // Optional
        ),
      ),
    )
        .then((_) async {
      await loadScheduleData(); // Re-fetch data
      setState(() {}); // Rebuild UI
    });
  }

  List<Widget> _buildScheduleBoxes(
      List<ScheduleBox> scheduleBoxes,
      double columnWidth,
      double rowHeight,
      DateTime startOfWeek,
      bool showCurrent,
      Animation<double> fadeAnimation,
      ) {
    return [
      // Weekly Schedules
      ...scheduleBoxes
          .where((schedule) {
        if (!schedule.isWeekly) return false;
        if (showCurrent) return !schedule.isRecommended;
        return true;
      })
          .expand((schedule) {
        if (schedule.scheduleCode.isEmpty) return [const SizedBox.shrink()];

        final dayCode = schedule.scheduleCode[0];
        print('daycode1:$dayCode');
        try {
          final weekday = _dayCodeToWeekday(dayCode);
          final startSlot = schedule.startHour - 8;

          return List.generate(7, (weekOffset) {
            final date = startOfWeek.add(Duration(days: weekOffset));
            final DateTime? actualEndDate =
            schedule.endDate is int
                ? _semEndDate(schedule.endDate as int)
                : schedule.endDate as DateTime?;

            if (date.weekday == weekday &&
                (actualEndDate == null ||
                    date.isBefore(
                      actualEndDate.add(const Duration(days: 1)),
                    )) &&
                (schedule.date == null || !date.isBefore(schedule.date!))) {
              return Positioned(
                top: rowHeight * startSlot,
                left: columnWidth * (weekday - 1),
                width: columnWidth,
                height: rowHeight * schedule.durationSlots,
                child: GestureDetector(
                  onTap: () async {
                    if (schedule.isRecommended) {
                      _showPanel(schedule);
                    } else {
                      final courseBox = await Hive.openBox<CourseData>(
                        'all_courses',
                      );
                      final course = courseBox.values.firstWhere(
                            (course) => schedule.code == course.id,
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (context) => CourseDetailPage(
                            courseCode: schedule.code,
                            courseName: schedule.title,
                            professor: course.professor,
                            credits: course.credit,
                            department: schedule.code.split(' ')[0],
                            syllabus: course.syllabus,
                            grading: course.grading,
                            location: schedule.location,
                            time: course.classTime ?? '',
                          ),
                        ),
                      );
                    }
                  },
                  child:
                  schedule.isRecommended
                      ? FadeTransition(
                    opacity: fadeAnimation,
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      child: schedule,
                    ),
                  )
                      : Container(
                    margin: const EdgeInsets.all(2),
                    child: schedule,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          });
        } catch (e) {
          return [const SizedBox.shrink()];
        }
      }),

      // Non-weekly Schedules
      ...scheduleBoxes
          .where((schedule) {
        if (schedule.isWeekly) {
          print('schedule is weekly: ${schedule.title}');
          return false;
        }
        if (showCurrent) {
          print('show current: ${schedule.title}');
          print('REEEEEECC: ${schedule.isRecommended}');
          return !schedule.isRecommended;
        }
        print("AWADADHALOBANDUNG");
        return true;
      })
          .map((schedule) {
        if (schedule.date == null) return const SizedBox.shrink();

        final DateTime? actualEndDate =
        schedule.endDate is int
            ? _semEndDate(schedule.endDate as int)
            : schedule.endDate as DateTime?;
        print("DAATEE ${schedule.date}");
        print("ENDENDDAATEE ${schedule.endDate}");
        if (actualEndDate != null &&
            schedule.date!.isAfter(actualEndDate)) {
          print('1');
          return const SizedBox.shrink();
        }

        final startOfCurrentWeek = getStartOfWeek(today);
        final endOfCurrentWeek = startOfCurrentWeek.add(
          const Duration(days: 6),
        );
        final isInCurrentWeek =
            !schedule.date!.isBefore(startOfCurrentWeek) &&
                !schedule.date!.isAfter(endOfCurrentWeek);
        print('startcurrentweek:$startOfCurrentWeek');
        print('endcurrentweek:$endOfCurrentWeek');

        if (!isInCurrentWeek) {
          print('2');
          return const SizedBox.shrink();
        }

        final dayIndex = schedule.date!.weekday - 1;
        final startSlot = schedule.startHour - 8;

        return Positioned(
          top: rowHeight * startSlot,
          left: columnWidth * dayIndex,
          width: columnWidth,
          height: rowHeight * schedule.durationSlots,
          child: GestureDetector(
            onTap: () async {
              print("STARTE: ${schedule.date}");
              print("ENDE: ${schedule.endDate}");
              print("NGAKAK1 ${schedule.isWeekly}");
              print("NGAKAK2 ${schedule.endDate}");
              print("NGAKAK3 ${schedule.startHour}");
              print("NGAKAK4 ${schedule.isEvent}");
              _openEventDetail(schedule);
            },
            child: Container(
              margin: const EdgeInsets.all(2),
              child: schedule,
            ),
          ),
        );
      })
          .toList(),
    ];
  }

  // Add these with your other state variables
  int? _anchorCol, _anchorRow;
  int? _hoverCol, _hoverRow;
  Set<String>? _selectedSlots;

  String _getDayCodeFromCol(int col) {
    const dayCodes = ['M', 'T', 'W', 'R', 'F', 'S', 'U'];
    return dayCodes[col];
  }

  String _getSlotCodeFromRow(int row) {
    const slotCodes = [
      '1',
      '2',
      '3',
      '4',
      'n',
      '5',
      '6',
      '7',
      '8',
      '9',
      'a',
      'b',
      'c',
    ];
    return slotCodes[row];
  }

  Set<String> _getSelectedSlotCodes(int startCol, int startRow, int endRow) {
    final dayCode = _getDayCodeFromCol(startCol);
    final slots = <String>{};

    for (int row = startRow; row <= endRow; row++) {
      slots.add('$dayCode${_getSlotCodeFromRow(row)}');
    }

    return slots;
  }

  bool _isDragSelection = false;

  @override
  Widget build(BuildContext context) {
    final startOfWeek = getStartOfWeek(today);
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    // final todayIndex = DateTime.now().difference(startOfWeek).inDays;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.height * 0.02,
                ),
                //height: MediaQuery.of(context).size.height * 0.085,
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Visibility(
                                visible:
                                !(today.month == DateTime.now().month &&
                                    today.year == DateTime.now().year),
                                // Visibility(
                                //   visible:
                                //       !today.isBefore(DateTime.now()) &&
                                //       !today.isAtSameMomentAs(DateTime.now()),
                                maintainSize: true,
                                maintainAnimation: true,
                                maintainState: true,
                                child: GestureDetector(
                                  onTap: _prevMonth,
                                  child: Icon(
                                    Icons.chevron_left,
                                    size: 35,
                                    color: MyTheme.getSettingsTextColor(
                                      isDarkMode,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 120,
                                child: Container(
                                  height: 35,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: const Color(
                                      0xFF8B7FA5,
                                    ).withOpacity(0.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        offset: const Offset(0, 2),
                                        blurRadius: 6,
                                        spreadRadius: -6,
                                      ),
                                      BoxShadow(
                                        color: const Color(
                                          0xFF513061,
                                        ).withOpacity(1),
                                        offset: const Offset(0, -1),
                                        blurRadius: 2,
                                        spreadRadius: -2,
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _getMonthYear(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFEBEAEC),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              //MONTH SELECTOR UI
                              GestureDetector(
                                onTap: _nextMonth,
                                child: Icon(
                                  Icons.chevron_right,
                                  size: 35,
                                  color: MyTheme.getSettingsTextColor(
                                    isDarkMode,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    //CHOOSE TO SHOW UI
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "CHOOSE TO SHOW",
                                style: GoogleFonts.poppins(
                                  color: MyTheme.getSettingsTextColor(
                                    isDarkMode,
                                  ),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      if (isAI) {
                                        // Only animate if switching from Recommended to Current
                                        // First fade out the recommended courses
                                        await _fadeController.reverse();
                                        if (mounted) {
                                          setState(() {
                                            showCurrent = true;
                                            isAI = false;
                                          });
                                        }
                                      } else {
                                        setState(() {
                                          showCurrent = true;
                                          isAI = false;
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        color:
                                        showCurrent
                                            ? MyTheme.getSettingsTextColor(
                                          isDarkMode,
                                        )
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: MyTheme.getSettingsTextColor(
                                            isDarkMode,
                                          ),
                                        ),
                                        boxShadow:
                                        showCurrent
                                            ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF000010,
                                            ),
                                            offset:
                                            Offset.fromDirection(
                                              1.0,
                                            ),
                                            blurRadius: 2.0,
                                            spreadRadius: 1.0,
                                          ),
                                        ]
                                            : [],
                                      ),
                                      child: Text(
                                        'Current',
                                        style: GoogleFonts.poppins(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color:
                                          showCurrent
                                              ? const Color(0xFF6F4F7D)
                                              : const Color(0xFFEBEAEC),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () {
                                      if (!isAI) {
                                        setState(() {
                                          showCurrent = false;
                                          isAI = true;
                                        });
                                        _fadeController.forward(from: 0.0);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        color:
                                        showCurrent
                                            ? Colors.transparent
                                            : MyTheme.getSettingsTextColor(
                                          isDarkMode,
                                        ),
                                        border: Border.all(
                                          color: MyTheme.getSettingsTextColor(
                                            isDarkMode,
                                          ),
                                        ),
                                        boxShadow:
                                        showCurrent
                                            ? []
                                            : [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF000000,
                                            ),
                                            offset: Offset.zero,
                                            blurRadius: 4.0,
                                            spreadRadius: 1.0,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        'Recommended',
                                        style: GoogleFonts.poppins(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color:
                                          showCurrent
                                              ? const Color(0xFFEBEAEC)
                                              : const Color(0xFF6F4F7D),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                //SWIPE CALENDAR TO CHANGE WEEK
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity != null) {
                      if (details.primaryVelocity! < 0) {
                        _nextWeek();
                      } else if (details.primaryVelocity! > 0 &&
                          !today.isBefore(DateTime.now()) &&
                          !today.isAtSameMomentAs(DateTime.now())) {
                        _prevWeek();
                      }
                    }
                  },

                  //CLIPS ALL THE CALENDAR INSIDE THE ROUNDED BOX
                  child: SizedBox(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(40.0),
                      ),
                      child: Container(
                        color: MyTheme.getSettingsTextColor(isDarkMode),
                        padding: const EdgeInsets.all(14.0),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Column(
                                children: [
                                  // 🔹 Top Header: Days of the week
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      const timeColumnWidth = 35.0;
                                      final gridWidth =
                                          constraints.maxWidth -
                                              timeColumnWidth;
                                      final dayColumnWidth = gridWidth / 7;

                                      return Row(
                                        children: [
                                          SizedBox(width: timeColumnWidth),
                                          ...List.generate(7, (index) {
                                            final currentDay = startOfWeek.add(
                                              Duration(days: index),
                                            );
                                            final today = DateTime.now();
                                            final isToday =
                                                today.year == currentDay.year &&
                                                    today.month ==
                                                        currentDay.month &&
                                                    today.day == currentDay.day;

                                            return Container(
                                              width: dayColumnWidth,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color:
                                                isToday
                                                    ? Colors.deepPurple
                                                    .withOpacity(0.2)
                                                    : Colors.transparent,
                                                borderRadius:
                                                BorderRadius.circular(12),
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    DateFormat(
                                                      'E',
                                                    ).format(currentDay),
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                      FontWeight.bold,
                                                      fontSize: 14,
                                                      color: const Color(
                                                        0xFF6F4F7D,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    DateFormat(
                                                      'd',
                                                    ).format(currentDay),
                                                    style:
                                                    GoogleFonts.abhayaLibre(
                                                      fontWeight:
                                                      isToday
                                                          ? FontWeight
                                                          .bold
                                                          : FontWeight
                                                          .w600,
                                                      fontSize:
                                                      isToday ? 14 : 13,
                                                      color: const Color(
                                                        0xFFA18BAC,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),

                                  // Main calendar body - this is the modified part
                                  Expanded(
                                    child: Row(
                                      children: [
                                        // Time column (keep this as is)
                                        Container(
                                          width: 35,
                                          padding: const EdgeInsets.only(
                                            right: 10,
                                          ),
                                          child: Column(
                                            children: List.generate(13, (
                                                index,
                                                ) {
                                              return Expanded(
                                                child: Center(
                                                  child: Column(
                                                    mainAxisSize:
                                                    MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: 15,
                                                        height: 15,
                                                        decoration: BoxDecoration(
                                                          shape:
                                                          BoxShape.circle,
                                                          color:
                                                          index % 2 == 0
                                                              ? const Color(
                                                            0xFF8F9BB3,
                                                          )
                                                              : const Color(
                                                            0xFFAC8BBD,
                                                          ),
                                                        ),
                                                        child: Center(
                                                          child: Text(
                                                            _getTimeSlots(
                                                              index,
                                                            ),
                                                            style: GoogleFonts.poppins(
                                                              fontSize: 10,
                                                              fontWeight:
                                                              FontWeight
                                                                  .bold,
                                                              color:
                                                              MyTheme.getSettingsTextColor(
                                                                isDarkMode,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Text(
                                                        _getUpperSlot(index),
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 6.5,
                                                          fontWeight:
                                                          FontWeight.bold,
                                                          color:
                                                          index % 2 == 0
                                                              ? const Color(
                                                            0xFF8F9BB3,
                                                          )
                                                              : const Color(
                                                            0xFFAC8BBD,
                                                          ),
                                                        ),
                                                      ),
                                                      Text(
                                                        _getLowerSlot(index),
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 6.5,
                                                          fontWeight:
                                                          FontWeight.bold,
                                                          color:
                                                          index % 2 == 0
                                                              ? const Color(
                                                            0xFF8F9BB3,
                                                          )
                                                              : const Color(
                                                            0xFFAC8BBD,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }),
                                          ),
                                        ),

                                        // This is the modified grid section
                                        Expanded(
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              final columnWidth =
                                              (constraints.maxWidth / 7);
                                              final rowHeight =
                                                  constraints.maxHeight / 13;

                                              return Stack(
                                                children: [
                                                  // Grid background
                                                  Column(
                                                    children: List.generate(13, (
                                                        row,
                                                        ) {
                                                      return Container(
                                                        height: rowHeight,
                                                        decoration: BoxDecoration(
                                                          color:
                                                          row.isOdd
                                                              ? Color(
                                                            0xFFD2A9FF,
                                                          ).withOpacity(
                                                            0.08,
                                                          )
                                                              : null,
                                                          border: Border(
                                                            bottom: BorderSide(
                                                              color:
                                                              MyTheme.getSettingsTextColor(
                                                                isDarkMode,
                                                              ),
                                                              width: 1.0,
                                                            ),
                                                          ),
                                                        ),
                                                        child: Row(
                                                          children: List.generate(7, (
                                                              col,
                                                              ) {
                                                            return Container(
                                                              width:
                                                              columnWidth,
                                                              decoration: BoxDecoration(
                                                                border: Border(
                                                                  right:
                                                                  col < 6
                                                                      ? BorderSide(
                                                                    color: const Color(
                                                                      0xFFDCD2E0,
                                                                    ).withOpacity(
                                                                      0.5,
                                                                    ),
                                                                    width:
                                                                    1.0,
                                                                  )
                                                                      : BorderSide
                                                                      .none,
                                                                ),
                                                              ),
                                                            );
                                                          }),
                                                        ),
                                                      );
                                                    }),
                                                  ),

                                                  // Drag selection listener
                                                  Positioned.fill(
                                                    child: Listener(
                                                      onPointerDown: (details) {
                                                        if (!isAI) return;
                                                        setState(() {
                                                          _isDragSelection =
                                                          true;
                                                        });
                                                        final renderBox =
                                                        context.findRenderObject()
                                                        as RenderBox;
                                                        final localPosition =
                                                        renderBox
                                                            .globalToLocal(
                                                          details
                                                              .position,
                                                        );

                                                        setState(() {
                                                          _anchorCol =
                                                              (localPosition
                                                                  .dx /
                                                                  columnWidth)
                                                                  .floor()
                                                                  .clamp(0, 6);
                                                          _anchorRow =
                                                              (localPosition
                                                                  .dy /
                                                                  rowHeight)
                                                                  .floor()
                                                                  .clamp(0, 12);
                                                          _hoverCol =
                                                              _anchorCol;
                                                          _hoverRow =
                                                              _anchorRow;
                                                        });
                                                      },

                                                      // In your onPointerMove handler, replace with this:
                                                      onPointerMove: (details) {
                                                        if (!isAI ||
                                                            _anchorCol ==
                                                                null ||
                                                            _anchorRow == null)
                                                          return;
                                                        final renderBox =
                                                        context.findRenderObject()
                                                        as RenderBox;
                                                        final localPosition =
                                                        renderBox
                                                            .globalToLocal(
                                                          details
                                                              .position,
                                                        );

                                                        int newRow =
                                                        (localPosition.dy /
                                                            rowHeight)
                                                            .floor()
                                                            .clamp(0, 12);
                                                        final dayCode =
                                                        _getDayCodeFromCol(
                                                          _anchorCol!,
                                                        );
                                                        // Limit selection to available slots only
                                                        if (newRow >
                                                            _anchorRow!) {
                                                          // Dragging down
                                                          for (
                                                          int r =
                                                              _anchorRow! + 1;
                                                          r <= newRow;
                                                          r++
                                                          ) {
                                                            if (UserData()
                                                                .usedslot
                                                                .contains(
                                                              '${dayCode}${_getSlotCodeFromRow(r)}',
                                                            )) {
                                                              newRow = r - 1;
                                                              break;
                                                            }
                                                          }
                                                        } else {
                                                          // Dragging up
                                                          if (newRow <
                                                              _anchorRow!) {
                                                            // Dragging up
                                                            for (
                                                            int r =
                                                                _anchorRow! -
                                                                    1;
                                                            r >= newRow;
                                                            r--
                                                            ) {
                                                              if (UserData()
                                                                  .usedslot
                                                                  .contains(
                                                                '${dayCode}${_getSlotCodeFromRow(r)}',
                                                              )) {
                                                                newRow = r + 1;
                                                                break;
                                                              }
                                                            }

                                                            // Ensure we are not landing on an occupied slot
                                                            if (UserData()
                                                                .usedslot
                                                                .contains(
                                                              '${dayCode}${_getSlotCodeFromRow(_anchorRow!)}',
                                                            )) {
                                                              newRow =
                                                              _anchorRow!;
                                                            } else if (newRow >
                                                                _anchorRow!) {
                                                              newRow =
                                                              _anchorRow!;
                                                            }
                                                          }
                                                        }

                                                        setState(() {
                                                          _hoverRow = newRow;
                                                        });
                                                      },

                                                      onPointerUp: (details) {
                                                        if (!isAI) return;
                                                        setState(() {
                                                          _isDragSelection =
                                                          true;
                                                        });
                                                        if (isAI &&
                                                            _anchorCol !=
                                                                null &&
                                                            _anchorRow !=
                                                                null &&
                                                            _hoverRow != null) {
                                                          final minRow = math
                                                              .min(
                                                            _anchorRow!,
                                                            _hoverRow!,
                                                          );
                                                          final maxRow = math
                                                              .max(
                                                            _anchorRow!,
                                                            _hoverRow!,
                                                          );

                                                          setState(() {
                                                            _selectedSlots =
                                                                _getSelectedSlotCodes(
                                                                  _anchorCol!,
                                                                  minRow,
                                                                  maxRow,
                                                                );
                                                            _showPanel(
                                                              ScheduleBox(
                                                                title:
                                                                'Looking for courses on...',
                                                                code: '',
                                                                location:
                                                                '${_getDayNameFromCode(_getDayCodeFromCol(_anchorCol!))}',
                                                                scheduleCode:
                                                                _getDayCodeFromCol(
                                                                  _anchorCol!,
                                                                ) +
                                                                    _getSlotCodeFromRow(
                                                                      minRow,
                                                                    ) +
                                                                    _getSlotCodeFromRow(
                                                                      maxRow,
                                                                    ),
                                                                startHour:
                                                                8 + minRow,
                                                                durationSlots:
                                                                maxRow -
                                                                    minRow +
                                                                    1,
                                                                date:
                                                                DateTime.now(),
                                                                isWeekly: true,
                                                              ),
                                                            );

                                                            _anchorCol =
                                                                _anchorRow =
                                                                _hoverCol =
                                                                _hoverRow =
                                                            null;
                                                          });
                                                        }
                                                      },
                                                      child: MouseRegion(
                                                        onExit: (_) {
                                                          if (_anchorCol !=
                                                              null) {
                                                            setState(() {
                                                              _anchorCol =
                                                                  _anchorRow =
                                                                  _hoverCol =
                                                                  _hoverRow =
                                                              null;
                                                            });
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ),

                                                  // Selection overlay
                                                  if (_anchorCol != null &&
                                                      _hoverRow != null)
                                                    Positioned(
                                                      left:
                                                      columnWidth *
                                                          _anchorCol!,
                                                      top:
                                                      rowHeight *
                                                          math.min(
                                                            _anchorRow!,
                                                            _hoverRow!,
                                                          ),
                                                      width: columnWidth,
                                                      height:
                                                      rowHeight *
                                                          (math.max(
                                                            _anchorRow!,
                                                            _hoverRow!,
                                                          ) -
                                                              math.min(
                                                                _anchorRow!,
                                                                _hoverRow!,
                                                              ) +
                                                              1),
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          border: Border.all(
                                                            color: const Color(
                                                              0xFF582A6D,
                                                            ),
                                                            width: 2,
                                                          ),
                                                          borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                          color: const Color(
                                                            0x33582A6D,
                                                          ),
                                                        ),
                                                      ),
                                                    ),

                                                  // Existing schedule boxes
                                                  ..._buildScheduleBoxes(
                                                    scheduleBoxes,
                                                    columnWidth - 0.3,
                                                    rowHeight - 0.15,
                                                    startOfWeek,
                                                    showCurrent,
                                                    _fadeAnimation,
                                                  ),
                                                ],
                                              );
                                            },
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
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          //SIDE PANEL
          if (_panelVisible)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 5.0, // Blur intensity
                  sigmaY: 5.0,
                ),
                child: Container(
                  color: Colors.black.withOpacity(
                    0.3,
                  ), // Semi-transparent overlay
                ),
              ),
            ),
          if (_panelVisible && _selectedSchedule != null)
            Positioned(
              right: 0,
              top: MediaQuery.of(context).size.height * 0,
              bottom: 0,
              child: ScheduleDetailsPanel(
                schedule: _selectedSchedule!,
                animation: CurvedAnimation(
                  parent: _panelController,
                  curve: Curves.easeOut,
                ),
                onClose:
                    (newCourse, oldCourse) => _hidePanel(newCourse, oldCourse),
                usedSlots: UserData().usedslot,
                selectedSlots: _selectedSlots ?? {},
                isDragSelection: _isDragSelection,
                onRemoveOldCourse: removeoldcoursedata,
              ),
            ),
        ],
      ),
    );
  }
}
// ========================================================