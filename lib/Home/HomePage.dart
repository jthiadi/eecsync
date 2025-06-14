import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../Data/UserData.dart';
import '../Recommendation/get_ai_response.dart';
import '../Data/CourseData.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Data/GraduationRequirement.dart';
import '../Recommendation/RecommendationPage.dart';
import '../Calendar/CalendarPage.dart';
import 'HomeScreen.dart';
import '../MainJobs/MainJobs.dart';
import '../Settings/Settings.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/theme.dart';  

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _currentIndex = 2;

  final List<Widget> _pages = [
    CalendarPage(), // CLNDR
    RecommendationPage(),
    HomeScreen(),
    MainJobs(), // JOBS
    SettingsPage(), // STTNGS
  ];

  final List<PageType> _pageTypes = [
    PageType.calendar,
    PageType.recommendation,
    PageType.home,
    PageType.jobs,
    PageType.settings,
  ];

  void setCurrentIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return AppScaffold(
      currentIndex: _currentIndex,
      backgroundGradient: MyTheme.getPageGradient(_pageTypes[_currentIndex], isDarkMode),
      onNavItemTapped: (index) {
        if (index != _currentIndex) {
          setState(() {
            _currentIndex = index;
          });
        }
      },
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        transitionBuilder:
            (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: _pages[_currentIndex],
      ),
    );
  }
}