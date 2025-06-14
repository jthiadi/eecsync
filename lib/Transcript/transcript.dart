import 'package:flutter/material.dart';
import '../widgets/app_scaffold.dart';
import '../Data/UserData.dart';
import '../Data/GraduationRequirement.dart';
import 'package:provider/provider.dart';
import '../widgets/theme.dart';

class Transcript extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onNavItemTapped;

  const Transcript({
    super.key,
    required this.currentIndex,
    required this.onNavItemTapped,
  });

  @override
  State<Transcript> createState() => _TranscriptState();
}

class _TranscriptState extends State<Transcript> {
  int selectedSemesterIndex = 0;
  bool isScrolling = false;
  int selectedTab = 0;
  final PageController transcriptController = PageController();
  final PageController requiredController = PageController();
  int currentTranscriptPage = 0;
  int currentRequiredPage = 0;

  // Complete local data with string color identifiers
  final List<Map<String, dynamic>> semesterData =
      UserData().buildSemesterData();

  @override
  void initState() {
    super.initState();
    transcriptController.addListener(_handleTranscriptPageChange);
    requiredController.addListener(_handleRequiredPageChange);
  }

  void _handleTranscriptPageChange() {
    if (mounted) {
      setState(() {
        currentTranscriptPage = transcriptController.page?.round() ?? 0;
      });
    }
  }

  void _handleRequiredPageChange() {
    if (mounted) {
      setState(() {
        currentRequiredPage = requiredController.page?.round() ?? 0;
      });
    }
  }

  @override
  void dispose() {
    transcriptController.dispose();
    requiredController.dispose();
    super.dispose();
  }

