import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "preference_selector.dart";
import "loading.dart";
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/theme.dart';
import 'package:url_launcher/url_launcher.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

// =========BACKGROUND==============//
class BlobBackground extends StatelessWidget {
  final double keyboardHeight;
  final bool isDarkMode;  // Add this parameter

  const BlobBackground({
    Key? key,
    required this.keyboardHeight,
    required this.isDarkMode,  // Add this required parameter
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return CustomPaint(
      size: Size(
        MediaQuery.of(context).size.width,
        MediaQuery.of(context).size.height,
      ),
      painter: BlobPainter(
        keyboardHeight: keyboardHeight,
        isDarkMode: isDarkMode,  // Pass it to the painter
      ),
    );
  }
}

class BlobPainter extends CustomPainter {
  final double keyboardHeight;
  final bool isDarkMode;

  BlobPainter({
    required this.keyboardHeight,
    this.isDarkMode = false,
  });
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint =
    Paint()
      ..shader = LinearGradient(
        colors: isDarkMode
            ? [Color(0xFF422E5A), Color(0xFF1F1B33)]  // dark
            : [Color(0xFF2E1A3B), Color(0xFF3D2352)], // light
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    Path path = Path();
    double stretch = keyboardHeight > 0 ? 0.1 : 0.0;
    double adjustHeight = size.height * (1.0 - stretch);
    //ATTEMPT 1
    // path.moveTo(0, size.height * 0.55);
    // path.quadraticBezierTo(
    //     size.width * 0.25, size.height * 0.85, size.width * 0.5, size.height * 0.8);
    // path.quadraticBezierTo(
    //     size.width * 0.75, size.height * 0.75, size.width, size.height * 0.95);
    // path.lineTo(size.width, size.height);
    // path.lineTo(0, size.height);

    //ATTEMPT 2
    path.moveTo(-500, size.height * 0.7); //  up from 0.65
    path.quadraticBezierTo(
      size.width * 0.75,
      adjustHeight * 0.2, // was 0.4
      size.width * 0.65,
      adjustHeight * 0.5,
    ); // was 0.45
    path.quadraticBezierTo(
      size.width * 1.2,
      adjustHeight * 0.42, // was 0.5
      size.width,
      adjustHeight * 0.6,
    ); // was 0.4
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
// =========END OF BACKGROUND=================//

class _LoginPageState extends State<LoginPage> {
  final _studentIDController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _validateAndLogin() async {
    String studentID = _studentIDController.text;
    String password = _passwordController.text;

    //generateAndUploadSyllabi();

    //CASE 1: studentid & pass empty
    if (studentID.isEmpty || password.isEmpty) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
          title: const Text("Missing Information"),
          content: const Text("Please input username and password"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    //CASE 2: username diisi huruf
    if (!RegExp(r'^[0-9]+$').hasMatch(studentID)) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
          title: const Text("Invalid Student ID"),
          content: const Text("Student ID should consist of numbers only"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    var snapshot =
    await FirebaseFirestore.instance
        .collection('Student')
        .doc(studentID)
        .get();

    if (snapshot.exists) {
      var data = snapshot.data();
      if (data?['PASSWORD'] == password) {
        if (data?['PREFERENCES'].length == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => Scaffold(
                body: SafeArea(
                  child: PreferenceSelector(
                    onComplete: (selectedData, summaries) async {
                      // Handle selection (save to Firebase, local state, etc.)
                      print("Selected: $selectedData");
                      print("Summaries: $summaries");
                      final docRef = FirebaseFirestore.instance
                          .collection('Student')
                          .doc(studentID);
                      try {
                        await docRef.update({
                          'SELECTED': {
                            'Skills I Am Interested':
                            selectedData['Skills I Am Interested'] ??
                                [],
                            'Jobs I Am Seeking':
                            selectedData['Jobs I Am Seeking'] ?? [],
                            'My Priorities':
                            selectedData['My Priorities'] ?? [],
                          },
                        });
                        await docRef.update({'PREFERENCES': summaries});
                        print("Update successful!");
                      } catch (e) {
                        print("Update failed: ${e.toString()}");
                        if (e is FirebaseException) {
                          print("Firebase error code: ${e.code}");
                          print("Firebase message: ${e.message}");
                        }
                      }
                      // Navigate to the next step
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                              Loading1(
                                ID: studentID,
                                userpreferences: summaries,
                                selected: selectedData,
                              ),
                          transitionsBuilder: (
                              context,
                              animation,
                              secondaryAnimation,
                              child,
                              ) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          transitionDuration: Duration(milliseconds: 600),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) => Loading1(
                ID: studentID,
                userpreferences: List<String>.from(
                  data?['PREFERENCES'] ?? [],
                ),
                selected: Map<String, List<String>>.fromEntries(
                  (data?['SELECTED'] as Map<String, dynamic>? ?? {}).entries.map(
                        (e) => MapEntry(
                      e.key.toString(),
                      List<String>.from(
                        (e.value as List).map((item) => item.toString()),
                      ),
                    ),
                  ),
                ),
              ),
              transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                  ) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: Duration(milliseconds: 600),
            ),
          );
        }
        _studentIDController.clear();
        _passwordController.clear();
      } else {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
            title: const Text("Login Failed"),
            content: const Text("Incorrect password"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        );
        return;
      }
    } else {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
          title: const Text("Login Failed"),
          content: const Text("Incorrect username"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: isDarkMode ? Color(0xFF1F1B33) : Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              BlobBackground(
                keyboardHeight: keyboardHeight,
                isDarkMode: isDarkMode,  // Pass the current theme state
              ),
              Align(
                alignment: Alignment(0, -0.28),
                child: Image.asset(
                  'assets/logincubes.png',
                  scale: 0.9,
                  color: isDarkMode ? Color(0xFF554978).withAlpha(60): Color(0xFFBFBFBF).withOpacity(0.2),
                ),
              ),
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                // padding: EdgeInsets.only(bottom: keyboardHeight > 0 ? keyboardHeight * 0.5 : 0),
                // alignment: Alignment(0, keyboardHeight > 0 ? 0.4 : 1),
                //child: BlobBackground(keyboardHeight: keyboardHeight),
              ),
              // AnimatedContainer(
              //   duration: Duration(milliseconds: 300),
              //   alignment: Alignment(0, keyboardHeight > 0 ? 0.4 : 5.4),
              //   child: Image.asset('assets/loginbackground.png', scale: 0.9),
              // ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Image.asset(
                      'assets/loginshapes.png',
                      width: constraints.maxWidth,
                      fit: BoxFit.fitWidth,
                    ),
                  );
                },
              ),
              AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.only(bottom: keyboardHeight > 0 ? 1000 : 0),
                alignment: Alignment(0, -0.83),
                child: Text(
                  'LOG',
                  style: GoogleFonts.montserrat(
                    fontSize: 96,
                    color: isDarkMode? Color(0xFF866BA6).withAlpha(90) : Color(0xFFF0EEEE),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.only(bottom: keyboardHeight > 0 ? 1000 : 0),
                alignment: Alignment(0, -0.61),
                child: Hero(
                  tag: 'eecsync-logo', // HERO ANIMATION TAG
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      'eecsync',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        color: isDarkMode? MyTheme.getSettingsTextColor(isDarkMode) : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.only(bottom: keyboardHeight > 0 ? 1000 : 0),
                alignment: Alignment(0, -0.55),
                child: Text(
                  'IN',
                  style: GoogleFonts.montserrat(
                    fontSize: 96,
                    color: isDarkMode? Color(0xFF866BA6).withAlpha(90) : Color(0xFFF0EEEE),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
// Replace the Align widget containing your form with this:
// Replace the Align widget containing your form with this:
              AnimatedAlign(
                duration: Duration(milliseconds: 300),
                alignment: keyboardHeight > 0 ? Alignment(0, -0.2) : Alignment(0, 0.64),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  child: Container(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Your existing form fields...
                          // USERNAME SECTION
                          Container(
                            width: 305,
                            height: 58.25,
                            decoration: BoxDecoration(
                              color: MyTheme.getSettingsTextColor(isDarkMode),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                width: 2,
                                color: Color(0xFFEEDBFF),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: Offset(0, 7),
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: _studentIDController,
                              style: TextStyle(color: Color(0xFF65558F)),
                              decoration: InputDecoration(
                                hintText: 'Student ID',
                                prefixIcon: Icon(Icons.person),
                                prefixIconColor: Color(0xFF65558F),
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Color(0xFFA185C1),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 15,
                                  horizontal: 20,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 30),

                          // PASSWORD SECTION
                          Container(
                            width: 305,
                            height: 58.25,
                            decoration: BoxDecoration(
                              color: MyTheme.getSettingsTextColor(isDarkMode),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                width: 2,
                                color: Color(0xFFEEDBFF),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: Offset(0, 4),
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              style: TextStyle(color: Color(0xFF65558F)),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline),
                                prefixIconColor: Color(0xFF65558F),
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Color(0xFFA185C1),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 15,
                                  horizontal: 20,
                                ),
                              ),
                            ),
                          ),

                          // FORGOT PASSWORD SECTION
                          Container(
                            width: 305,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    //add logic
                                    final url = Uri.parse('https://www.ccxp.nthu.edu.tw/ccxp/INQUIRE/PC/1/1.3/PC13001.php?lang=E');
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url, mode: LaunchMode.externalApplication); // opens in browser
                                    } else {
                                      throw 'Could not launch $url';
                                    }
                                  },
                                  style: ButtonStyle(
                                    overlayColor: MaterialStateProperty.all(
                                      Colors.transparent,
                                    ),
                                  ),
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: MyTheme.getSettingsTextColor(isDarkMode),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: keyboardHeight > 0 ? 5 : 40), // More responsive spacing

                          // LOGIN BUTTON
                          Container(
                            height: 63,
                            width: 294,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: Offset(0, 3),
                                  spreadRadius: -3.5,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(5),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: MyTheme.getSettingsTextColor(isDarkMode),
                                  borderRadius: BorderRadius.circular(38),
                                ),
                                child: TextButton(
                                  onPressed: _validateAndLogin,
                                  child: Text(
                                    'Log In',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Color(0xFF1E1C1F),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
