import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:marquee/marquee.dart';
import '../widgets/nthu_background.dart';
import 'get_ai_search.dart';
import 'get_ai_answer.dart';
import '../Data/course_rec_data.dart';
import 'getsearchrecom.dart';
import 'dart:async';
import 'dart:convert';
import '../Recommendation/course_info.dart';
import '../Data/CourseData.dart';
import '../Home/professor_info.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../MainJobs/job_infopage.dart';
import '../MainJobs/MainJobs.dart';
import '../Data/UserData.dart';
import '../Settings/search_history_provider.dart';
import 'package:provider/provider.dart';
import 'package:finalproject/widgets/theme.dart';

class SearchPage extends StatefulWidget {
  final int currentIndex;
  final LinearGradient backgroundGradient;
  final ValueChanged<int> onNavItemTapped;

  const SearchPage({
    Key? key,
    required this.currentIndex,
    required this.backgroundGradient,
    required this.onNavItemTapped,
  }) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  // ─────────────────────────  STATE  ─────────────────────────
  bool isSyncSelected = false;
  bool isJobTypeSelected = false;
  bool displayans = false;
  bool loading = false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  late final AnimationController _bgController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  )..repeat(reverse: true);
  late final AnimationController _rainbowController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  String searchQuery = '';
  String? activeSuggestion;

  final List<String> recentSearches = [
    "software studio course",
    "data structure test",
    "teaching assistant",
  ];

  List<String> suggestions = [];

  // final List<String> aiSuggestions = [
  //   "Probability of passing OS",
  //   "Trending Jobs",
  //   "Most seen course now",
  //   "Newest announcements",
  // ];

  String aianswer = '';

  List<String> normalsuggestions = [];
  List<String> AIsuggestions = [];

  Future<void> _loadInitialSuggestions() async {
    final normalSuggest = await getNormalRecommendations('', 'CJP');
    final aiSuggest = await getSearchRecommendations('');
    final jobsuggestion = await getNormalRecommendations('', 'J');

    setState(() {
      normalsuggestions = normalSuggest;
      AIsuggestions = aiSuggest;
      suggestions = jobsuggestion;
    });
  }

  void _onSearchChanged(String query) async {
    if (displayans) displayans = false;
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      AIsuggestions = await getSearchRecommendations(query);
    });
  }

  void _onNormalSearchChanged(String query, String cat) async {
    if (displayans) displayans = false;
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      var temp = await getNormalRecommendations(query, cat);
      setState(() {
        normalsuggestions = temp;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _loadInitialSuggestions();
  }

  // ─────────────────────────  LIFECYCLE  ─────────────────────────
  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _bgController.dispose();
    _rainbowController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ─────────────────────────  UI  ─────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    final isMobile = size.width < 600;
    final searchHistory = Provider.of<SearchHistoryProvider>(context).history;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgController,
            builder:
                (_, __) => Container(
                  width: size.width,
                  height: size.height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.12, 1],
                      colors:
                          isDarkMode
                              ? [
                                Color.lerp(
                                  const Color(0xFF392A4F),
                                  const Color(0xFF100729),
                                  _bgController.value,
                                )!.withOpacity(1),
                                Color.lerp(
                                  const Color(0xFF392A4F),
                                  const Color(0xFF100729),
                                  _bgController.value,
                                )!.withOpacity(1),
                              ]
                              : [
                                Color.lerp(
                                  const Color(0xFFAA51D3),
                                  const Color(0xFF582A6D),
                                  _bgController.value,
                                )!.withOpacity(1),
                                Color.lerp(
                                  const Color(0xFF582A6D),
                                  const Color(0xFFAA51D3),
                                  _bgController.value,
                                )!.withOpacity(1),
                              ],
                    ),
                  ),
                ),
          ),

          Column(
            children: [
              // ─────────────────────────  HEADER  ─────────────────────────
              Container(
                width: size.width,
                padding: EdgeInsets.fromLTRB(
                  size.width * 0.05,
                  topPadding + size.height * 0.015,
                  size.width * 0.05,
                  size.height * 0.03,
                ),
                decoration: BoxDecoration(
                  color: MyTheme.getSettingsTextColor(isDarkMode),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 30),
                      color: Colors.grey[700],
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 3,
                            height: 33,
                            margin: const EdgeInsets.only(right: 8, top: 4),
                            decoration: BoxDecoration(
                              color:
                                  _focusNode.hasFocus
                                      ? isDarkMode
                                          ? Color(0xFF582A6D)
                                          : const Color(0xFFAA51D3)
                                      : Colors.grey[400],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _controller,
                                    focusNode: _focusNode,
                                    textAlignVertical: TextAlignVertical.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: isMobile ? 18 : 22,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                    decoration: InputDecoration(
                                      hintText:
                                          _focusNode.hasFocus
                                              ? ''
                                              : isJobTypeSelected
                                              ? 'Search Jobs Here'
                                              : isSyncSelected
                                              ? 'Ask Sync AI Questions Here'
                                              : 'Search Your Questions Here',
                                      hintStyle: GoogleFonts.poppins(
                                        color: Colors.grey[400],
                                        fontSize: isMobile ? 18 : 22,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    cursorColor:
                                        isDarkMode
                                            ? Color(0xFF582A6D)
                                            : const Color(0xFFAA51D3),
                                    onChanged: (value) {
                                      setState(() {
                                        searchQuery = value.trim();
                                        if (activeSuggestion != null &&
                                            activeSuggestion != value.trim()) {
                                          activeSuggestion = null;
                                        }
                                        if (isSyncSelected) {
                                          _onSearchChanged(searchQuery);
                                        }
                                        if (!isSyncSelected &&
                                            !isJobTypeSelected) {
                                          _onNormalSearchChanged(
                                            searchQuery,
                                            "CPJ",
                                          );
                                        }
                                        if (isJobTypeSelected &&
                                            !isSyncSelected) {
                                          _onNormalSearchChanged(
                                            searchQuery,
                                            "J",
                                          );
                                        }
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isSyncSelected || isJobTypeSelected)
                                  IconButton(
                                    onPressed: _performSearch,
                                    icon: Icon(
                                      Icons.search,
                                      color:
                                          isDarkMode
                                              ? Color(0xFF582A6D)
                                              : const Color(0xFFAA51D3),
                                      size: 25,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Row(
                        children: [
                          _buildButton(
                            icon: Icons.work_outline,
                            text: 'JOB TYPE',
                            selected: isJobTypeSelected,
                            onTap: () {
                              setState(() {
                                isJobTypeSelected = !isJobTypeSelected;
                                if (isJobTypeSelected) isSyncSelected = false;
                              });
                            },
                          ),
                          const SizedBox(width: 15),
                          _buildButton(
                            icon: Icons.bolt_outlined,
                            text: 'SYNC AI',
                            selected: isSyncSelected,
                            onTap: () {
                              setState(() {
                                isSyncSelected = !isSyncSelected;
                                if (isSyncSelected) isJobTypeSelected = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // ─────────────────────────  BODY  ─────────────────────────
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder:
                      (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.05),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                  child:
                      isJobTypeSelected
                          ? _buildJobBody(
                            searchHistory: searchHistory,
                            key: const ValueKey('job'),
                          )
                          : isSyncSelected
                          ? _buildSyncAI(key: const ValueKey('sync'))
                          : _buildDefaultBody(
                            searchQuery: searchQuery,
                            key: const ValueKey('default'),
                          ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────  SEARCH ACTION  ─────────────────────────
  void _performSearch() async {
    final query = searchQuery.trim();
    if (query.isEmpty) return;

    if (isSyncSelected) {
      setState(() {
        loading = true;
      });

      try {
        final alljobs = await getalljobs();
        print('all jobs:$alljobs');
        final aiResponse = await getaianswer(
          buildGraduationSummary(),
          semua,
          takenCoursess,
          alljobs,
          query,
        );
        print('AI response: $aiResponse');
        aianswer = aiResponse.toString().trim();
        setState(() {
          loading = false;
          displayans = true;
        });
      } catch (e) {
        print('AI Error: $e');
      }
    }
    context.read<SearchHistoryProvider>().addToHistory(query);
    // Optionally close keyboard
    FocusScope.of(context).unfocus();
  }

  // ─────────────────────────  CONTENT  ─────────────────────────
  Widget _buildSyncAI({Key? key}) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(17.3, 3, 25, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ask any questions, AI Assist will help you ✧",
            style: GoogleFonts.poppins(
              color: MyTheme.getSettingsTextColor(isDarkMode),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          loading
              ? Center(
                key: const ValueKey('loading'),
                child: CircularProgressIndicator(
                  color: MyTheme.getSettingsTextColor(isDarkMode),
                ),
              )
              : !displayans
              ? Wrap(
                spacing: 12,
                runSpacing: 20,
                children:
                    AIsuggestions.map((text) {
                      final isActive = activeSuggestion == text;
                      return GestureDetector(
                        onTap: () => _setSearchFromSuggestion(text),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 1,
                            end: isActive ? 1.05 : 1.0,
                          ),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          builder:
                              (context, scale, child) =>
                                  Transform.scale(scale: scale, child: child),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: Colors.white.withOpacity(0.08),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromARGB(
                                    255,
                                    225,
                                    180,
                                    222,
                                  ).withOpacity(0.15),
                                  blurRadius: 6,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              text,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: MyTheme.getSettingsTextColor(isDarkMode),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              )
              : GestureDetector(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 1, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  builder:
                      (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.white.withOpacity(0.08),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(
                            255,
                            225,
                            180,
                            222,
                          ).withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(
                      maxHeight: 500,
                    ), // Add max height constraint
                    child: SingleChildScrollView(
                      // Make content scrollable
                      child: Text(
                        aianswer,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: MyTheme.getSettingsTextColor(isDarkMode),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  // shows recents & suggestions list + result/no-result banner
  Widget _buildJobBody({required List<String> searchHistory, Key? key}) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    final lower = searchQuery.toLowerCase();
    final hasQuery = searchQuery.isNotEmpty;
    final bool noMatch =
        hasQuery && !searchHistory.any((e) => e.toLowerCase().contains(lower));
    //!suggestions.any((e) => e.toLowerCase().contains(lower));

    if (hasQuery) {
      return _buildQueryBanner(noMatch, key: key);
    }

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recents",
                style: GoogleFonts.poppins(
                  color: MyTheme.getSettingsTextColor(isDarkMode),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap:
                    () =>
                        Provider.of<SearchHistoryProvider>(
                          context,
                          listen: false,
                        ).clearHistory(),
                child: Text(
                  "Clear",
                  style: GoogleFonts.poppins(
                    color: MyTheme.getSettingsTextColor(isDarkMode),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...searchHistory.map(
            (item) => GestureDetector(
              onTap: () => _setSearchFromSuggestion(item),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 18,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OverflowAwareText(
                        text: item,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),
          Text(
            "Try Searching",
            style: GoogleFonts.poppins(
              color: MyTheme.getSettingsTextColor(isDarkMode),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ...suggestions.map((item) {
            final fullText = getFromSecondWord(item);
            final index = fullText.indexOf('11320');
            final displayText =
                (index != -1 && index >= 2)
                    ? '${fullText.substring(0, index - 2)} TA ${fullText.substring(index - 1)}'
                    : fullText;

            return GestureDetector(
              onTap: () => _setSearchFromSuggestion(displayText),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 18, color: Colors.white70),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OverflowAwareText(
                        text: displayText,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // default/unfiltered body: only banner when there is a query
  Widget _buildDefaultBody({required String searchQuery, Key? key}) {
    if (searchQuery.isEmpty) {
      return Center(key: key, child: const NthuBackground());
    }

    // when user typed something but didn’t pick a filter → banner logic
    final lower = searchQuery.toLowerCase();
    final searchHistory = Provider.of<SearchHistoryProvider>(context).history;
    final noMatch = !searchHistory.any((e) => e.toLowerCase().contains(lower));
    return _buildQueryBanner(noMatch, key: key);
  }

  // banner helper
  // Replace your _buildQueryBanner method with this:
  Widget _buildQueryBanner(bool noMatch, {Key? key}) =>
      normalsuggestions.isEmpty
          ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'No search results found for "$searchQuery"',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color.fromARGB(179, 198, 198, 198),
              ),
            ),
          )
          : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                normalsuggestions.map((text) {
                  final isActive = activeSuggestion == text;
                  return GestureDetector(
                    onTap: () async {
                      if (text[0] == 'C') {
                        context.read<SearchHistoryProvider>().addToHistory(
                          getFromSecondWord(text),
                        );
                        final courseBox = await Hive.openBox<CourseData>(
                          'all_courses',
                        );
                        final courseCode = extractCourseCode(text);
                        final course = courseBox.values.firstWhere(
                          (course) =>
                              courseCode.replaceAll(RegExp(r'\s+'), ' ') ==
                              course.id,
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) => CourseDetailPage(
                                  courseCode: course.id,
                                  courseName: course.name,
                                  professor: course.professor,
                                  credits: course.credit,
                                  department: course.id.split(' ')[0],
                                  syllabus: course.syllabus,
                                  grading: course.grading,
                                  location: course.location,
                                  time: course.classTime ?? '',
                                ),
                          ),
                        );
                      } else if (text[0] == 'P') {
                        context.read<SearchHistoryProvider>().addToHistory(
                          getFromSecondWord(text),
                        );
                        final querySnapshot =
                            await FirebaseFirestore.instance
                                .collection('Professor')
                                .where(
                                  'name.EN',
                                  isEqualTo: getFromSecondWord(text),
                                )
                                .get();
                        final professor = querySnapshot.docs[0];
                        showProfessorProfile(
                          context,
                          name: professor['name']['CH'],
                          englishName: professor['name']['EN'],
                          labName: professor['title_lab'],
                          scopeItems: List<String>.from(professor['scope_lab']),
                          imgurl: professor['imgurl'],
                          weburl: professor['website'],
                          startPosition: Offset(0, -2000),
                          size: Size(100, 100),
                        );
                      } else if (text[0] == 'J') {
                        Provider.of<SearchHistoryProvider>(
                          context,
                          listen: false,
                        ).addToHistory(
                          '${getFromSecondWord(text).substring(0, getFromSecondWord(text).indexOf('11320') - 2)} TA ${getFromSecondWord(text).substring(getFromSecondWord(text).indexOf('11320') - 1)}',
                        );
                        final box = await Hive.openBox('userBox');
                        Map<String, dynamic>? storedUser = box.get('userData');
                        final querySnapshot1 =
                            await FirebaseFirestore.instance
                                .collection('TA Application')
                                .get();
                        final docSnapshot =
                            await FirebaseFirestore.instance
                                .collection('Student')
                                .doc(storedUser?['id'])
                                .get();

                        final loadedJobs =
                            querySnapshot1.docs.map((doc) {
                              return doc.data();
                            }).toList();

                        final Map<String, dynamic> studentData =
                            docSnapshot.data()!;
                        final String courseCode = extractCourseCode(text);
                        final Map<String, dynamic>? job = loadedJobs.firstWhere(
                          (job) => job['code'] == courseCode,
                        );

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) => JobInfoPage(
                                  fromjob: false,
                                  availableJobs: loadedJobs,
                                  jobData: job,
                                  student: studentData,
                                ),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        6,
                        16,
                        6,
                      ), // spacing between items
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ), // inner spacing
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(
                            255,
                            225,
                            180,
                            222,
                          ).withOpacity(0.15), // light translucent card feel
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFB388EB,
                              ).withOpacity(0.3), // soft purple glow
                              blurRadius: 12,
                              spreadRadius: 2,
                              offset: const Offset(
                                0,
                                0,
                              ), // glow around all sides
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                text[0] == 'J'
                                    ? '${getFromSecondWord(text).substring(0, getFromSecondWord(text).indexOf('11320') - 2)} TA ${getFromSecondWord(text).substring(getFromSecondWord(text).indexOf('11320') - 1)}'
                                    : getFromSecondWord(text),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
          );

  // ─────────────────────────  HELPERS  ─────────────────────────
  void _setSearchFromSuggestion(String text) {
    setState(() {
      searchQuery = text;
      activeSuggestion = text;
      _controller.text = text;
      _controller.selection = TextSelection.collapsed(offset: text.length);
      _focusNode.requestFocus();
      _onNormalSearchChanged(searchQuery, 'J');
    });
  }

  Widget _buildButton({
    required IconData icon,
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isSyncAI = text.toUpperCase().contains('SYNC');
        final isJobType = text.toUpperCase().contains('JOB');
        final isDisabled =
            (isSyncAI && isJobTypeSelected) || (isJobType && isSyncSelected);

        return GestureDetector(
          onTap: isDisabled ? null : onTap,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 1, end: selected ? 1.05 : 1),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            builder:
                (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
            child: Container(
              width: 101,
              height: 42,
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isSyncAI && selected)
                    AnimatedBuilder(
                      animation: _rainbowController,
                      builder:
                          (context, _) => Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                width: 3,
                                color: Colors.transparent,
                              ),
                            ),
                            child: ShaderMask(
                              shaderCallback:
                                  (bounds) => SweepGradient(
                                    center: Alignment.center,
                                    startAngle: 0,
                                    endAngle: 6.283,
                                    transform: GradientRotation(
                                      _rainbowController.value * 6.283,
                                    ),
                                    colors: const [
                                      Color(0xFFFFBEBB),
                                      Color(0xFFFFE3BA),
                                      Colors.yellow,
                                      Color(0xFFB7FFB9),
                                      Color(0xFFBAE0FF),
                                      Color(0xFFB3BEFF),
                                      Color(0xFFF9B9FF),
                                      Color(0xFFFFC8C4),
                                    ],
                                  ).createShader(bounds),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    width: 3,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          selected
                              ? themeProvider.isDarkMode
                                  ? const Color(0xFF582A6D)
                                  : const Color(0xFFAA51D3)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(
                        color:
                            isDisabled
                                ? Colors.grey
                                : themeProvider.isDarkMode
                                ? const Color(0xFF582A6D)
                                : const Color(0xFFAA51D3),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 14,
                          color:
                              isDisabled
                                  ? Colors.grey
                                  : (selected
                                      ? Colors.white
                                      : themeProvider.isDarkMode
                                      ? const Color(0xFF582A6D)
                                      : const Color(0xFFAA51D3)),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          text,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color:
                                isDisabled
                                    ? Colors.grey
                                    : (selected
                                        ? Colors.white
                                        : themeProvider.isDarkMode
                                        ? const Color(0xFF582A6D)
                                        : const Color(0xFFAA51D3)),
                            fontWeight: FontWeight.w500,
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
      },
    );
  }
}

class OverflowAwareText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const OverflowAwareText({Key? key, required this.text, required this.style})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(text: text, style: style);
        final tp = TextPainter(
          text: span,
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflowing = tp.didExceedMaxLines;

        if (isOverflowing) {
          return SizedBox(
            height: 20,
            child: Marquee(
              text: text,
              style: style,
              scrollAxis: Axis.horizontal,
              blankSpace: 30.0,
              velocity: 30.0,
              pauseAfterRound: const Duration(seconds: 1),
              startPadding: 10.0,
              accelerationDuration: const Duration(milliseconds: 500),
              accelerationCurve: Curves.easeIn,
              decelerationDuration: const Duration(milliseconds: 500),
              decelerationCurve: Curves.easeOut,
              textDirection: TextDirection.ltr,
              showFadingOnlyWhenScrolling: true,
              fadingEdgeStartFraction: 0.05,
              fadingEdgeEndFraction: 0.05,
            ),
          );
        }

        return Text(text, style: style, overflow: TextOverflow.ellipsis);
      },
    );
  }
}
