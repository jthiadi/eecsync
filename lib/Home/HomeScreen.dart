import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'professor_info.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Data/UserData.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../MainJobs/announcement_infopage.dart';
import 'package:provider/provider.dart';
import '../widgets/theme.dart';
import 'package:marquee/marquee.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // for the news slider and main scroll
  final ScrollController _newsScrollController = ScrollController();
  final ScrollController _mainScrollController = ScrollController();
  Map<int, double> gpa = UserData().getGPApersemester();

  // Sample news data W favorite status
  List<Map<String, dynamic>> newsItems = [];
  Map<String, dynamic> student = {};
  bool isLoading = true;

  List<Map<String, dynamic>> professors = [];

  Future<void> fetchUserData() async {
    try {
      final querySnapshot1 =
      await FirebaseFirestore.instance.collection('News').get();

      final List<Map<String, dynamic>> loadedAnnouncements =
      querySnapshot1.docs.map((doc) {
        return doc.data();
      }).toList();

      final box = await Hive.openBox('userBox');
      Map<String, dynamic>? storedUser = box.get('userData');

      final docSnapshot =
      await FirebaseFirestore.instance
          .collection('Student')
          .doc(storedUser?['id'])
          .get();

      final Map<String, dynamic> studentData = docSnapshot.data()!;

      final querySnapshot2 =
      await FirebaseFirestore.instance.collection('Professor').get();

      final List<Map<String, dynamic>> loadedProfs =
      querySnapshot2.docs.map((doc) {
        return doc.data();
      }).toList();

      setState(() {
        isLoading = false;
        newsItems = loadedAnnouncements;
        newsItems.sort(
              (a, b) => (b['last_updated'].toDate() as DateTime).compareTo(
            a['last_updated'].toDate() as DateTime,
          ),
        );
        professors = (loadedProfs..shuffle()).take(5).toList();
        newsItems = newsItems.take(8).toList();
        student = studentData;
      });
    } catch (e) {
      //print("Error fetching user data: $e");
      setState(() {
        isLoading = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  @override
  void dispose() {
    _newsScrollController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  Future<void> saveFirebase(String studentID, String code) async {
    final docRef = FirebaseFirestore.instance
        .collection('Student')
        .doc(studentID);

    await docRef.update({
      'ANNOUNCEMENT': FieldValue.arrayUnion([code]),
    });
  }

  Future<void> removeFirebase(String studentID, String code) async {
    final docRef = FirebaseFirestore.instance
        .collection('Student')
        .doc(studentID);

    await docRef.update({
      'ANNOUNCEMENT': FieldValue.arrayRemove([code]),
    });
  }

  bool isSavedAnn(String annCode, Map<String, dynamic> student) {
    final saved = student['ANNOUNCEMENT'] ?? [];
    return saved.contains(annCode);
  }

  // to toggle favorite status
  void _toggleFavorite(String annCode, Map<String, dynamic> student) {
    if (student['ANNOUNCEMENT'].contains(annCode)) {
      student['ANNOUNCEMENT'].remove(annCode);
      removeFirebase(student['ID'], annCode);
    } else {
      student['ANNOUNCEMENT'].add(annCode);
      saveFirebase(student['ID'], annCode);
    }
  }

  // to navigate to news detail page
  void _navigateToNewsDetail(BuildContext context, Map<String, dynamic> news) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Navigating to ${news['english_title']}'s details..."),
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AnnouncementInfoPage(
          annData: news,
          student: student,
          onFavoriteChanged: () => setState(() {}),
        ),
      ),
    );
  }

  void _showProfessorInfo(
      BuildContext context,
      Map<String, dynamic> professor,
      RenderBox box,
      ) {
    // global position of the professor circle
    final RenderBox? renderBox = box;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showProfessorProfile(
      context,
      name: professor['name']['CH'],
      englishName: professor['name']['EN'],
      labName: professor['title_lab'],
      imgurl: professor['imgurl'],
      weburl: professor['website'],
      scopeItems: List<String>.from(professor['scope_lab']),
      startPosition: position,
      size: size,
    );
  }

  //navigate to favorites page
  void _navigateToFavorites(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Navigating to Favorites page...')));
    // will be added later
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => FavoritesScreen()),
    // );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: Column(
        children: [
          // Weekly Progress Chart 
          Padding(
            padding: EdgeInsets.all(16.0),
            child: _buildWeeklyProgressSection(isDarkMode),
          ),

          // White curved background container
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: MyTheme.getSettingsTextColor(isDarkMode),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  // Fixed News and Updates Header
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: 'NEWS ',
                                style: TextStyle(color: Color(0xFF92A0A1)),
                              ),
                              TextSpan(
                                text: 'AND ',
                                style: TextStyle(color: Color(0xFF9692A1)),
                              ),
                              TextSpan(
                                text: 'UPDATES',
                                style: TextStyle(color: Color(0xFF92A0A1)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // news boxes and everything else
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _mainScrollController,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // News slider 
                            _buildNewsSlider(isDarkMode),
                            SizedBox(height: 24),

                            _buildScrollableContent(isDarkMode),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // builds only the news slider part (without the header)
  Widget _buildNewsSlider(bool isDarkMode) {
    return Container(
      height: 210,
      child: RawScrollbar(
        controller: _newsScrollController,
        thumbVisibility: true,
        //trackVisibility: true,
        thickness: 9, 
        radius: Radius.circular(10), 
        thumbColor: Colors.purple.withAlpha(100),
        //trackColor: Colors.grey.withOpacity(0.2),
        interactive: true,
        minThumbLength: 50,
        mainAxisMargin: 0,
        crossAxisMargin: -5,
        child: ListView.separated(
          controller: _newsScrollController,
          padding: const EdgeInsets.all(10),
          scrollDirection: Axis.horizontal,
          itemCount: newsItems.length,
          separatorBuilder: (context, index) => const SizedBox(width: 4),
          itemBuilder: (context, index) {
            final newsItem = newsItems[index];
            return _buildNewsCard(newsItem, isDarkMode);
          },
        ),
      ),
    );
  }

  Widget _buildWeeklyProgressSection(bool isDarkMode) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        // Determine how many week numbers we can fit based on available width
        double weekTextWidth = 40; 
        double weekNumberWidth =
        20; // Width for each week number including margin
        double availableWidth =
            screenWidth - 32 - weekTextWidth; // 32 is from the padding

        // Calculate how many week numbers we can show based on available width
        int maxWeeksToShow = (availableWidth / weekNumberWidth).floor();
        maxWeeksToShow = maxWeeksToShow.clamp(
          7,
          14,
        ); // Show at least 7, at most 14

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Week indicators at top 
            Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'WEEK',
                      style: TextStyle(
                        color: Color(0xFFFFE5FD),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 12),
                    ...List.generate(maxWeeksToShow, (index) {
                      // Current week
                      final DateTime semesterStart = DateTime(2025, 3, 05);
                      final DateTime today = DateTime.now();

                      final int currentWeek = ((today.difference(semesterStart).inDays) / 7).floor() + 1;
                      final bool isCurrentWeek = index + 1 == currentWeek;

                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        child:
                        isCurrentWeek
                            ? // Current week with circular background
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.fromARGB(
                              120,
                              128,
                              100,
                              200,
                            ), 
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                            : 
                        Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Color(0xFFFFE5FD),
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            Container(
              height: 180,
              width: double.infinity, 
              child: Stack(
                alignment: Alignment.center, 
                children: [
                  LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        // Target 
                        LineChartBarData(
                          spots: [
                            FlSpot(0, 4.3),
                            FlSpot(1, 2.2),
                            FlSpot(2, 4.3),
                            FlSpot(3, 3.8),
                            FlSpot(4, 2.2),
                            FlSpot(5, 3.8),
                            FlSpot(6, 3.2),
                            FlSpot(7, 4.3),
                          ],
                          isCurved: true,
                          color: isDarkMode? Color(0xFFB6CB7B) : Color(0xFFD3FFD7), // Light green
                          barWidth: 5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 0,
                                color: isDarkMode? Color(0xFFB6CB7B) : Color(0xFFD3FFD7),
                                strokeWidth: 0,
                                strokeColor: isDarkMode? Color(0xFFB6CB7B) : Color(0xFFD3FFD7),
                              );
                            },
                          ),
                          dashArray: [18, 20],
                          shadow: Shadow(
                            blurRadius: 10,
                            color: isDarkMode? Color(0xFFB6CB7B) : Color(0xFFD3FFD7),
                            offset: Offset(0, 4),
                          ),
                        ),
                        // Actual line 
                        LineChartBarData(
                          spots: [
                            FlSpot(
                              0,
                              UserData().semester - 1 >= 1
                                  ? gpa[1] ?? 2.2
                                  : 2.2,
                            ),
                            FlSpot(
                              1,
                              UserData().semester - 1 >= 2
                                  ? gpa[2] ?? 2.2
                                  : 2.2,
                            ),
                            FlSpot(
                              2,
                              UserData().semester - 1 >= 3
                                  ? gpa[3] ?? 2.2
                                  : 2.2,
                            ), // SEM point
                            FlSpot(
                              3,
                              UserData().semester - 1 >= 4
                                  ? gpa[4] ?? 2.2
                                  : 2.2,
                            ),
                            FlSpot(
                              4,
                              UserData().semester - 1 >= 5
                                  ? gpa[5] ?? 2.2
                                  : 2.2,
                            ),
                            FlSpot(
                              5,
                              UserData().semester - 1 >= 6
                                  ? gpa[6] ?? 2.2
                                  : 2.2,
                            ),
                            FlSpot(
                              6,
                              UserData().semester - 1 >= 7
                                  ? gpa[7] ?? 2.2
                                  : 2.2,
                            ),
                            FlSpot(
                              7,
                              UserData().semester - 1 >= 8
                                  ? gpa[8] ?? 2.2
                                  : 2.2,
                            ),
                          ],
                          isCurved: true,
                          color: isDarkMode? Color(0xFF9A93BE): Color(0xFF949BFF), 
                          barWidth: 5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 5,
                                color: isDarkMode? Color(0xFF9A93BE): Color(0xFF949BFF),
                                strokeWidth: 1.5,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          shadow: Shadow(
                            blurRadius: 12,
                            color: isDarkMode? Color(0xFF9A93BE): Color(0xFF949BFF),
                            offset: Offset(0, 4),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: Color(0xFF2A1C48),
                          tooltipRoundedRadius: 8,
                          tooltipPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                            return touchedBarSpots.map((barSpot) {
                              // tooltip for the actual line 
                              if (barSpot.barIndex == 1) {
                                // Actual line
                                final semesterNumber = barSpot.x.toInt() + 1;
                                final actualGpa = barSpot.y.toStringAsFixed(2);

                                // find the target GPA from the same x position in the other line
                                String targetGpa = "--";
                                for (var spot in touchedBarSpots) {
                                  if (spot.barIndex == 0 &&
                                      spot.x == barSpot.x) {
                                    targetGpa = spot.y.toStringAsFixed(2);
                                    break;
                                  }
                                }

                                return LineTooltipItem(
                                  'Semester $semesterNumber\nActual GPA: ${UserData().semester - 1 >= semesterNumber ? actualGpa : 'N/A'}\nTarget GPA: $targetGpa',
                                  TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                );
                              }
                              return null; 
                            }).toList(); 
                          },
                        ),
                        handleBuiltInTouches: true,
                      ),
                      minX: -2,
                      maxX: 10,
                      minY: 0,
                      maxY: 6,
                    ),
                  ),
                  // Legend 
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 20,
                              height: 3,
                              color: isDarkMode? Color(0xFF9A93BE): Color(0xFF949BFF), 
                              margin: EdgeInsets.only(right: 6),
                            ),
                            Text(
                              'ACTUAL',
                              style: GoogleFonts.poppins(
                                color: Color(0xFFFFE5FD).withAlpha(85),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 20,
                              height: 3,
                              color: isDarkMode? Color(0xFFB6CB7B) : Color(0xFFD3FFD7), 
                              margin: EdgeInsets.only(right: 6),
                            ),
                            Text(
                              'TARGET',
                              style: GoogleFonts.poppins(
                                color: Color(0xFFFFE5FD).withAlpha(85),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // University and Department Information
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(top: 0.0),
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NATIONAL TSING HUA UNIVERSITY',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.withAlpha(125),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'DEPARTMENT OF ELECTRICAL ENGINEERING & COMPUTER SCIENCE',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.withAlpha(85),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> newsItem, bool isDarkMode) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    String locationText = newsItem['location'];
    final isValidLocation = locationText != null && locationText.trim().isNotEmpty && locationText != '-';
    final isLongLocation = locationText.length > 20 ? true : false;
    if (isLongLocation) locationText = "$locationText      ";

    return GestureDetector(
      onTap: () => _navigateToNewsDetail(context, newsItem),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        color: MyTheme.getSettingsTextColor(isDarkMode), 
        child: Container(
          width: 200,
          // fixed height for the entire card to ensure proper sizing
          height: 190, 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  // Image placeholder 
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.network(
                      newsItem['imgurl'],
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        height: 100,
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey[500],
                            size: 40,
                          ),
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 100,
                          color: Colors.grey[300],
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                    ),
                  ),
                  // Bookmark button 
                  Positioned(
                    right: 10,
                    top: 10,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _toggleFavorite(newsItem['code'], student);
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                      ),
                    ),
                  ),
                ],
              ),
              // Title bar 
              SizedBox(height: 15),
              // Location row 
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ), 
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: Colors.grey[500],
                      size: 20,
                    ),
                    SizedBox(width: 4),
                    Expanded(
                        child: SizedBox(
                          height: 20,
                          child: isValidLocation
                              ? (isLongLocation
                              ? Marquee(
                            text: locationText,
                            velocity: 10.0,
                            numberOfRounds: 2,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF737373),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                              : Text(
                            locationText,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF737373),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ))
                              : Text(
                            "N/A",
                            style: GoogleFonts.poppins(
                              color: const Color.fromARGB(255, 255, 58, 58),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      // Text(
                      //   "${newsItem['location']}" ?? "-",
                      //   style: GoogleFonts.poppins(
                      //     color: Color(0xFF373737),
                      //     fontSize: 12,
                      //     fontWeight: FontWeight.w600,
                      //   ),
                      // )
                    ),
                  ],
                ),
              ),
              // News title 
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: SizedBox(
                  height: 20, 
                  child: Marquee(
                    text: "${newsItem['english_title']}      ",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF737373),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    velocity: 15.0,
                  ),
                ),

                // Text(
                //   newsItem['english_title'],
                //   style: GoogleFonts.poppins(
                //     color: Color(0xFF373737),
                //     fontSize: 12,
                //     fontWeight: FontWeight.w600,
                //   ),
                //   maxLines: 1,
                //   overflow: TextOverflow.ellipsis,
                // ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableContent(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            children: [
              TextSpan(
                text: 'DISTINGUISHED ',
                style: TextStyle(color: Color(0xFF92A0A1)),
              ),
              TextSpan(
                text: 'PROFESSORS ',
                style: TextStyle(color: Color(0xFF9692A1)),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
            professors.map((professor) {
              // key for each professor to access its render box
              final GlobalKey professorKey = GlobalKey();

              return GestureDetector(
                onTap: () {
                  // render box of the tapped professor circle
                  final RenderBox? box =
                  professorKey.currentContext?.findRenderObject()
                  as RenderBox?;
                  _showProfessorInfo(context, professor, box!);
                },
                child: Container(
                  key: professorKey, // key to the container
                  margin: EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      // for animation
                      Hero(
                        tag: "professor_${professor['name']['CH']}",
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.blue, Colors.purple],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: SizedBox(
                            width: 60,
                            height: 60,
                            child: ClipOval(
                              child: Image.network(
                                professor['imgurl'],
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        professor['name']['CH'],
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        professor['name']['EN'],
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}