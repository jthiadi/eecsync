import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/nthu_background.dart';
import '../main.dart';
import 'curved_bg.dart';
import 'dropdown.dart';
import 'result.dart';
import '../Data/course_rec_data.dart';
import 'package:provider/provider.dart';
import '../widgets/theme.dart';

class ResultPage extends StatefulWidget {
  const ResultPage({Key? key}) : super(key: key);

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final TextEditingController _creditsController = TextEditingController(
    text: '15',
  );
  final TextEditingController _searchController = TextEditingController();
  bool _isValidCredits = true;
  bool _randomizeChoices = false;

  final List<Map<String, dynamic>> _selectedCourseTypes = [];

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

  @override
  void initState() {
    super.initState();
    _validateCredits(_creditsController.text);
  }

  @override
  void dispose() {
    _creditsController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _validateCredits(String value) {
    final credits = int.tryParse(value);
    setState(() {
      _isValidCredits = credits != null && credits > 0 && credits <= 30;
    });
  }

  void _selectCourseType(Map<String, dynamic> courseType) {
    setState(() {
      // if already selected
      final existingIndex = _selectedCourseTypes.indexWhere(
        (item) => item['id'] == courseType['id'],
      );
      if (existingIndex == -1) {
        // add to selected list if not alr
        _selectedCourseTypes.add(courseType);
      } else {
        // if already in list, don't add again
        _removeCourseType(courseType);
        return;
      }
      _searchController.clear();
    });
  }

  void _removeCourseType(Map<String, dynamic> courseType) {
    setState(() {
      _selectedCourseTypes.removeWhere(
        (item) => item['id'] == courseType['id'],
      );
    });
  }

  void _toggleRandomize(bool value) {
    setState(() {
      _randomizeChoices = value;
      if (value) {
        // clear all selections when randomize is enabled
        _selectedCourseTypes.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return AppScaffold(
      currentIndex: 1,
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
      showBottomNav: true,
      onNavItemTapped: (index) {
        homePageKey.currentState?.setCurrentIndex(index);
        Navigator.of(context).pop();
      },
      body: Stack(
        children: [
          const CurvedBackground(),
          const NthuBackground(),
          // to handle keyboard overflow
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 30, 30, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "FILL INFORMATION",
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                      color: MyTheme.getSettingsTextColor(isDarkMode),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // target creds
                  Container(
                    decoration: BoxDecoration(
                      color: MyTheme.getSettingsTextColor(isDarkMode),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Text(
                            'Target Credits',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: _creditsController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                              ),
                              inputFormatters: [
                                // limit input to 2 digits
                                LengthLimitingTextInputFormatter(2),
                                // only allow digits
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: _validateCredits,
                            ),
                          ),
                          if (_isValidCredits)
                            const Icon(Icons.check_circle, color: Colors.green)
                          else
                            const Icon(Icons.error, color: Colors.red),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // pass sorted course types to dropdown
                  CourseTypeDropdown(
                    selectedCourseTypes: _selectedCourseTypes,
                    courseTypes: _courseTypes,
                    onSelect: _selectCourseType,
                    onRemove: _removeCourseType,
                    randomizeChoices: _randomizeChoices,
                  ),

                  const SizedBox(height: 20),

                  // randomize
                  Row(
                    children: [
                      Switch(
                        value: _randomizeChoices,
                        onChanged: _toggleRandomize,
                        activeColor: Color(0xFFFFFFFF),
                        activeTrackColor: Color(0xFFAFDAAA),
                        inactiveThumbColor: Colors.grey[300],
                        inactiveTrackColor: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Randomize My Choices',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // start button - disabled when credits are invalid
                  Center(
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color:
                            _isValidCredits ? MyTheme.getSettingsTextColor(isDarkMode) : Colors.grey[300],
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          if (_isValidCredits)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed:
                            _isValidCredits
                                ? () {
                                  // navigate to recommendation page with the entered data

                                  temp = [];
                                  courseList = [];
                                  //availablecourses = getCourses();

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => RecommendationPage(
                                            targetCredits: int.parse(
                                              _creditsController.text,
                                            ),
                                            selectedCourseTypes:
                                                _selectedCourseTypes,
                                            randomizeChoices: _randomizeChoices,
                                          ),
                                    ),
                                  );
                                }
                                : null, 
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isValidCredits ? MyTheme.getSettingsTextColor(isDarkMode) : Colors.grey[300],
                          foregroundColor:
                              _isValidCredits
                                  ? Colors.black87
                                  : Colors.grey[500],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          splashFactory:
                              _isValidCredits
                                  ? InkRipple.splashFactory
                                  : NoSplash.splashFactory,
                        ),
                        child: Text(
                          'Start',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height:
                        MediaQuery.of(context).viewInsets.bottom > 0
                            ? MediaQuery.of(context).viewInsets.bottom
                            : 100,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
