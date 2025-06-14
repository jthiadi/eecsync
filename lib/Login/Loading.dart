import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'PreviewPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../Data/UserData.dart';
import '../Data/CourseData.dart';
import '../Calendar/schedule_data.dart';
import 'package:flutter/cupertino.dart';
import '../Data/course_rec_data.dart';
import 'package:provider/provider.dart';
import '../widgets/theme.dart';

String convertGPAtoLetterGrade(double gpa) {
  final reversed = {
    4.3: 'A+',
    4.0: 'A',
    3.7: 'A-',
    3.3: 'B+',
    3.0: 'B',
    2.7: 'B-',
    2.3: 'C+',
    2.0: 'C',
    1.7: 'C-',
    1.0: 'D',
    0.0: 'E',
  };

  final sortedThresholds =
      reversed.keys.toList()..sort((a, b) => b.compareTo(a));

  for (final threshold in sortedThresholds) {
    if (gpa >= threshold) {
      return reversed[threshold]!;
    }
  }

  return 'E';
}

final Map<String, double> gpachart = {
  'A+': 4.3,
  'A': 4.0,
  'A-': 3.7,
  'B+': 3.3,
  'B': 3.0,
  'B-': 2.7,
  'C+': 2.3,
  'C': 2.0,
  'C-': 1.7,
  'D': 1.0,
  'E': 0.0,
  'X': 0.0,
};

Future<void> fetchUserData(
  String userID,
  List<String> preferences,
  Map<String, List<String>> selected,
) async {
  UserData().clear();
  try {
    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance
            .collection('Student')
            .doc(userID)
            .get();

    if (snapshot.exists) {
      Map<String, dynamic> userData = snapshot.data() as Map<String, dynamic>;
      List<int> temp=[];
      for (var i in userData['RANK']) {
        temp.add(i);
      }

      UserData().fromMap({
        'id': userID,
        'name': userData['NAME'] ?? 'Unknown',
        'chinese_name': userData['CHINESE'] ?? 'Unknown',
        'semester': userData['SEMESTER'] ?? 0,
        'profile': userData['PROFILE'] ?? '',
        'rank': temp ?? [],
        'preferences': preferences,
        'selectedData': selected,
      });

      var box = await Hive.openBox('userBox');
      await box.put('userData', {
        'id': userID,
        'name': userData['NAME'] ?? 'Unknown',
        'chinese_name': userData['CHINESE'] ?? 'Unknown',
        'semester': userData['SEMESTER'] ?? 0,
        'profile': userData['PROFILE'] ?? '',
        'rank': temp ?? [],
        'preferences': preferences,
        'selectedData': selected,
      });
    }
  } catch (e) {
    print("Error fetching user data: $e");
  }
}

