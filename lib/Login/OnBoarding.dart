import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'LoginPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;
  double _opacity = 1.0;
  late Timer _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/ob1.png'), context);
    precacheImage(const AssetImage('assets/ob2.png'), context);
    precacheImage(const AssetImage('assets/ob3.png'), context);
  }

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 8), (Timer timer) {
      _fadeText();
    });
  }

  void _fadeText() {
    setState(() => _opacity = 0.0);

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _currentPage = (_currentPage + 1) % 3;
      });

      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() => _opacity = 1.0);
      });
      // if(_currentPage==2){
      //   _timer.cancel();
      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(builder: (context) => const LoginPage()),
      //   );
      // }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size; //responsive size
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: Hero(
                    tag: 'eecsync-logo', // Unique tag for Hero animation
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        'eecsync',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  // height: 450,
                  // width: 400,
                  // alignment: Alignment.center,
                  flex: 10,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 1000),
                      transitionBuilder: (
                          Widget child,
                          Animation<double> animation,
                          ) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(-1.0, 0.0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Image.asset(
                        _imgOnboard(),
                        key: ValueKey<int>(_currentPage),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.only(
                    left: MediaQuery.of(context).size.width * 0.05,
                    right: MediaQuery.of(context).size.width * 0.125,
                    //bottom: 50
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NTHU DEPARTMENT OF EECS',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          color: Colors.black87,
                        ),
                        softWrap: true,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 80,
                        child: AnimatedOpacity(
                          opacity: _opacity,
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            _title(_currentPage),
                            style: GoogleFonts.poppins(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            softWrap: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),
                Padding(
                  padding: EdgeInsets.only(
                    left: MediaQuery.of(context).size.width * 0.05,
                    right: MediaQuery.of(context).size.width * 0.12,
                    bottom: 50,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      TextButton(
                        onPressed: () async {
                          _timer.cancel();
                          // Navigator.pushReplacement(
                          //   context,
                          //   MaterialPageRoute(builder: (context) => const LoginPage()),
                          // );
                          // final prefs =
                          //     await SharedPreferences.getInstance();
                          // await prefs.setBool('is_first_launch', false);
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration: Duration(milliseconds: 600),
                              pageBuilder: (_, __, ___) => LoginPage(),
                              transitionsBuilder: (_, animation, __, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Get Started',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Padding(
                //   padding: const EdgeInsets.only(bottom: 50),
                //   child: Align(
                //     alignment: Alignment.bottomLeft,
                //     child: TextButton(
                //       onPressed: () {},
                //       style: TextButton.styleFrom(
                //         foregroundColor: Colors.black,
                //       ),
                //       child: Row(
                //         mainAxisSize: MainAxisSize.min,
                //         children: [
                //           TextButton(
                //             onPressed: (){
                //               _timer.cancel();
                //               Navigator.pushReplacement(
                //                 context,
                //                 MaterialPageRoute(builder: (context) => const LoginPage()),
                //               );
                //             },
                //             child: Text('Start Now',
                //               style: GoogleFonts.poppins(
                //                 fontSize: 18,
                //                 fontWeight: FontWeight.bold,
                //                 decoration: TextDecoration.underline,
                //               ),
                //             ),
                //           ),
                //           const SizedBox(width: 8),
                //           const Icon(
                //             Icons.arrow_forward_ios,
                //             size: 18,
                //             color: Colors.black,
                //           ),
                //         ],
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
          Positioned(
            right: 20,
            top: MediaQuery.of(context).size.height * 0.20,
            child: Column(
              children: List.generate(3, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  margin: const EdgeInsets.symmetric(vertical: 15),
                  width: 4,
                  height: _currentPage == index ? 150 : 120,
                  decoration: BoxDecoration(
                    color:
                    _currentPage == index
                        ? const Color.fromARGB(183, 64, 0, 98)
                        : const Color.fromARGB(102, 106, 106, 106),
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  String _imgOnboard() {
    switch (_currentPage) {
      case 0:
        return 'assets/ob1.png';
      case 1:
        return 'assets/ob2.png';
      case 2:
        return 'assets/ob3.png';
      default:
        return 'assets/ob1.png';
    }
  }

  String _title(int pageIndex) {
    switch (pageIndex) {
      case 0:
        return 'Get Personalized Recommendations';
      case 1:
        return 'Customize Your Own Schedule';
      case 2:
        return 'Keep Track Of Classes & Records Easily';
      default:
        return '';
    }
  }
}
