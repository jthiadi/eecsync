import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';

class AnimatedProfessorProfile extends StatefulWidget {
  final String name;
  final String englishName;
  final String labName;
  final List<String> scopeItems;
  final String imgurl;
  final String weburl;
  final Offset startPosition; 
  final Size size; // size of professor circle

  const AnimatedProfessorProfile({
    Key? key,
    required this.name,
    required this.englishName,
    required this.labName,
    required this.scopeItems,
    required this.imgurl,
    required this.weburl,
    required this.startPosition,
    required this.size,
  }) : super(key: key);

  @override
  _AnimatedProfessorProfileState createState() => _AnimatedProfessorProfileState();
}

class _AnimatedProfessorProfileState extends State<AnimatedProfessorProfile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _positionAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 2.0, 
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuad,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.5, 1.0, curve: Curves.easeInOut),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);

    _positionAnimation = Tween<Offset>(
      begin: widget.startPosition,
      end: Offset(screenCenter.dx - widget.size.width / 2, screenCenter.dy - screenSize.height * 0.27),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuad,
    ));

    return WillPopScope(
      onWillPop: () async {
        await _controller.reverse();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // animated background blur (bottom layer)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                        sigmaX: 3 * _controller.value,
                        sigmaY: 3 * _controller.value
                    ),
                    child: Container(
                      color: Colors.black.withOpacity(0.85 * _controller.value),
                    ),
                  ),
                );
              },
            ),

            // content layer (middle layer)
            AnimatedBuilder(
              animation: _opacityAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: child,
                );
              },
              child: SafeArea(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: IconButton(
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () async {
                            await _controller.reverse();
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.18),

                    SizedBox(height: 16),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(height: 16),
                              _buildScopeLabSection(widget.scopeItems),
                              SizedBox(height: 30),
                              SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // animated professor profile circle (top layer)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Positioned(
                  left: _positionAnimation.value.dx,
                  top: _positionAnimation.value.dy,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Hero(
                      tag: "professor_${widget.name}",
                      child: Container(
                        width: widget.size.width,
                        height: widget.size.height,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.blue, Colors.purple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: Color(0xFF222123),
                            width: 7.0 / _scaleAnimation.value, 
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: widget.imgurl.isNotEmpty
                              ? Image.network(widget.imgurl, fit: BoxFit.cover)
                              : Icon(
                            Icons.person,
                            color: Colors.white,
                            size: widget.size.width * 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeLabSection(List<String> scopeItems) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFF222123),
        borderRadius: BorderRadius.circular(30),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: widget.size.height * 0.6), 

          Text(
            widget.name,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            widget.englishName,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
            child: Container(
              height: 1.5,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.7),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          Container(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Text(
              widget.labName.toUpperCase(), 
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          ...scopeItems.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          )),

          SizedBox(height: 20),

          SizedBox(
            width: 195,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                final url = Uri.parse(widget.weburl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                } else {
                  throw 'Could not launch $url';
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFA4BDE3),
              ),
              child: Text(
                'WEBSITE',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

void showProfessorProfile(
    BuildContext context, {
      required String name,
      required String englishName,
      required String labName,
      required List<String> scopeItems,
      required String imgurl,
      required String weburl,
      required Offset startPosition,
      required Size size,
    }) {
  Navigator.push(
    context,
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (context, animation, secondaryAnimation) => AnimatedProfessorProfile(
        name: name,
        englishName: englishName,
        labName: labName,
        scopeItems: scopeItems,
        imgurl: imgurl,
        weburl: weburl,
        startPosition: startPosition,
        size: size,
      ),
      transitionDuration: Duration.zero, 
    ),
  );
}