Future<void> fetchTakenCourseDetails(String userID) async {
  final firestore = FirebaseFirestore.instance;
  final box = await Hive.openBox<CourseData>('all_courses');
  QuerySnapshot recommendedSnapshot =
      await FirebaseFirestore.instance
          .collection('Student')
          .doc(UserData().id)
          .collection('RECOMMENDED')
          .get();

  for (var doc in recommendedSnapshot.docs) {
    if (doc.id == 'test') continue;
    final course = box.values.firstWhere((course) => doc.id == course.id);
    print(UserData().usedslot);
    print(course.classTime);
    addusedslot(course.classTime ?? '');
    UserData().recommended.add(course.id);
    print(course.classTime);
    //recommendedList.add(doc.id);
  }
  final courseBox = await Hive.openBox<CourseData>('all_courses');
  double total_gpa = 0.0;
  double total_credit = 0.0;

  final courseSnapshot =
      await firestore
          .collection('Student')
          .doc(userID)
          .collection('COURSE')
          .get();

  final courses = await Future.wait(
    courseSnapshot.docs.map((doc) async {
      final courseRef = firestore
          .collection('Student')
          .doc(userID)
          .collection('COURSE')
          .doc(doc.id);
      //print(doc.id);

      if (doc['SEMESTER'] < UserData().semester && doc['GRADE'] != 'W') {
        print(doc.id);
        total_gpa += (gpachart[doc['GRADE']] ?? 0) * (doc['CREDIT'] as num);
        total_credit += doc['CREDIT'];
        UserData().passed += 1;
        UserData().credits += (doc['CREDIT'] as num).toInt();
      } else if (doc['SEMESTER'] < UserData().semester) {
        print("tes");
        UserData().withdrawals += 1;
      }

      final courseData;
      if (doc.id.indexOf(' ') == 2)
        courseData = courseBox.get('11320${doc.id.replaceFirst(' ', '  ')}');
      else
        courseData = courseBox.get('11320${doc.id}');
      if (courseData != null) {
        final updates = <String, dynamic>{};

        // if (!doc.data().containsKey('CREDIT') || doc.data()['CREDIT'] == null) {
        //   updates['CREDIT'] = courseData.credit;
        // }

        // if (!doc.data().containsKey('NAME') || doc.data()['NAME'] == null) {
        //   updates['NAME'] = courseData.name;
        // }

        if (updates.isNotEmpty) {
          await courseRef.update(updates);
        }
        print(doc['NAME']);
        if (doc['SEMESTER'] == UserData().semester) {
          final temp = courseBox.values.firstWhere(
            (course) => doc.id == course.id,
          );
          print(temp.classTime);
          addusedslot(temp.classTime ?? "");
        }

        return {
          'code': doc.id,
          'name': doc['NAME'] ?? 'Unknown',
          'gpa': doc.data().containsKey('GRADE') ? doc['GRADE'] : 99,
          't-score': doc.data().containsKey('T-SCORE') ? doc['T-SCORE'] : 99,
          'semester': doc.data().containsKey('SEMESTER') ? doc['SEMESTER'] : 99,
          'credit': doc.data().containsKey('CREDIT') ? doc['CREDIT'] : 99,
        };
      }

      //print(doc['NAME']);

      return {
        'code': doc.id,
        'name': doc['NAME'] ?? 'Unknown',
        'gpa': doc.data().containsKey('GRADE') ? doc['GRADE'] : 99,
        't-score': doc.data().containsKey('T-SCORE') ? doc['T-SCORE'] : 99,
        'semester': doc.data().containsKey('SEMESTER') ? doc['SEMESTER'] : 99,
        'credit': doc.data().containsKey('CREDIT') ? doc['CREDIT'] : 99,
      };
    }),
  );

  UserData().gpa = total_gpa / total_credit;

  print(courses);

  final validCourses = courses.where((course) => course != null).toList();
  print(validCourses);
  UserData().setCourses(validCourses.cast<Map<String, dynamic>>());
  loadScheduleData();
}

Future<void> fetchAllCoursesToHive() async {
  final box = await Hive.openBox<CourseData>('all_courses');
  final metaBox = await Hive.openBox('metadataBox');

  // if (box.isNotEmpty) {
  //    print('✅ Courses already cached in Hive. Skipping fetch.');
  //    return;
  // }

  final firestore = FirebaseFirestore.instance;
  DateTime? localLastUpdated = metaBox.get('lastUpdated') as DateTime?;
  final firestoreLastUpdatedDoc =
      await firestore.collection('Course').doc('lastUpdated').get();
  final Timestamp firestoreLastUpdatedTimestamp =
      firestoreLastUpdatedDoc['lastUpdated'];
  DateTime firestoreLastUpdated = firestoreLastUpdatedTimestamp.toDate();
  if (localLastUpdated != null &&
      !firestoreLastUpdated.isAfter(localLastUpdated)) {
    print('Courses already up-to-date.');
    return;
  }

  DocumentSnapshot? lastDoc;
  bool more = true;

  while (more) {
    Query query = firestore
        .collection('Course')
        .orderBy(FieldPath.documentId)
        .limit(500);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.get();
    if (snapshot.docs.isEmpty) {
      more = false;
      break;
    }

    final Map<String, CourseData> courseMap = {};

    for (final doc in snapshot.docs) {
      if (doc.id == 'lastUpdated') continue;
      final data = doc.data() as Map<String, dynamic>;

      final course = CourseData(
        id:
            doc.id
                .replaceFirst(RegExp(r'^\d+'), '')
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim(),
        name: data['english_title'] ?? 'Unknown',
        credit: int.tryParse(data['credit']?.toString() ?? '0') ?? 0,
        professor: data['teacher'] ?? 'Unknown',
        classTime:
            data['class_room_and_time'] != ''
                ? (data['class_room_and_time'].split(
                      '\t',
                    )[data['class_room_and_time'].split('\t').length - 1] ??
                    'Unknown')
                : 'Unknown',
        location:
            data['class_room_and_time'] != ''
                ? (data['class_room_and_time'].split('\t')[0] ?? 'Unknown')
                : 'Unknown',
        syllabus: data.containsKey('syllabus') ? data['syllabus'] : 'Unknown',
        grading: data.containsKey('grading') ? data['grading'] : 'Unknown',
      );

      //print(course.location);
      // print(course.id.length);

      courseMap[doc.id] = course;
    }

    await box.putAll(courseMap);
    lastDoc = snapshot.docs.last;

    if (snapshot.docs.length < 500) {
      more = false;
    }
  }

  //Set<String> recommendedList = {};

  //print(UserData().recommended);
  availablecourses = getCourses();
  await metaBox.put('lastUpdated', firestoreLastUpdated);
  print('✅ All courses saved to Hive successfully.');
}

