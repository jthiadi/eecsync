import 'package:flutter/material.dart';
import 'LoginPage.dart';
import '../Data/UserData.dart';
import 'package:provider/provider.dart';
import '../widgets/theme.dart';

class PreferenceSelector extends StatefulWidget {
  final void Function(Map<String, List<String>>, List<String>) onComplete;

  const PreferenceSelector({super.key, required this.onComplete});

  @override
  State<PreferenceSelector> createState() => _PreferenceSelectorState();
}

class _PreferenceSelectorState extends State<PreferenceSelector>
    with TickerProviderStateMixin {
  final Map<String, List<String>> categories = {
    "Skills I Am Interested": [
      "Hardware Circuits",
      "Programming",
      "AI/ML",
      "Networks",
      "Cybersecurity",
      "Data",
      "Cloud",
      "DevOps",
    ],
    "Jobs I Am Seeking": [
      "Teaching Assistant",
      "Research Assistant",
      "Internship",
      "Office Job",
    ],
    "My Priorities": [
      "GPA",
      "Opportunities",
      "Studies",
      "Skills",
      "Work-School Balance",
      "All Pass",
    ],
  };

  late final Map<String, List<String>> selected;

  List<String> generatedSummary = [];

  final List<Map<String, dynamic>> iconStyles = [
    {'icon': Icons.wb_sunny, 'label': 'Enjoy'},
    {'icon': Icons.air, 'label': 'Interest'},
    {'icon': Icons.eco, 'label': 'Passion'},
    {'icon': Icons.star, 'label': 'Goal'},
  ];

  late AnimationController _iconController;
  late Animation<Offset> _slideAnimation;

  late AnimationController _studyIconController;
  late Animation<Offset> _studyIconAnimation;

  @override
  void initState() {
    selected = UserData().selectedData.isNotEmpty
        ? Map.from(UserData().selectedData) // Create a new copy
        : {
            "Skills I Am Interested": [],
            "Jobs I Am Seeking": [],
            "My Priorities": [],
          };
    super.initState();

    setState(() {
      
    });

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.1, 0),
    ).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );

    _studyIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _studyIconAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0.05, 0),
    ).animate(
      CurvedAnimation(parent: _studyIconController, curve: Curves.easeInOut),
    );

    generateSummary();
  }

  void toggleSelection(String category, String item) {
    final selectedList = selected[category]!;
    setState(() {
      if (selectedList.contains(item)) {
        selectedList.remove(item);
      } else if (selectedList.length < 2) {
        selectedList.add(item);
      }
      generateSummary();
    });
  }

  void generateSummary() {
    final courses = selected["Skills I Am Interested"] ?? [];
    final jobs = selected["Jobs I Am Seeking"] ?? [];
    final priority = selected["My Priorities"] ?? [];
    final summaries = <String>[];

    if (courses.isNotEmpty && jobs.isNotEmpty) {
      summaries.add(
        "I enjoy ${jobs.join(' & ')} roles & ${courses.join(' & ')} studies.",
      );
    }
    if (jobs.isNotEmpty) {
      summaries.add("${jobs.join(' & ')} are jobs I’d like to explore more.");
    }
    if (courses.isNotEmpty) {
      summaries.add("I'm focused on learning ${courses.join(' & ')}.");
    }
    if (priority.isNotEmpty) {
      summaries.add("I prioritize on ${priority.join(' & ')}.");
    }
    generatedSummary = summaries.take(4).toList();
  }

  Widget buildCategory(String category, double scaleFactor) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final selectedList = selected[category]!;
    final maxReached = selectedList.length >= 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category,
          style: TextStyle(
            fontSize: 15 * scaleFactor,
            fontWeight: FontWeight.w900,
            color: const Color.fromARGB(255, 209, 180, 231),
          ),
        ),
        SizedBox(height: 10 * scaleFactor),
        Wrap(
          spacing: 10 * scaleFactor,
          runSpacing: 8 * scaleFactor,
          children:
              categories[category]!.map((item) {
                final isSelected = selectedList.contains(item);
                final isDisabled = maxReached && !isSelected;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: ChoiceChip(
                    label: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14 * scaleFactor,
                        fontWeight: FontWeight.w600,
                        color: isDisabled
                            ? (isDarkMode
                            ? const Color.fromARGB(255, 157, 145, 170)
                            : const Color.fromARGB(255, 199, 187, 214))
                            : isSelected
                            ? Colors.white
                            : (isDarkMode
                            ? Color.fromARGB(255, 131, 104, 163)

                          : const Color.fromARGB(255, 145, 118, 160)),
                      ),
                    ),
                    selected: isSelected,
                    onSelected: isDisabled ? null : (_) => toggleSelection(category, item),
                    selectedColor: isDarkMode
                        ? const Color.fromARGB(255, 180, 130, 230)
                        : const Color.fromARGB(255, 147, 116, 201),
                    backgroundColor: isDarkMode
                        ? MyTheme.getSettingsTextColor(isDarkMode)
                        : MyTheme.getSettingsTextColor(isDarkMode),
                    disabledColor: MyTheme.getSettingsTextColor(isDarkMode),
                    checkmarkColor: Colors.white,
                    showCheckmark: true,
                    side: BorderSide(
                      color: isDisabled
                          ? Colors.grey.shade600
                          : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade300),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                );
              }).toList(),
        ),
        SizedBox(height: 16 * scaleFactor),
      ],
    );
  }

  Widget buildSummaryCard(
    String text,
    IconData icon,
    String label,
    double scaleFactor,
    Color bgColor,
    bool darkText,
  ) {
    final textColor = darkText ? Colors.white : Colors.black;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (_, value, __) {
        return Transform.scale(
          scale: value,
          child: Card(
            color: bgColor,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: EdgeInsets.all(8 * scaleFactor),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.rotate(
                    angle: (1 - value) * 3.14,
                    child: Icon(icon, size: 24 * scaleFactor, color: textColor),
                  ),
                  SizedBox(height: 6 * scaleFactor),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14 * scaleFactor,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 8 * scaleFactor),
                  Flexible(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 12 * scaleFactor,
                        fontStyle: FontStyle.italic,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
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

  Widget buildSummaryGrid(double scaleFactor) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: generatedSummary.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8 * scaleFactor,
        mainAxisSpacing: 8 * scaleFactor,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        final iconData = iconStyles[index % iconStyles.length];
        final isLeft = index % 2 == 0;
        final isTopRow = index < 2;
        final usePurple = isLeft == isTopRow;

        return buildSummaryCard(
          generatedSummary[index],
          iconData['icon'],
          iconData['label'],
          scaleFactor,
          usePurple ? const Color.fromARGB(255, 174, 139, 235) : Colors.white,
          usePurple,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final scaleFactor = MediaQuery.of(context).size.width / 390;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: isDarkMode
      ? LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF2B2141),
        Color(0xFF201C33),
      ],
      stops: [0.0, 1.0],
    )
        : LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
    Color(0xFFA157C7),
    Color(0xFF1E1C1F),
    ],
    stops: [0.0, 0.97],
    ),

    ),
            ),
          ),
          Positioned(
            top: -MediaQuery.of(context).size.height * 0.8,
            left: -MediaQuery.of(context).size.width * 0.3,
            child: Container(
              height: MediaQuery.of(context).size.height * 1.6,
              width: MediaQuery.of(context).size.width * 1.8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color.fromARGB(70, 150, 120, 200),
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(height: statusBarHeight),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(15 * scaleFactor),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 30 * scaleFactor,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: const Color.fromARGB(255, 238, 216, 255),
                            ),
                            children: [
                              const TextSpan(text: "Write Your Own Plans "),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: SlideTransition(
                                  position: _studyIconAnimation,
                                  child: Icon(
                                    Icons.school,
                                    size: 28 * scaleFactor,
                                    color: const Color.fromARGB(
                                      255,
                                      238,
                                      216,
                                      255,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16 * scaleFactor),
                        buildSummaryGrid(scaleFactor),
                        SizedBox(height: 24 * scaleFactor),
                        ...categories.keys.map(
                          (cat) => buildCategory(cat, scaleFactor),
                        ),
                        SizedBox(height: 40 * scaleFactor),
                        Center(
                          child: Container(
                            width: 220,
                            decoration: BoxDecoration(
                              color: MyTheme.getSettingsTextColor(isDarkMode),
                              borderRadius: BorderRadius.circular(38),
                            ),
                            child: TextButton(
                              onPressed:
                                  () => widget.onComplete(
                                    selected,
                                    generatedSummary,
                                  ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Continue",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Color.fromARGB(255, 131, 104, 163),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SlideTransition(
                                    position: _slideAnimation,
                                    child: const Icon(
                                      Icons.arrow_forward,
                                      size: 25,
                                      color: Color.fromARGB(255, 131, 104, 163),

                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16 * scaleFactor),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _iconController.dispose();
    _studyIconController.dispose();
    super.dispose();
  }
}
