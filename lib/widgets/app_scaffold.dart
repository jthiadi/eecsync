import 'package:flutter/material.dart';
import 'curved_bottom/curved_bottom_nav.dart';
import '../widgets/top.dart';

class AppScaffold extends StatelessWidget {
  final bool showBottomNav;
  final Widget body;
  final int currentIndex;
  final LinearGradient backgroundGradient;
  final ValueChanged<int>? onNavItemTapped;
  final Widget? topSection;

  const AppScaffold({
    Key? key,
    required this.body,
    required this.currentIndex,
    required this.backgroundGradient,
    this.onNavItemTapped,
    this.topSection,
    this.showBottomNav = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: Column(
          children: [
            topSection ?? TopSection(
              currentIndex: currentIndex,
              backgroundGradient: backgroundGradient,
              onNavItemTapped: onNavItemTapped,
            ),
            Expanded(
              child: SafeArea(
                top: false,
                bottom: true,
                child: Padding(
                  padding: EdgeInsets.only(top: 20, bottom: 20),
                  child: body,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: showBottomNav
          ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            top: false,
            bottom: false,
            child: CurvedBottomNav(
              currentIndex: currentIndex,
              onTap: onNavItemTapped,
            ),
          ),
          Container(height: bottomInset, color: Colors.white),
        ],
      )
          : null,
    );
  }
}