class Loading1 extends StatefulWidget {
  final String ID;
  final List<String> userpreferences;
  final Map<String, List<String>> selected;
  const Loading1({
    super.key,
    required this.ID,
    required this.userpreferences,
    required this.selected,
  });

  @override
  State<Loading1> createState() => _Loading1State();
}

class _Loading1State extends State<Loading1>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _bgFade;
  bool _datafetched = false;
  bool _animationdone = false;

  void _tryNavigate() {
    if (_datafetched && _animationdone) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => Loading2(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1400),
    );

    // Bounce animation for the logo
    _logoScale = TweenSequence<double>([
      // EXPAND ANIMATION
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.4,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40.0,
      ),
      // PAUSE ANIMATION
      TweenSequenceItem(tween: ConstantTween<double>(1.4), weight: 40.0),
      // SHIRNK + DISAPPEAR
      TweenSequenceItem(
        tween: Tween(
          begin: 1.4,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30.0,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Fade animation for the background
    _bgFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    fetchUserData(widget.ID, widget.userpreferences, widget.selected).then((_) {
      setState(() {
        _datafetched = true;
      });
      // If animation is already complete, navigate immediately
      _tryNavigate();
    });

    // Start the animation after a delay
    Timer(Duration(seconds: 1), () {
      _controller.forward().then((_) {
        _animationdone = true;
        _tryNavigate();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF1F1B33) : Colors.white,
      body: Center(
        child: Stack(
          children: [
            // Background with fade animation
            AnimatedBuilder(
              animation: _bgFade,
              builder: (context, child) {
                return Opacity(
                  opacity: _bgFade.value,
                  child:
                  // Align(
                  //   alignment: Alignment(0, 2.4),
                  //   child: Image.asset('assets/loadingbg.png', scale: 0.9),
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
                );
              },
            ),

            // Logo with bounce animation
            AnimatedBuilder(
              animation: _logoScale,
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoScale.value,
                  child: Align(
                    alignment: Alignment.center,
                    child: Image.asset('assets/loadinglogo.png'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class Loading2 extends StatefulWidget {
  const Loading2({super.key});

  @override
  State<Loading2> createState() => _Loading2State();
}

class _Loading2State extends State<Loading2> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    fetchAllCoursesToHive().then((_) {
      setState(() {
        isLoading = false;
      });
      Timer(Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => Loading3(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: Duration(milliseconds: 600),
          ),
          //MaterialPageRoute(builder: (context) => Loading3()),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors:
              isDarkMode
                  ? [Color(0xFF422E5A), Color(0xFF1C1B33)] // dark
                  : [Color(0xFFA157C7), Color(0xFF1E1C1F)], // light
          stops: [0, 0.97],
        ),
      ),
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
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Welcome, ${UserData().id}',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        color: Color(0xFFEBEAEC),
                      ),
                    ),
                    // CUPERTINO LOADING
                    if (isLoading)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: CupertinoActivityIndicator(
                          radius: 12,
                          color: Colors.white,
                        ),
                      ),
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

class Loading3 extends StatefulWidget {
  const Loading3({super.key});

  @override
  State<Loading3> createState() => _Loading3State();
}

class _Loading3State extends State<Loading3> {
  @override
  void initState() {
    super.initState();

    fetchTakenCourseDetails(UserData().id).then((_) {
      Timer(Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => PreviewPage(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: Duration(milliseconds: 600),
          ),
          //MaterialPageRoute(builder: (context) => PreviewPage()),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors:
              isDarkMode
                  ? [Color(0xFF1C1B33), Color(0xFF422E5A)] // dark
                  : [Color(0xFF1E1C1F), Color(0xFF67387E)], // light
          stops: [0, 0.97],
        ),
      ),
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
            ],
          ),
        ),
      ),
    );
  }
}
