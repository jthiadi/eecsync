import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/theme.dart';

class VerticalBarSearchField extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final String hintText;

  const VerticalBarSearchField({
    Key? key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search...',
  }) : super(key: key);

  @override
  State<VerticalBarSearchField> createState() => _VerticalBarSearchFieldState();
}

class _VerticalBarSearchFieldState extends State<VerticalBarSearchField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    // Define colors for the indicator bar
    final Color indicatorColor =
        _isFocused
            ? const Color(0xFF582A6D) // Purple when focused
            : Colors.grey[400]!; // Grey when not focused

    final Color backgroundColor = Colors.white;
    final Color textColor = Colors.black87;
    final Color hintColor = Colors.grey[400]!;
    final Color cursorColor = const Color(0xFF582A6D);

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Vertical indicator bar
          Container(
            width: 3,
            height: 30,
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            decoration: BoxDecoration(
              color: indicatorColor,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          // Text field
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              cursorColor: cursorColor,
              style: GoogleFonts.poppins(fontSize: 16, color: textColor),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: GoogleFonts.poppins(fontSize: 16, color: hintColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onChanged: widget.onChanged,
            ),
          ),
          // Clear button when text is entered
          if (widget.controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: Colors.grey[400],
              onPressed: () {
                widget.controller.clear();
                widget.onChanged('');
              },
            ),
        ],
      ),
    );
  }
}

// Updated CourseTypeDropdown widget with the new search field
class CourseTypeDropdown extends StatefulWidget {
  final List<Map<String, dynamic>> selectedCourseTypes;
  final List<Map<String, dynamic>> courseTypes;
  final Function(Map<String, dynamic>) onSelect;
  final Function(Map<String, dynamic>) onRemove;
  final bool randomizeChoices;
  final double? maxWidth;

  const CourseTypeDropdown({
    Key? key,
    required this.selectedCourseTypes,
    required this.courseTypes,
    required this.onSelect,
    required this.onRemove,
    required this.randomizeChoices,
    this.maxWidth,
  }) : super(key: key);

  @override
  State<CourseTypeDropdown> createState() => _CourseTypeDropdownState();
}

class _CourseTypeDropdownState extends State<CourseTypeDropdown>
    with SingleTickerProviderStateMixin {
  bool _showDropdown = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CourseTypeDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.randomizeChoices &&
        !oldWidget.randomizeChoices &&
        _showDropdown) {
      _closeDropdown();
    }
  }

  void _toggleDropdown() {
    setState(() {
      _showDropdown = !_showDropdown;
      if (_showDropdown) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _closeDropdown() {
    setState(() {
      _showDropdown = false;
      _animationController.reverse();
    });
  }

  List<Map<String, dynamic>> get _filteredCourseTypes {
    List<Map<String, dynamic>> filtered;

    if (_searchController.text.isEmpty) {
      filtered = List<Map<String, dynamic>>.from(widget.courseTypes);
    } else {
      filtered =
          widget.courseTypes
              .where(
                (course) => course['name'].toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ),
              )
              .toList();
    }

    filtered.sort(
      (a, b) => a['name'].toString().compareTo(b['name'].toString()),
    );

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final double availableHeight =
        MediaQuery.of(context).size.height -
        MediaQuery.of(context).viewInsets.bottom -
        MediaQuery.of(context).padding.top -
        180;

    final double width = widget.maxWidth ?? MediaQuery.of(context).size.width;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width * 0.9),
      child: Column(
        children: [
          // Course Type Selection Header
          GestureDetector(
            onTap: widget.randomizeChoices ? null : _toggleDropdown,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Course Type Preference',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        if (!widget.randomizeChoices)
                          Icon(
                            _showDropdown
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.grey[600],
                          ),
                      ],
                    ),
                  ),

                  // Selected course types as chips
                  if (widget.selectedCourseTypes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 12,
                      ),
                      child: SizedBox(
                        height: 85, // Slightly taller to accommodate more text
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                widget.selectedCourseTypes.map((course) {
                                  // Create a short version of the name for display
                                  String displayName = course['name'];
                                  String shortName = displayName;

                                  // If name is too long, use a short version
                                  if (displayName.length > 20) {
                                    final List<String> words = displayName
                                        .split(' ');
                                    if (words.length > 2) {
                                      // Use first letters of each word except the last one
                                      shortName = words
                                          .sublist(0, words.length - 1)
                                          .map((word) => word[0])
                                          .join('');
                                      shortName += ' ' + words.last;
                                    } else {
                                      // Use first 15 characters + ellipsis
                                      shortName =
                                          displayName.substring(0, 15) + '...';
                                    }
                                  }

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: course['color'].withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Tooltip(
                                            message:
                                                displayName, // Show full name in tooltip
                                            child: Text(
                                              shortName,
                                              style: TextStyle(
                                                color: course['color'],
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: () => widget.onRemove(course),
                                          child: Icon(
                                            Icons.close,
                                            size: 16,
                                            color: course['color'],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Animated Dropdown Slider
          SizeTransition(
            sizeFactor: _animation,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: availableHeight * 0.6,
                maxWidth: width * 0.9,
              ),
              child: Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // New vertical bar search field
                    Padding(
                      padding: const EdgeInsets.all(7),
                      // child: VerticalBarSearchField(
                      //   controller: _searchController,
                      //   onChanged: (value) {
                      //     setState(() {
                      //       // Trigger rebuild to filter the list
                      //     });
                      //   },
                      // ),
                    ),
                    // Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                    // Course type options
                    Flexible(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shrinkWrap: true,
                        itemCount: _filteredCourseTypes.length,
                        separatorBuilder:
                            (context, index) =>
                                const Divider(height: 1, indent: 60),
                        itemBuilder: (context, index) {
                          final courseType = _filteredCourseTypes[index];
                          final bool isSelected = widget.selectedCourseTypes
                              .any(
                                (selected) =>
                                    selected['id'] == courseType['id'],
                              );

                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 0,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: courseType['color'].withOpacity(
                                0.2,
                              ),
                              child: Text(
                                courseType['id'],
                                style: TextStyle(
                                  color: courseType['color'],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              courseType['name'],
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            trailing:
                                isSelected
                                    ? const Icon(
                                      Icons.check,
                                      color: Colors.green,
                                    )
                                    : null,
                            onTap: () {
                              if (isSelected) {
                                widget.onRemove(courseType);
                              } else {
                                widget.onSelect(courseType);
                              }
                            },
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
    );
  }
}
