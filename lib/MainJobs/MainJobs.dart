import 'package:flutter/material.dart';
import 'dart:async';
import 'job_infopage.dart';
import 'dart:ui' as ui;
import 'announcement_infopage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:marquee/marquee.dart';
import 'package:hive/hive.dart';
import '../Data/UserData.dart';
import 'package:provider/provider.dart';
import 'package:finalproject/widgets/theme.dart';

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

class MainJobs extends StatefulWidget {
  const MainJobs({super.key});

  @override
  State<MainJobs> createState() => _MainJobsState();
}

int _contentTabIndex = 0;

class _MainJobsState extends State<MainJobs> {
  int selectedTab = 0;
  bool showTabBar = true;
  double lastScrollOffset = 0;
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late Timer _timer;

  // Track which items are marked as newest
  // TODO
  Map<int, bool> newestJobs = {};
  Map<int, bool> newestAnnouncements = {};

  List<Map<String, dynamic>> jobs = [];
  List<Map<String, dynamic>> announcements = [];
  Map<String, dynamic> student = {};
  Map<String, dynamic> course = {};
  bool isLoading = true;

  List<Map<String, dynamic>> carouselItems = [];

  Future<void> fetchUserData() async {
    try {
      final box = await Hive.openBox('userBox');
      Map<String, dynamic>? storedUser = box.get('userData');

      final querySnapshot1 =
      await FirebaseFirestore.instance.collection('TA Application').get();
      final querySnapshot2 =
      await FirebaseFirestore.instance.collection('News').get();

      final docSnapshot =
      await FirebaseFirestore.instance
          .collection('Student')
          .doc(storedUser?['id'])
          .get();

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

      final List<Map<String, dynamic>> loadedAnnouncements =
      querySnapshot2.docs.map((doc) {
        return doc.data();
      }).toList();

      final Map<String, dynamic> studentData = docSnapshot.data()!;

      final newCarouselItems =
      loadedJobs.take(5).map((job) {
        return {
          'title': '${job['code'].substring(5)} ${job['position']}',
          'subtitle': '${job['title']} - ${job['professor']['EN']}',
          'course': '${job['title']}',
          'professor': '${job['professor']['EN']}',
          'color':
          Colors.primaries[loadedJobs.indexOf(job) %
              Colors.primaries.length],
          'language': '${job['lang']}',
          'timestamp':
          job['description']['last_updated']
              .toDate(), // ← Only if it's a Firestore Timestamp
          'code': job['code'],
        };
      }).toList();

      setState(() {
        jobs = loadedJobs;
        for (var i in jobs) {
          print(i['title']);
        }
        jobs =
        jobs.where((j) => j['posted'] != null).toList()..sort(
              (a, b) => (b['posted'].toDate() as DateTime).compareTo(
            a['posted'].toDate() as DateTime,
          ),
        );
        jobs.sort(
              (a, b) => (b['posted'].toDate() as DateTime).compareTo(
            a['posted'].toDate() as DateTime,
          ),
        );
        announcements = loadedAnnouncements;
        announcements =
        announcements.where((a) => a['last_updated'] != null).toList()
          ..sort(
                (a, b) => (b['last_updated'].toDate() as DateTime).compareTo(
              a['last_updated'].toDate() as DateTime,
            ),
          );
        announcements.sort(
              (a, b) => (b['last_updated'].toDate() as DateTime).compareTo(
            a['last_updated'].toDate() as DateTime,
          ),
        );
        student = studentData;
        carouselItems = newCarouselItems;
        isLoading = false;
        initNewestTags("jobs", jobs);
        initNewestTags("announcements", announcements);
      });
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        isLoading = false;
      });
    }
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

  void initNewestTags(String type, List<Map<String, dynamic>> datalist) {
    // Get current time
    final now = DateTime.now();
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    DateTime? timestamp;

    if (type == 'jobs') {
      for (int idx = 0; idx < datalist.length; idx++) {
        timestamp = datalist[idx]['posted'].toDate();
        if (timestamp != null && timestamp.isAfter(threeDaysAgo)) {
          newestJobs[idx] = true;
        } else {
          newestJobs[idx] = false;
        }
      }
    } else if (type == 'announcements') {
      for (int idx = 0; idx < datalist.length; idx++) {
        timestamp = datalist[idx]['last_updated'].toDate();
        if (timestamp != null && timestamp.isAfter(threeDaysAgo)) {
          newestAnnouncements[idx] = true;
        } else {
          newestAnnouncements[idx] = false;
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserData();
    _scrollController.addListener(_handleScroll);

    _pageController.addListener(() {
      if (_pageController.page == null) return;
      final newPage = _pageController.page!.round();
      if (newPage != _currentPage) {
        setState(() {
          _currentPage = newPage;
        });
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (!mounted || !_pageController.hasClients) return;
      if (_currentPage < carouselItems.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });

    // Initialize newest flags
    newestJobs = {};
    newestAnnouncements = {};

    carouselItems =
        jobs.take(5).map((job) {
          return {
            'title': '${job['code'].substring(5)} ${job['position']}',
            'subtitle': '${job['title']} - ${job['professor']['EN']}',
            'course': '${job['title']}',
            'professor': '${job['professor']['EN']}',
            'color':
            Colors.primaries[jobs.indexOf(job) %
                Colors.primaries.length], // cycle through default colors
            'language': '${job['lang']}',
            'timestamp': job['description']['posted'].toDate(),
            'code': job['code'],
          };
        }).toList();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _pageController.dispose();
    _timer.cancel();
    super.dispose();
  }

  void _handleScroll() {
    final offset = _scrollController.offset;

    if (offset <= 0) {
      if (!showTabBar) {
        setState(() => showTabBar = true);
      }
      lastScrollOffset = offset;
      return;
    }

    if (offset > lastScrollOffset + 10 && showTabBar) {
      setState(() => showTabBar = false);
    } else if (offset < lastScrollOffset - 10 && !showTabBar) {
      setState(() => showTabBar = true);
    }

    lastScrollOffset = offset;
  }

  String getLanguageDisplay(String? lang) {
    if (lang == 'CH') return '文';
    if (lang == 'EN') return 'E';
    if (lang == 'BOTH') return 'B';
    return lang ?? '';
  }

  Color getLanguageColor(String? lang) {
    final display = getLanguageDisplay(lang);
    if (display == 'E') return Colors.amber;
    if (display == 'B') return const Color.fromARGB(255, 165, 255, 168);
    return const Color.fromARGB(255, 188, 217, 255);
  }

  Widget _buildSmartMarqueeText(String text, TextStyle style, {double height = 20}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(text: text, style: style);
        final tp = TextPainter(
          text: span,
          maxLines: 1,
          textDirection: ui.TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        if (tp.width > constraints.maxWidth) {
          return SizedBox(
            height: height,
            child: Marquee(
              text: text,
              style: style,
              scrollAxis: Axis.horizontal,
              blankSpace: 40.0,
              velocity: 30.0,
              pauseAfterRound: const Duration(seconds: 1),
              startPadding: 0.0,
              accelerationDuration: const Duration(milliseconds: 800),
              accelerationCurve: Curves.linear,
              decelerationDuration: const Duration(milliseconds: 500),
              decelerationCurve: Curves.easeOut,
            ),
          );
        } else {
          return Text(
            text,
            style: style,
            overflow: TextOverflow.ellipsis,
          );
        }
      },
    );
  }


  Widget _buildCarouselItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSmartMarqueeText(
                            item['title'],
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 9),
                          _buildSmartMarqueeText(
                            item['subtitle'],
                            TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),

                        ],
                      ),
                    ),
                    const Column(
                      children: [
                        Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 26,
                        ),
                        SizedBox(height: 8),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromARGB(20, 237, 214, 255),
                    blurRadius: 10,
                    spreadRadius: -5,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

  Widget buildJobCard(Map<String, dynamic> job, int index) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    try {
      Color borderColor;
      final status = job['applicants']?[student['ID']]?['status'] ?? '';
      print('status:$status');
      if (status == 'P') {
        borderColor = const Color(0xFFF7B2D9);
      } else if (status == 'R') {
        borderColor = const Color.fromARGB(255, 255, 129, 129);
      } else {
        borderColor = Colors.white12;
      }

      final isNewest = newestJobs[index] ?? false;

      return GestureDetector(
        onTap: () {
          try {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => JobInfoPage(
                  fromjob: true,
                  availableJobs: jobs.isEmpty ? [] : jobs,
                  jobData: job,
                  student: student,
                ),
              ),
            );
          } catch (e) {
            print('error disini');
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isNewest)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            '${job['code'].substring(5)} ${job['position']}',
                            style: TextStyle(
                              color: MyTheme.getSettingsTextColor(isDarkMode),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${job['title']} - ${job['professor']['EN']}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 14),
                    Row(
                      children: [
                        if (status == 'P')
                          const Text(
                            '● Applied',
                            style: TextStyle(
                              color: Color(0xFFF7B2D9),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          )
                        else if (status == 'R')
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
                              addRemoveSavedJob(job['code'], student);
                            });
                          },
                          child: Icon(
                            isSavedJob(job['code'], student)
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
              const Icon(Icons.chevron_right, color: Colors.white70, size: 26),
            ],
          ),
        ),
      );
    } catch (e) {
      print('error anjay');
      return Text('tew');
    }
  }

  Widget _buildJobTabSelector() {
    final tabs = ['Main', 'Saved', 'Applied'];
    final icons = [Icons.list, Icons.star_border, Icons.check_circle_outline];

    return Container(
      height: 55,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(50),
        color: Colors.white.withOpacity(0.05),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / tabs.length;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                left: selectedTab * tabWidth,
                child: Container(
                  width: tabWidth,
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
              Row(
                children: List.generate(tabs.length, (index) {
                  final isSelected = selectedTab == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedTab = index),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icons[index],
                            color: isSelected ? Colors.white : Colors.white54,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tabs[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  Map<String, dynamic> getJob(String code) {
    final jobData = jobs.firstWhere(
          (job) => job['code'] == code,
      orElse: () => {},
    );
    return jobData;
  }

  Widget _buildMainContent() {
    final sortedJobs = List<Map<String, dynamic>>.from(jobs)
      ..sort((a, b) => b['posted'].compareTo(a['posted']));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Featured Positions',
          style: TextStyle(
            color: Color.fromARGB(248, 226, 226, 226),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: PageView.builder(
            controller: _pageController,
            itemCount: carouselItems.length,
            onPageChanged: (int index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder:
                (context, index) => GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => JobInfoPage(
                      fromjob: true,
                      availableJobs: jobs,
                      jobData: getJob(carouselItems[index]['code']),
                      student: student,
                    ),
                  ),
                );
              },
              child: _buildCarouselItem(carouselItems[index]),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            carouselItems.length,
                (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                _currentPage == index
                    ? Colors.white
                    : Colors.white.withOpacity(0.4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        Container(
          height: 40,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              _buildContentTabButton(
                text: 'Explore Positions',
                isSelected: _contentTabIndex == 0,
                onTap: () => setState(() => _contentTabIndex = 0),
              ),
              _buildContentTabButton(
                text: 'Newest Announcements',
                isSelected: _contentTabIndex == 1,
                onTap: () => setState(() => _contentTabIndex = 1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_contentTabIndex == 0) ...[
          ...sortedJobs.asMap().entries.map(
                (entry) => buildJobCard(entry.value, entry.key),
          ),
        ] else ...[
          _buildAnnouncementsContent(),
        ],
      ],
    );
  }

  Widget _buildContentTabButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Text(
                text,
                style: TextStyle(
                  color:
                  isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Container(
              height: 2,
              color: isSelected ? Colors.white : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementsContent() {
    final sortedAnnouncements = List<Map<String, dynamic>>.from(announcements)
      ..sort((a, b) => b['last_updated'].compareTo(a['last_updated']));

    return Column(
      children:
      sortedAnnouncements.asMap().entries.map((entry) {
        final index = entry.key;
        final announcement = entry.value;
        return _buildAnnouncementCard(announcement, index);
      }).toList(),
    );
  }

  bool containsUrgent(List<String> types) {
    String type;
    for (type in types) {
      if (type == "Application deadline" || type == "Maintenance") {
        return true;
      }
    }
    return false;
  }

  bool isSavedAnn(String annCode, Map<String, dynamic> student) {
    final saved = student['ANNOUNCEMENT'] ?? [];
    return saved.contains(annCode);
  }

  void addRemoveSavedAnn(String annCode, Map<String, dynamic> student) {
    if (student['ANNOUNCEMENT'].contains(annCode)) {
      student['ANNOUNCEMENT'].remove(annCode);
      removeFirebase('ANNOUNCEMENT', student['ID'], annCode);
    } else {
      student['ANNOUNCEMENT'].add(annCode);
      saveFirebase('ANNOUNCEMENT', student['ID'], annCode);
    }
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> announcement, int index) {
    final isUrgent = containsUrgent(announcement['type'].cast<String>());
    final isNewest = newestAnnouncements[index] ?? false;
    final date =
        'Last Updated ${DateFormat('dd/MM/yy').format(announcement['last_updated'].toDate())}';
    final title = announcement['english_title'] as String;
    final description = announcement['description'] as String;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => AnnouncementInfoPage(
              annData: announcement,
              student: student,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
            isUrgent
                ? const Color(0xFFFF6B6B).withOpacity(0.3)
                : Colors.white12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'URGENT',
                      style: TextStyle(
                        color: Color(0xFFFF6B6B),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isUrgent) const SizedBox(width: 8),
                if (isNewest)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isNewest) const SizedBox(width: 8),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      addRemoveSavedAnn(announcement['code'], student);
                    });
                  },
                  child: Icon(
                    isSavedAnn(announcement['code'], student)
                        ? Icons.star
                        : Icons.star_border,
                    color: const Color.fromARGB(255, 196, 221, 255),
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isNewest)
                  Container(
                    width: 4,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedContent() {
    final List<dynamic> savedJobCodes = student['JOB']?['SAVED'] ?? [];
    final List<dynamic> savedAnnCodes = student['ANNOUNCEMENT'] ?? [];

    final savedJobs =
    jobs.where((job) => savedJobCodes.contains(job['code'])).toList();
    final savedAnnouncements =
    announcements
        .where(
          (announcement) => savedAnnCodes.contains(announcement['code']),
    )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Saved Items',
          style: TextStyle(
            color: Color.fromARGB(248, 226, 226, 226),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        if (savedJobs.isNotEmpty) ...[
          const Text(
            'Saved Positions',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...savedJobs.asMap().entries.map(
                (entry) => buildJobCard(entry.value, entry.key),
          ),
          const SizedBox(height: 16),
        ],

        if (savedAnnouncements.isNotEmpty) ...[
          const Text(
            'Saved Announcements',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...savedAnnouncements.asMap().entries.map(
                (entry) => _buildAnnouncementCard(entry.value, entry.key),
          ),
        ],

        if (savedJobs.isEmpty && savedAnnouncements.isEmpty)
          const Center(
            child: Text(
              'No saved items yet',
              style: TextStyle(color: Colors.white70),
            ),
          ),
      ],
    );
  }

  Widget _buildAppliedContent() {
    final appliedJobs =
    jobs
        .where((job) => job['applicants']?[student['ID']]?['status'] == 'P')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Applied Positions',
          style: TextStyle(
            color: Color.fromARGB(249, 195, 195, 195),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (appliedJobs.isEmpty)
          const Center(
            child: Text(
              'No applied positions yet',
              style: TextStyle(color: Colors.white70),
            ),
          )
        else
          ...appliedJobs.asMap().entries.map(
                (entry) => buildJobCard(entry.value, entry.key),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/images/flowerbg.png',
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 300),
                  crossFadeState:
                  showTabBar
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildJobTabSelector(),
                      const SizedBox(height: 26),
                    ],
                  ),
                  secondChild: const SizedBox.shrink(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: [
                        if (selectedTab == 0) _buildMainContent(),
                        if (selectedTab == 1) _buildSavedContent(),
                        if (selectedTab == 2) _buildAppliedContent(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
