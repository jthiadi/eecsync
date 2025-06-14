import 'package:flutter/material.dart';
import 'curved_navigation_bar.dart';
import 'package:provider/provider.dart';
import 'package:finalproject/widgets/theme.dart';

class CurvedBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const CurvedBottomNav({
    Key? key,
    required this.currentIndex,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return CurvedNavigationBar(
      index: currentIndex,
      backgroundColor: Colors.transparent,
      color: MyTheme.getSettingsTextColor(isDarkMode),
      buttonBackgroundColor: MyTheme.getSettingsTextColor(isDarkMode),
      height: 50,
      items: [
        Icon(Icons.calendar_today_outlined,
            size: 20, color: currentIndex == 0 ? Colors.purple : Colors.black),
        Icon(Icons.assignment_outlined,
            size: 20, color: currentIndex == 1 ? Colors.purple : Colors.black),
        Icon(Icons.home_outlined,
            size: 20, color: currentIndex == 2 ? Colors.purple : Colors.black),
        Icon(Icons.work_outline,
            size: 20, color: currentIndex == 3 ? Colors.purple : Colors.black),
        Icon(Icons.settings_outlined,
            size: 20, color: currentIndex == 4 ? Colors.purple : Colors.black),
      ],
      animationDuration: Duration(milliseconds: 300),
      animationCurve: Curves.linear,
      onTap: onTap,
    );
  }
}