  Color _getColorFromString(String colorStr) {
    switch (colorStr.toLowerCase()) {
      case 'redaccent':
        return Colors.redAccent;
      case 'greenaccent':
        return Colors.greenAccent;
      case 'orangeaccent':
        return Colors.orangeAccent;
      case 'grey':
      default:
        return Colors.grey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final screen = MediaQuery.of(context);
    final fontScale = screen.textScaleFactor.clamp(0.8, 1.2) * (screen.size.shortestSide / 400);

    if (semesterData.isEmpty) {
      return AppScaffold(
        currentIndex: widget.currentIndex,
        backgroundGradient: isDarkMode? LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [        Color(0xFF100729),
            Color(0xFF2B2141),
            Color(0xFF392A4F),
          ],
          stops: [0.0, 0.39, 0.74],
        ) : LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2B1735), Color(0xFF582A6D), Color(0xFF813BA1)],
          stops: [0.0, 0.39, 0.74],
        ),
        onNavItemTapped: widget.onNavItemTapped,
        showBottomNav: false,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'No semester data available.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    "Go Back",
                    style: TextStyle(
                      color: const Color.fromARGB(255, 114, 73, 124), 
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

  final currentSemester = semesterData[selectedSemesterIndex];

    final requiredStatus =
        currentSemester['courses']['requiredStatus'] as Map<String, dynamic>;

    return WillPopScope(
      onWillPop: () async => true,
      child: AppScaffold(
        currentIndex: widget.currentIndex,
        backgroundGradient: isDarkMode
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
      colors: [Color(0xFF2B1735), Color(0xFF582A6D), Color(0xFF813BA1)],
      stops: [0.0, 0.39, 0.74],
    ),

        onNavItemTapped: (index) {
          if (index != widget.currentIndex) Navigator.pop(context);
          widget.onNavItemTapped(index);
        },
        showBottomNav: false,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/panda_transcriptbg.png',
                    fit: BoxFit.cover,
                  ),
                ),
                SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: constraints.maxWidth > 600 ? 24 : 16,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 20 * fontScale,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Roboto',
                              ),
                              children: [
                                const TextSpan(
                                  text: "YOU'RE CURRENTLY ",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                TextSpan(
                                  text: currentSemester['semester'],
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 189, 147, 199),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                        // _buildSemesterWheel(constraints, fontScale),
                          semesterData.isNotEmpty
                            ? _buildSemesterWheel(constraints, fontScale)
                            : SizedBox.shrink(),
                          SizedBox(height: constraints.maxHeight * 0.03),
                          _buildTabButtons(fontScale),
                          SizedBox(height: constraints.maxHeight * 0.03),
                          SizedBox(
                            height: constraints.maxHeight * 0.6,
                            child:
                                selectedTab == 0
                                    ? _buildTranscriptContent(
                                      currentSemester['courses']['transcript']
                                          as List,
                                      fontScale,
                                      constraints.maxWidth,
                                    )
                                    : _buildRequiredCoursesContent(
                                      fontScale,
                                      requiredStatus,
                                      constraints.maxWidth,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSemesterWheel(BoxConstraints constraints, double fontScale) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 900),
      height:
          isScrolling
              ? constraints.maxHeight * 0.20
              : constraints.maxHeight * 0.15,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification) {
            setState(() => isScrolling = true);
          } else if (notification is ScrollEndNotification) {
            Future.delayed(const Duration(milliseconds: 150), () {
              if (mounted) setState(() => isScrolling = false);
            });
          }
          return true;
        },
        child: ListWheelScrollView.useDelegate(
          itemExtent: constraints.maxHeight * 0.17,
          perspective: 0.003,
          diameterRatio: 1,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (index) {
            setState(() => selectedSemesterIndex = index);
          },
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: semesterData.length,
            builder: (context, index) {
              final data = semesterData[index];
              final isSelected = index == selectedSemesterIndex;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(
                      constraints.maxWidth > 600 ? 25 : 18,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),

                      // boxShadow: isSelected && !isScrolling
                    ),
                    child: LayoutBuilder(
                      builder: (context, innerConstraints) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _gpaItem('GPA', '${data['gpa']}/4.3', fontScale),
                            _gpaItem('AVG', data['average'], fontScale),
                            _gpaItem('T-SCR', data['tscore'], fontScale),
                            _gpaItem('RNK', '${data['rank']}', fontScale),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

Widget _buildTranscriptContent(
  List transcriptData,
  double fontScale,
  double maxWidth,
) {
  if (transcriptData.isEmpty) {
    return Center(
      child: Text(
        'No transcript courses taken yet.',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 16 * fontScale,
          fontFamily: 'Roboto',
        ),
      ),
    );
  }

  return Column(
    children: [
      Expanded(
        child: PageView.builder(
          controller: transcriptController,
          itemCount: transcriptData.length,
          onPageChanged: (index) {
            setState(() {
              currentTranscriptPage = index;
            });
          },
          itemBuilder: (context, pageIndex) {
            final department = transcriptData[pageIndex] as Map<String, dynamic>;
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: maxWidth > 600 ? 16.0 : 8.0,
                vertical: 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    department['department'] as String,
                    style: TextStyle(
                      color: const Color.fromARGB(179, 199, 255, 253),
                      fontSize: 16 * fontScale,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...(department['courses'] as List).map<Widget>((course) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                        SizedBox(
                          width: maxWidth > 600 ? 120 : 100,
                          child: Text(
                            course['code'],
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15 * fontScale,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),

                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: maxWidth > 600 ? 12 : 4,
                              ),
                            child: Text(
                              course['name'],
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                                fontSize: 15 * fontScale,
                                fontFamily: 'Roboto',
                              ),
                            ),

                            ),
                          ),
                          Text(
                            course['grade'],
                            style: TextStyle(
                              color: const Color.fromARGB(255, 245, 255, 191),
                              fontWeight: FontWeight.bold,
                              fontSize: 15 * fontScale,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildPageIndicator(
          transcriptData.length,
          currentTranscriptPage,
        ),
      ),
    ],
  );
}

Widget _buildCategoryPage(Map<String, dynamic> category, double fontScale, double maxWidth) {
  return SingleChildScrollView(
    padding: EdgeInsets.symmetric(
      horizontal: maxWidth > 600 ? 16.0 : 8.0,
      vertical: 10,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  category['title'] as String,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color.fromARGB(199, 255, 255, 255),
                    fontSize: 16 * fontScale,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
              Text(
                "COMPLETED: ${category['completed']}/${category['required']}",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15 * fontScale,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildCourseListHeader(fontScale, maxWidth),
        const Divider(height: 12, color: Colors.white54, thickness: 0.8),
        ...List.generate(
          (category['courses'] as List).length,
          (index) {
            final course = category['courses'][index] as Map<String, dynamic>;
            final statusColor = _getColorFromString(course['color'] as String);
            return _buildCourseCard(course, statusColor, fontScale, maxWidth);
          },
        ),
        const SizedBox(height: 20), // space above page indicator
      ],
    ),
  );
}


  Widget _buildRequiredCoursesContent(
    double fontScale,
    Map<String, dynamic> requiredStatus,
    double maxWidth,
  ) {
    final coursesByCategory = <String, List<Map<String, dynamic>>>{};
    final Map<String, Map<String, dynamic>> bestCourseInstances = {};

    allRequiredCourses.forEach((code, course) {
      final status = requiredStatus[code] ?? 
          {'status': 'NOT TAKEN', 'grade': '', 'color': 'grey'};
      
      final courseName = course['name'] as String;
      final currentPriority = _getStatusPriority(status['status'] as String);
      
      // If we haven't seen this course name before, or if this instance has higher priority
      if (!bestCourseInstances.containsKey(courseName) || 
          currentPriority > _getStatusPriority(bestCourseInstances[courseName]!['status'] as String)) {
        bestCourseInstances[courseName] = {
          'name': courseName,
          'code': code,
          'status': status['status'],
          'grade': status['grade'],
          'color': status['color'],
          'category': course['category'],
        };
      }
    });

    // Second pass: Organize by category
    bestCourseInstances.forEach((courseName, course) {
      final category = course['category'] as String;
      if (!coursesByCategory.containsKey(category)) {
        coursesByCategory[category] = [];
      }
      coursesByCategory[category]!.add({
        'name': course['name'],
        'code': course['status'] != 'NOT TAKEN' ? course['code'] : '',
        'status': course['status'],
        'grade': course['grade'],
        'color': course['color'],
      });
    });

    final categories = coursesByCategory.entries.map((entry) {
      final completed = (entry.value)
          .where((course) => course['status'] == 'PASSED')
          .length;
      return {
        'title': entry.key,
        'required': entry.value.length,
        'completed': completed,
        'courses': entry.value,
      };
    }).toList();

  if (categories.isEmpty ||
      categories.every((cat) => (cat['courses'] as List).isEmpty)) {
    return Center(
      child: Text(
        'No required courses taken yet.',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 16 * fontScale,
          fontFamily: 'Roboto',
        ),
      ),
    );
  }

  return Column(
    children: [
      Expanded(
  child: AnimatedBuilder(
    animation: requiredController,
    builder: (context, child) {
      return PageView.builder(
        controller: requiredController,
        itemCount: categories.length,
        onPageChanged: (index) {
          setState(() {
            currentRequiredPage = index;
          });
        },
        itemBuilder: (context, pageIndex) {
          final category = categories[pageIndex];
          double pageOffset = 0;
          if (requiredController.position.haveDimensions) {
            pageOffset = pageIndex - requiredController.page!;
          }
          final blurValue = (1 - pageOffset.abs()).clamp(0.3, 1.0);
          return Opacity(
            opacity: blurValue,
            child: Transform.scale(
              scale: 0.9 + 0.1 * blurValue,
              child: _buildCategoryPage(
                category,
                fontScale,
                maxWidth,
              ),
            ),
          );
        },
      );
    },
  ),
),

      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildPageIndicator(categories.length, currentRequiredPage),
      ),
    ],
  );
}

int _getStatusPriority(String status) {
    switch (status) {
      case 'PASSED': return 3;
      case 'FAILED': return 2;
      case 'WITHDRAWED': return 1;
      case 'NOT TAKEN': return 0;
      default: return 0;
    }
  }


  Widget _buildCourseListHeader(double fontScale, double maxWidth) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Row(
        children: [
          Expanded(
            flex: maxWidth > 600 ? 5 : 4,
            child: Text(
              'COURSE NAME',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12 * fontScale,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
          ),
          Expanded(
            flex: maxWidth > 600 ? 3 : 2,
            child: Text(
              'STATUS',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12 * fontScale,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'GRADE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12 * fontScale,
                fontWeight:FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
          ),
          Expanded(
            flex: maxWidth > 600 ? 3 : 2,
            child: Text(
              'CODE',
              textAlign: TextAlign.end,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12 * fontScale,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(
    Map<String, dynamic> course,
    Color statusColor,
    double fontScale,
    double maxWidth,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(
        horizontal: maxWidth > 600 ? 16 : 12,
        vertical: maxWidth > 600 ? 12 : 10,
      ),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 67, 39, 108).withOpacity(0.3), 
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1), 
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),

      child: Row(
        children: [
          Expanded(
            flex: maxWidth > 600 ? 5 : 4,
            child: Text(
              course['name'] as String,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14 * fontScale,
                fontFamily: 'Roboto',
              ),
            ),
          ),
          Expanded(
            flex: maxWidth > 600 ? 3 : 2,
            child: Row(
              children: [
                Icon(Icons.circle, size: 8, color: statusColor),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    course['status'] as String,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 14 * fontScale,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              course['grade'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color.fromARGB(255, 251, 255, 217),
                fontSize: 15 * fontScale,
                fontFamily: 'Roboto',
              ),
            ),
          ),
          Expanded(
            flex: maxWidth > 600 ? 3 : 2,
            child: Text(
              course['code'] as String,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14 * fontScale,
                fontFamily: 'Roboto',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int count, int currentIndex) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  currentIndex == index
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
            ),
          );
        }),
      ),
    );
  }

  Widget _gpaItem(String label, String value, double fontScale) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white54,
            fontSize: 15 * fontScale,
            fontFamily: 'Roboto',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20 * fontScale,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
        ),
      ],
    );
  }

  Widget _buildTabButtons(double fontScale) {
    final titles = ['Transcript', 'Required Courses'];

    return Row(
      children: List.generate(titles.length, (index) {
        final isActive = selectedTab == index;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => selectedTab = index),
            child: Column(
              children: [
                Text(
                  titles[index],
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white54,
                    fontSize: 17 * fontScale,
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 3,
                  width: 30,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white70 : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}