import 'package:flutter/material.dart';
import 'dart:math';
import 'package:marquee/marquee.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'ai_similar_response.dart';
import 'dart:convert';
import '../Data/UserData.dart';
import 'MainJobs.dart';
import 'package:provider/provider.dart';
import '../widgets/theme.dart';
import 'dart:ui';

class JobInfoPage extends StatefulWidget {
  final List<Map<String, dynamic>>? availableJobs;
  final Map<String, dynamic>? jobData;
  final Map<String, dynamic>? student;
  final bool fromjob;

  const JobInfoPage({
    super.key,
    required this.fromjob,
    this.availableJobs,
    this.jobData,
    this.student,
  });

  @override
  State<JobInfoPage> createState() => _JobInfoPageState();
}

List<dynamic> jobList = [];

Future<List<String>> start_get_rec(
    Map<String, dynamic> jobData,
    List<Map<String, dynamic>> availableJobs,
    ) async {
  String response = await aisimilarresponse(jobData, availableJobs);
  String cleanResponse =
  response.replaceAll('```json', '').replaceAll('```', '').trim();
  jobList = jsonDecode(cleanResponse);
  try {
    return jobList.map((course) => course.toString()).toList();
  } catch (e) {
    return [];
  }
}

List<Map<String, dynamic>> favoriteJobs = [];

Color getLanguageColor(dynamic lang) {
  final display = getLanguageDisplay(lang);
  if (display == 'E') {
    return Colors.amber; // Yellow
  } else if (display == 'B') {
    return const Color.fromARGB(255, 165, 255, 168); // Green
  } else {
    return const Color.fromARGB(255, 188, 217, 255); // Default Blue for 文
  }
}

String getLanguageDisplay(dynamic lang) {
  if (lang == 'CH' || lang == '中文' || lang == '文') {
    return '文'; // Chinese character
  } else if (lang == 'EN' || lang == 'English') {
    return 'E'; // English letter
  } else if (lang == 'BOTH' || lang == 'Both') {
    return 'B'; // Both
  } else {
    return lang.toString(); // Default: just show whatever
  }
}

// nnt coba replace this with Firebase DocumentSnapshot values.
/*
final Map<String, dynamic> currentJob = {
  //'title': 'xxxxxxxxxxxxxxxxxxxxxxxxxxx', // 25 text maximum
  'title': 'Software Studio TA',
  'professor': 'Prof. Wu-Shan-Hung',
  'code': 'DS 4200',
  'location': 'Online via Zoom',
  'language': 'both',
};
*/

class _JobInfoPageState extends State<JobInfoPage>
    with SingleTickerProviderStateMixin {
  bool isFavorite = false;
  bool availabilityPosition = true;

  final int participants = 1;
  final int maxParticipants = 16;
  final bool interviewRequired = true;

  final double containerHeight = 325.0;

  int selectedTabIndex = 0;
  late AnimationController _tabController;
  late Animation<double> _tabAnimation;

  final List<String> tabLabels = ['Description', 'Qualifications', 'Similar'];
  late List<String> tabContents;

  Map<String, dynamic> course = {};
  List<String> similarJobs = [];
  List<Map<String, dynamic>> similarJobsList = [];

  List<Map<String, dynamic>> findSimilarJobs(
      List<String> similarJobCodes,
      List<Map<String, dynamic>> availableJobs,
      ) {
    try {
      return availableJobs
          .where((job) => similarJobCodes.contains(job['code']))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> fetchSimilarJobs() async {
    final List<String> fetchedCodes = List<String>.from(
      await start_get_rec(widget.jobData!, widget.availableJobs!),
    );
    setState(() {
      similarJobs = fetchedCodes;
      similarJobsList = findSimilarJobs(fetchedCodes, widget.availableJobs!);
      print("📌 Similar Jobs Codes: $similarJobs");
      print("📌 Matched Job Data: $similarJobsList");
    });
  }

  Future<void> saveFirebase(String type, String studentID, String code) async {
    final docRef = FirebaseFirestore.instance
        .collection('Student')
        .doc(studentID);

    if (type == 'JOB') {
      await docRef.update({
        'JOB.SAVED': FieldValue.arrayUnion([code]),
      });
    } else if (type == 'ANNOUNCEMENT') {
      await docRef.update({
        'ANNOUNCEMENT': FieldValue.arrayUnion([code]),
      });
    }
  }

  Future<void> removeFirebase(
      String type,
      String studentID,
      String code,
      ) async {
    final docRef = FirebaseFirestore.instance
        .collection('Student')
        .doc(studentID);

    if (type == 'JOB') {
      await docRef.update({
        'JOB.SAVED': FieldValue.arrayRemove([code]),
      });
    } else if (type == 'ANNOUNCEMENT') {
      await docRef.update({
        'ANNOUNCEMENT': FieldValue.arrayRemove([code]),
      });
    }
  }

  Widget buildTitle(String title) {
    if (title.length <= 25) {
      return Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.bold,
          color: Color(0xFF7A9AC4),
        ),
      );
    } else {
      return SizedBox(
        height: 30,
        width: MediaQuery.of(context).size.width * 0.65,
        child: Marquee(
          text: title,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7A9AC4),
          ),
          scrollAxis: Axis.horizontal,
          blankSpace: 40.0,
          velocity: 10.0,
          pauseAfterRound: Duration(seconds: 1),
          startPadding: 10.0,
          accelerationDuration: Duration(seconds: 1),
          accelerationCurve: Curves.linear,
          decelerationDuration: Duration(milliseconds: 500),
          decelerationCurve: Curves.easeOut,
        ),
      );
    }
  }

  //Widget _buildSimilarJobsList() {
  // return Padding(
  //   padding: const EdgeInsets.symmetric(vertical: 0),
  //  child: Column(
  //      crossAxisAlignment: CrossAxisAlignment.start,
  //    children: [
  //       ...similarJobs.map((job) => buildSimilarJobCard(job)).toList(),
  //      const SizedBox(height: 200), // Add extra space to extend scroll view
  //    ],
  //  ),
  // );
  //}

  String normalizeCourseCode(String? rawCode) {
    if (rawCode == null) return '';

    // Remove extra spaces
    String cleaned = rawCode.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Match only exact '11320CS' or '11320EE' followed by optional space and digits
    final match = RegExp(r'^(11320(?:CS|EE))\s*(\d{5,6})$').firstMatch(cleaned);
    if (match != null) {
      final dept = match.group(1); // '11320CS' or '11320EE'
      final number = match.group(2); // course number
      return '$dept  $number'; // normalize with single space
    }

    return cleaned; // untouched if not CS or EE
  }

  Future<void> _fetchCourse() async {
    try {
      final normalizedCode = normalizeCourseCode(widget.jobData?['code']);
      final docSnapshot =
      await FirebaseFirestore.instance
          .collection('Course')
          .doc(normalizedCode)
          .get();
      final Map<String, dynamic> courseData = docSnapshot.data()!;

      setState(() {
        course = courseData;
      });
    } catch (e) {
      print("Error fetching course: $e");
    }
  }

  List<Map<String, dynamic>> filteredjobs = [];

  void fetchdata() async {
    final querySnapshot1 =
    await FirebaseFirestore.instance.collection('TA Application').get();

    final List<Map<String, dynamic>> loadedJobs =
    querySnapshot1.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .where((jobData) {
      final qualification = jobData['qualifications'];
      if (qualification == {} || qualification == []) return true;
      final takenCourses = UserData().getAllCourseNames();
      if (!takenCourses.contains(jobData['title'])) {
        print('blm ambil ${jobData['title']}');
        return false;
      }

      final matchingCourse = UserData().coursestaken.firstWhere(
            (courseName) => courseName['name'] == jobData['title'],
      );
      print('matching:${matchingCourse['name']}');

      final double? courseGpaValue =
      gpachart[matchingCourse['gpa']?.toString()];
      final double? requiredGpaValue =
      gpachart[jobData['qualifications']?['minimum_course_grades']
          ?.toString()];

      if (courseGpaValue != null && requiredGpaValue != null) {
        print(requiredGpaValue);
        if (courseGpaValue < requiredGpaValue) {
          return false;
        }
      }

      if (matchingCourse['t-score'] != null &&
          jobData['qualifications']?['minimum_t_score_average'] !=
              null) {
        print(jobData['qualifications']?['minimum_t_score_average']);
        if (matchingCourse['t-score'] <
            jobData['qualifications']?['minimum_t_score_average']) {
          return false;
        }
      }

      final raw = jobData['qualifications']?['prerequisites'];

      final prerequisites = <String>[];
      if (raw is List) {
        for (final item in raw) {
          final str = item?.toString()?.trim();
          if (str != null && str.isNotEmpty) {
            prerequisites.add(str);
          }
        }
      }

      print('Prerequisites length: ${prerequisites.length}');
      print('Prerequisites content: $prerequisites');
      print(
        'Prerequisites types: ${prerequisites.map((e) => e.runtimeType)}',
      );

      if (prerequisites.isEmpty) {
        return true;
      }

      return takenCourses.containsAll(prerequisites.toSet());
    })
        .toList();
    setState(() {
      filteredjobs = loadedJobs;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchdata();
    fetchSimilarJobs();
    _fetchCourse();
    tabContents = [
      widget.jobData?['description']['text'] ?? 'No description available.',
      'These are the Qualifications required for the position.',
      'These are similar jobs.',
    ];
    _tabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _tabAnimation = Tween<double>(begin: 0, end: 0).animate(_tabController);
  }

  void switchTab(int index) {
    _tabAnimation = Tween<double>(
      begin: _tabAnimation.value,
      end: index / 3,
    ).animate(CurvedAnimation(parent: _tabController, curve: Curves.easeInOut));
    _tabController.forward(from: 0);
    setState(() => selectedTabIndex = index);
  }

  void swipeLeft() =>
      selectedTabIndex < 2 ? switchTab(selectedTabIndex + 1) : null;
  void swipeRight() =>
      selectedTabIndex > 0 ? switchTab(selectedTabIndex - 1) : null;

  void showSuccess() async {
    final jobCode = widget.jobData?['code'];
    final studentID = widget.student?['ID'];
    final studentName = widget.student?['CHINESE'];

    if (widget.jobData?['applicants'].containsKey(studentID)) {
      if (widget.jobData?['applicants']?[studentID]['status'] == 'P') {
        showDialog(
          context: context,
          builder:
              (c) => AlertDialog(
            title: const Text('Warning'),
            content: const Text('Already Applied!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      } else if (widget.jobData?['applicants']?[studentID]['status'] == 'R') {
        showDialog(
          context: context,
          builder:
              (c) => AlertDialog(
            title: const Text('Warning'),
            content: const Text('Already Rejected!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    }

    if (!filteredjobs.contains(widget.jobData?['title']) && !widget.fromjob) {
      showDialog(
        context: context,
        builder:
            (c) => AlertDialog(
          title: const Text('Warning'),
          content: const Text(
            'You are not eligable for this position yet. Work harder!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (widget.jobData?['applicants'].length >=
        widget.jobData?['quota']['max']) {
      showDialog(
        context: context,
        builder:
            (c) => AlertDialog(
          title: const Text('Warning'),
          content: const Text('Quota Reached!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      final snapshot =
      await FirebaseFirestore.instance
          .collection('Student')
          .doc(UserData().id)
          .get();

      if (!snapshot.exists) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No user data found')));
        return;
      }

      final githubUrl = snapshot.data()?['GITHUB'] as String?;

      if (githubUrl == null || githubUrl.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No GitHub URL found')));
        return;
      }

      final linkedinUrl = snapshot.data()?['LINKEDIN'] as String?;

      if (linkedinUrl == null || linkedinUrl.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No GitHub URL found')));
        return;
      }

      final snapshot2 =
      await FirebaseFirestore.instance
          .collection('Student')
          .doc(UserData().id)
          .collection('CV')
          .get();

      final CV = snapshot2.docs.map((doc) => doc.data()).toList();

      (widget.student?['JOB']['APPLIED'] as List).add({
        'ID': jobCode,
        'STATUS': 'P',
        'GITHUB': githubUrl,
        'LINKEDIN': linkedinUrl,
        'CV': CV,
      });

      await FirebaseFirestore.instance
          .collection('Student')
          .doc(studentID)
          .update({
        'JOB.APPLIED': FieldValue.arrayUnion([
          {
            'ID': jobCode,
            'STATUS': 'P',
            'GITHUB': githubUrl,
            'LINKEDIN': linkedinUrl,
            'CV': CV,
          },
        ]),
      });

      widget.jobData?['applicants'][studentID] = {
        'name': studentName,
        'status': 'P', // P = Pending
        'GITHUB': githubUrl,
        'LINKEDIN': linkedinUrl,
        'CV': CV,
      };

      await FirebaseFirestore.instance
          .collection(
        'TA Application',
      ) // replace with your actual job collection name
          .doc(jobCode)
          .update({
        'applicants.$studentID': {
          'name': studentName,
          'status': 'P',
          'GITHUB': githubUrl,
          'LINKEDIN': linkedinUrl,
          'CV': CV,
        },
        'quota.current': FieldValue.increment(1),
      });

      widget.jobData?['quota']['current'] += 1;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }

    showDialog(
      context: context,
      builder:
          (c) => AlertDialog(
        title: const Text('Success'),
        content: const Text('Application Successful!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  //──────────────────────────────────────────────────────────────
  //  QUALIFICATIONS SECTION
  //──────────────────────────────────────────────────────────────
  /*
  // hardcode
    Widget _buildQualificationsContent() {
    const barDecoration = BoxDecoration(
      color: Color.fromARGB(7, 255, 255, 255),
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
    );

    Widget bullet(Color c, String txt) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(txt,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: c)),
          ],
        );

    /*
    Widget barKV(String k, String v) => Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: barDecoration,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(k,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              Text(v,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color.fromARGB(255, 246, 245, 215))),
            ],
          ),
        );
    */

      Widget barKV(String k, String v, {double? width}) => Container(
      width: width ?? double.infinity, // If width not passed, use full width
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: barDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          Text(v,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color.fromARGB(255, 246, 245, 215))),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Only Prerequisites title inside box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: barDecoration,
          child: const Text(
            'Prerequisites',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white),
          ),
        ),

        const SizedBox(height: 12),

        // Bullets outside box
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              bullet(const Color(0xFF6EC3FF), 'Introduction To Programming I'),
              bullet(const Color(0xFFFFE272), 'Calculus I'),
              bullet(const Color(0xFFFF7A7A), 'Introduction To Statistics'),
              bullet(const Color(0xFFCFF5D4), 'xxxxx'),
            ],
          ),
        ),

        const SizedBox(height: 10),

        /*
        // Other bars
        barKV('Minimum Course Grades', 'A'),
        const SizedBox(height: 10),
        barKV('Minimum T-Score Average', '50.0'),
        const SizedBox(height: 10),
        barKV('Schedule', 'M1M2T3T4'),
        const SizedBox(height: 10),
        barKV('Credits', '3'),
        */
        // Other bars
      barKV('Minimum Course Grades', 'A', width: MediaQuery.of(context).size.width * 0.9),
      const SizedBox(height: 20),
      barKV('Minimum T-Score Average', '50.0', width: MediaQuery.of(context).size.width * 0.8),
      const SizedBox(height: 20),
      barKV('Schedule', 'M1M2T3T4', width: MediaQuery.of(context).size.width * 0.7),
      const SizedBox(height: 20),
      barKV('Credits', '3', width: MediaQuery.of(context).size.width * 0.6),
      ],
    );
  }
  */

  Widget _buildQualificationsContent() {
    const barDecoration = BoxDecoration(
      color: Color.fromARGB(7, 255, 255, 255),
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
    );

    Widget bullet(Color color, String txt) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, // smaller bullet
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          txt,
          style: TextStyle(
            // font prerequisites details text
            fontSize: 16, // smaller font
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );

    Widget barKV(String k, dynamic v, {required double width}) => Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: barDecoration,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              k,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              v.toString(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color.fromARGB(255, 246, 245, 215),
              ),
            ),
          ],
        ),
      ),
    );

    final List<String> preCourses = List<String>.from(
      widget.jobData?['qualifications']?['prerequisites'] ?? [],
    );

    final List<Color> colors = [
      const Color.fromARGB(255, 177, 222, 255),
      const Color(0xFFFFE272),
      const Color.fromARGB(255, 246, 195, 255),
      const Color(0xFFCFF5D4),
      const Color(0xFFA1D6E2),
      const Color(0xFFF7CAC9),
    ];

    String extractSchedule(String schedule) {
      List<String> parts = schedule
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim()
          .split(' ');
      String result = '';
      for (int idx = 0; idx < parts.length; idx++) {
        if (idx % 2 == 1) {
          result += parts[idx];
        }
      }
      return result;
    }

    final List<Map<String, dynamic>> qualificationsData = [
      {
        'title': 'Minimum Course Grades',
        'value': widget.jobData?['qualifications']?['minimum_course_grades'],
      },
      {
        'title': 'Minimum T-Score Average',
        'value': widget.jobData?['qualifications']?['minimum_t_score_average'],
      },
      {
        'title': 'Schedule',
        'value': extractSchedule(course['class_room_and_time']),
      },
      {'title': 'Credits', 'value': course['credit']},
    ];

    final random = Random();
    List<Color> shuffledColors = List.from(colors)..shuffle(random);

    return Builder(
      builder: (context) {
        final double screenWidth = MediaQuery.of(context).size.width;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prerequisites box
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: screenWidth * 0.95,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: barDecoration,
                child: const Text(
                  'Prerequisites',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Bullets
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                alignment: WrapAlignment.start,
                spacing: 16,
                runSpacing: 16, // More vertical spacing between bullets
                children: List.generate(
                  min(3, preCourses.length),
                      (index) => bullet(shuffledColors[index], preCourses[index]),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Qualification bars
            ...List.generate(qualificationsData.length, (index) {
              final double widthFactor = 0.95 - (index * 0.05);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: barKV(
                  qualificationsData[index]['title']!,
                  qualificationsData[index]['value'],
                  width: screenWidth * widthFactor,
                ),
              );
            }),

            const SizedBox(height: 10),

            // Correct Last Updated (not hardcoded)
            /*
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              lastUpdatedText,
              style: const TextStyle(
                color: Color.fromARGB(92, 255, 255, 255),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),*/
          ],
        );
      },
    );
  }

  bool isSavedJob(String jobCode, Map<String, dynamic> student) {
    final saved = student['JOB']?['SAVED'] ?? [];
    return saved.contains(jobCode);
  }

  void addRemoveSavedJob(String jobCode, Map<String, dynamic> student) {
    if (student['JOB']['SAVED'].contains(jobCode)) {
      student['JOB']['SAVED'].remove(jobCode);
      removeFirebase('JOB', student['ID'], jobCode);
    } else {
      student['JOB']['SAVED'].add(jobCode);
      saveFirebase('JOB', student['ID'], jobCode);
    }
  }

  Widget buildSimilarJobCard(Map<String, dynamic> job) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    try {
      return Padding(
        padding: const EdgeInsets.only(
          bottom: 8,
        ), // Reduced spacing between cards
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => JobInfoPage(
                  fromjob: false,
                  availableJobs: widget.availableJobs,
                  jobData: job,
                  student: widget.student,
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.92,
                decoration: BoxDecoration(
                  color: MyTheme.getSettingsTextColor(isDarkMode).withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: MyTheme.getSettingsTextColor(isDarkMode).withAlpha(40),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),

                child: Container(
                  width: MediaQuery.of(context).size.width * 0.92,
                  decoration: BoxDecoration(
                    color: MyTheme.getSettingsTextColor(isDarkMode).withAlpha(70),
                    borderRadius: BorderRadius.circular(
                      12,
                    ), // Slightly smaller radius
                  ),
                  padding: const EdgeInsets.all(10), // Reduced internal padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job['title'],
                        style: TextStyle(
                          color: isDarkMode ? Color(0xFF33183E) : Color(0xFF582A6D),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ), // Smaller font
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${job['code'].substring(5)} - ${job['professor']['EN']}',
                        style: TextStyle(
                          color: isDarkMode ? Color(0xFF33183E) : Color(0xFF582A6D),
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ), // Smaller font
                      ),
                      const Divider(color: Colors.white24, height: 14),
                      Row(
                        children: [
                          if (job['applicants']?[widget.student?['ID']]?['status'] ==
                              'P')
                            const Text(
                              '● Applied',
                              style: TextStyle(
                                color: Color(0xFFF7B2D9),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            )
                          else if (job['applicants']?[widget
                              .student?['ID']]?['status'] ==
                              'R')
                            const Text(
                              '● Rejected',
                              style: TextStyle(
                                color: Color.fromARGB(255, 255, 129, 129),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: getLanguageColor(job['lang']),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            getLanguageDisplay(job['lang']),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: getLanguageColor(job['lang']),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${job['applicants'].length}/${job['quota']['max']} Applicants',
                            style: const TextStyle(
                              color: Color.fromARGB(255, 243, 220, 255),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                // job['favorite'] = !(job['favorite'] ?? false);
                                addRemoveSavedJob(job['code'], widget.student!);
                              });
                            },
                            child: Icon(
                              isSavedJob(job['code'], widget.student!)
                                  ? Icons.star
                                  : Icons.star_border,
                              color: const Color.fromARGB(255, 196, 221, 255),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      return Text('error');
    }
  }

  bool isSaved(String jobCode, Map<String, dynamic> student) {
    final saved = student['JOB']?['SAVED'] ?? [];
    return saved.contains(jobCode);
  }

  void addRemoveSaved(String jobCode, Map<String, dynamic> student) {
    if (student['JOB']['SAVED'].contains(jobCode)) {
      student['JOB']['SAVED'].remove(jobCode);
      removeFirebase('JOB', student['ID'], jobCode);
    } else {
      student['JOB']['SAVED'].add(jobCode);
      saveFirebase('JOB', student['ID'], jobCode);
    }
  }

  //──────────────────────────────────────────────────────────────
  //  UI
  //──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double screenHeight = mediaQuery.size.height;
    final double keyboardHeight = mediaQuery.viewInsets.bottom;
    final bool isKeyboardVisible = keyboardHeight > 0;

    final applicantsColor =
    widget.jobData?['applicants'].length >= widget.jobData?['quota']['max']
        ? Colors.red
        : const Color(0xFF758E4F);
    final interviewIcon =
    widget.jobData?['interview'] == 'Required'
        ? Icons.sentiment_satisfied_alt
        : Icons.sentiment_dissatisfied;
    final interviewColor =
    interviewRequired ? const Color(0xFF758E4F) : Colors.red;

    // decide paddings based on tab
    final EdgeInsets contentPadding =
    selectedTabIndex == 1
        ? EdgeInsets
        .zero // <-- NO padding when in Qualifications
        : const EdgeInsets.symmetric(horizontal: 20);

    // Timestamp
    final Timestamp? lastUpdated =
    widget.jobData?['description']?['last_updated'];
    final String formattedDate =
    lastUpdated != null
        ? 'Last Updated ${DateFormat('dd/MM/yy').format(lastUpdated.toDate())}'
        : 'Last Updated -';

    final double labelWidth =
    selectedTabIndex == 1
        ? double.infinity
        : MediaQuery.of(context).size.width * 0.9;

    final EdgeInsets lastUpdatedPad =
    selectedTabIndex == 1
        ? EdgeInsets.only(left: 10)
        : const EdgeInsets.only(left: 10);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onHorizontalDragEnd:
            (d) => d.primaryVelocity! < 0 ? swipeLeft() : swipeRight(),
        child: Stack(
          children: [
            // background
            Container(
              decoration: BoxDecoration(
                gradient:
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
              ),
            ),

            // header (unchanged)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(80),
                ),
                child: Container(
                  height: containerHeight,
                  color: MyTheme.getSettingsTextColor(isDarkMode),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.black54,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color:
                                  availabilityPosition
                                      ? Colors.green
                                      : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            buildTitle(
                              widget.jobData?['title'] ?? 'Course Name',
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap:
                                  () => setState(
                                    () => addRemoveSaved(
                                  widget.jobData?['code'],
                                  widget.student!,
                                ),
                              ),
                              child: Icon(
                                isSaved(
                                  widget.jobData?['code'],
                                  widget.student!,
                                )
                                    ? Icons.star
                                    : Icons.star_border,
                                color: const Color(0xFF7A9AC4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '(${widget.jobData?['professor']?['CH'] ?? 'Unknown'} / ${widget.jobData?['professor']?['EN'] ?? 'Unknown'})',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 8,
                              color: Color(0xFF7A9AC4),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.jobData?['code'] ?? 'Course Code',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7A9AC4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.jobData?['location'] ?? 'Location',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFAAC1DF),
                          ),
                        ),

                        const SizedBox(height: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _InfoCircle(
                              top: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text:
                                      '${widget.jobData?['applicants'].length}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: applicantsColor,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                      '/${widget.jobData?['quota']['max']}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              label: 'Applicants',
                            ),
                            const SizedBox(width: 40),

                            /*
                            _InfoCircle(
                              top: const Text('文',
                                  style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4B8289))),
                              label: 'Language',
                            ),*/
                            // hardcode
                            _InfoCircle(
                              top: Text(
                                getLanguageDisplay(widget.jobData?['lang']),
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: getLanguageColor(
                                    widget.jobData?['lang'],
                                  ),
                                ),
                              ),
                              label: 'Language',
                            ),

                            const SizedBox(width: 40),
                            _InfoCircle(
                              top: Icon(
                                interviewIcon,
                                size: 30,
                                color: interviewColor,
                              ),
                              label: 'Interview',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // body
            Positioned(
              top: containerHeight + 20,
              left: 0,
              right: 0,
              bottom: 20,
              child: Column(
                children: [
                  // tab bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.maxWidth / 3;
                          return Stack(
                            children: [
                              AnimatedBuilder(
                                animation: _tabAnimation,
                                builder:
                                    (_, __) => Positioned(
                                  left:
                                  _tabAnimation.value *
                                      constraints.maxWidth,
                                  child: Container(
                                    width: w,
                                    height: 45,
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                        48,
                                        231,
                                        231,
                                        231,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Row(
                                children: List.generate(3, (i) {
                                  final sel = i == selectedTabIndex;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () => switchTab(i),
                                      child: Center(
                                        child: Text(
                                          tabLabels[i],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color:
                                            sel
                                                ? Colors.white
                                                : Colors.white.withOpacity(
                                              0.7,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // content wrapper – conditional padding
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // grey section label OUTSIDE of Padding (but not shown in Qualifications tab)
                        if (selectedTabIndex != 1)
                          Container(
                            width: labelWidth,
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(7, 255, 255, 255),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(24),
                                bottomRight: Radius.circular(24),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              child: Text(
                                tabLabels[selectedTabIndex],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 10),

                        // Now apply padding only for the remaining content
                        Expanded(
                          child: Padding(
                            padding: contentPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Scrollable content area
                                Expanded(
                                  child:
                                  selectedTabIndex == 2
                                      ? (similarJobs.length == 0
                                      ? Center(
                                    child: Text(
                                      'No similar jobs found',
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Color.fromARGB(
                                          223,
                                          209,
                                          209,
                                          209,
                                        ),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.justify,
                                    ),
                                  )
                                      : ListView.builder(
                                    itemCount: similarJobs.length,
                                    padding: const EdgeInsets.only(
                                      bottom: 120,
                                    ),
                                    itemBuilder: (context, index) {
                                      return buildSimilarJobCard(
                                        similarJobsList[index],
                                      );
                                    },
                                  ))
                                      : SingleChildScrollView(
                                    child:
                                    selectedTabIndex == 1
                                        ? _buildQualificationsContent()
                                        : Padding(
                                      padding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 24.0,
                                      ), // <-- Adjust padding here
                                      child: Text(
                                        tabContents[selectedTabIndex],
                                        style: const TextStyle(
                                          fontStyle:
                                          FontStyle.italic,
                                          color: Color.fromARGB(
                                            223,
                                            251,
                                            237,
                                            251,
                                          ),
                                          fontSize: 16,
                                          fontWeight:
                                          FontWeight.w500,
                                        ),
                                        textAlign:
                                        TextAlign.justify,
                                      ),
                                    ),
                                  ),
                                ),

                                // Footer area (not scrollable)
                                if (selectedTabIndex == 0) ...[
                                  const SizedBox(height: 20),
                                  Padding(
                                    padding: lastUpdatedPad,
                                    child: Text(
                                      formattedDate,
                                      style: const TextStyle(
                                        color: Color.fromARGB(
                                          92,
                                          255,
                                          255,
                                          255,
                                        ),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 40),
                                Center(
                                  child:
                                  (widget.jobData?['applicants']?[widget
                                      .student?['ID']]?['status'] !=
                                      'P')
                                      ? ElevatedButton(
                                    onPressed: showSuccess,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                      MyTheme.getSettingsTextColor(
                                        isDarkMode,
                                      ),
                                      foregroundColor: Colors.black,
                                      padding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 150,
                                        vertical: 20,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(30),
                                      ),
                                      elevation: 8,
                                    ),
                                    child: const Text(
                                      'Apply',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  )
                                      : ElevatedButton(
                                    onPressed: null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                      foregroundColor: Colors.black,
                                      padding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 150,
                                        vertical: 20,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(30),
                                      ),
                                      elevation: 8,
                                    ),
                                    child: const Text(
                                      'Applied',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 50),
                              ],
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
      ),
    );
  }
}

class _InfoCircle extends StatelessWidget {
  final Widget top;
  final String label;
  const _InfoCircle({required this.top, required this.label});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Center(child: top),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: const TextStyle(color: Colors.grey, fontSize: 11),
        textAlign: TextAlign.center,
      ),
    ],
  );
}

class JobInfoPageFromJob extends StatelessWidget {
  final Map<String, dynamic> job;

  const JobInfoPageFromJob({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(job['title']),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: Text(
          'You opened: ${job['title']} by ${job['professor']}\nLanguage: ${getLanguageDisplay(job['lang'])}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
