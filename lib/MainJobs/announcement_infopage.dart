import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Calendar/schedule_data.dart';
import 'package:finalproject/Data/UserData.dart';
import 'package:provider/provider.dart';
import '../widgets/theme.dart';
// import '../Calendar/CalendarUtils.dart';
import '../Calendar/CalendarPage.dart';

class AnnouncementInfoPage extends StatefulWidget {
  final Map<String, dynamic>? annData;
  final Map<String, dynamic>? student;
  final VoidCallback? onFavoriteChanged;
  final VoidCallback? onDelete;

  const AnnouncementInfoPage({
    super.key,
    this.annData,
    this.student,
    this.onFavoriteChanged,
    this.onDelete,
  });

  @override
  State<AnnouncementInfoPage> createState() => _AnnouncementInfoPageState();
}

class _AnnouncementInfoPageState extends State<AnnouncementInfoPage> {
  Future<void> saveFirebase(String type, String studentID, String code) async {
    final docRef = FirebaseFirestore.instance
        .collection('Student')
        .doc(studentID);

    if (type == 'JOB') {
      await docRef.update({
        'JOB.SAVED': FieldValue.arrayUnion([code]),
      });
    } else if (type == 'ANNOUNCEMENT') {
      await docRef.update({
        'ANNOUNCEMENT': FieldValue.arrayUnion([code]),
      });
    } else if (type == 'ANNADD') {
      await docRef.update({
        'ANNADD': FieldValue.arrayUnion([code]),
      });
      await loadScheduleData();
      setState(() {}); // This rebuilds the calendar
    }
  }

  Future<void> removeFirebase(
      String type,
      String studentID,
      String code,
      ) async {
    final docRef = FirebaseFirestore.instance
        .collection('Student')
        .doc(studentID);

    if (type == 'JOB') {
      await docRef.update({
        'JOB.SAVED': FieldValue.arrayRemove([code]),
      });
    } else if (type == 'ANNOUNCEMENT') {
      await docRef.update({
        'ANNOUNCEMENT': FieldValue.arrayRemove([code]),
      });
    } else if (type == 'ANNADD') {
      await docRef.update({
        'ANNADD': FieldValue.arrayRemove([code]),
      });
      await loadScheduleData();
      // await removeEventSchedule(
      //   scheduleCode: code,
      //   scheduleData: scheduleData,
      //   onRemove: (oldCourse) {
      //     widget.onDelete?.call();
      //   },
      // );
      widget.onDelete?.call();
      setState(() {}); // This rebuilds the calendar
    }
  }

  bool isSaved(String annCode, Map<String, dynamic> student) {
    final saved = student['ANNOUNCEMENT'] ?? [];
    return saved.contains(annCode);
  }

  addRemoveSaved(String annCode, Map<String, dynamic> student) {
    if (student['ANNOUNCEMENT'].contains(annCode)) {
      student['ANNOUNCEMENT'].remove(annCode);
      removeFirebase('ANNOUNCEMENT', student['ID'], annCode);
    } else {
      student['ANNOUNCEMENT'].add(annCode);
      saveFirebase('ANNOUNCEMENT', student['ID'], annCode);
    }
    widget.onFavoriteChanged?.call();
  }

  bool isAdded(String annCode, Map<String, dynamic> student) {
    final saved = student['ANNADD'] ?? [];
    return saved.contains(annCode);
  }

  addRemoveAnnAdd(String annCode, Map<String, dynamic> student) {
    if (student['ANNADD'].contains(annCode)) {
      student['ANNADD'].remove(annCode);
      removeFirebase('ANNADD', student['ID'], annCode);
    } else {
      student['ANNADD'].add(annCode);
      saveFirebase('ANNADD', student['ID'], annCode);
    }
  }

  Timestamp? lastUpdated;
  String formattedDate = 'Last Updated -';

  @override
  void initState() {
    super.initState();
    print("SCHSLOTS: ${UserData().usedschslot}");
    print("SLOTSRR: ${UserData().usedslot}");

    lastUpdated =
    widget.annData?['last_updated']; // Assuming you passed it via widget
    formattedDate =
    lastUpdated != null
        ? 'Last Updated ${DateFormat('dd/MM/yy').format(lastUpdated!.toDate())}'
        : 'Last Updated -';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode? LinearGradient(
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
        ),
        child: Column(
          children: [
            // Header
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(80),
              ),
              child: Container(
                color: MyTheme.getSettingsTextColor(isDarkMode),
                padding: const EdgeInsets.only(bottom: 20),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.black54,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap:
                                      () {
                                    bool hasConflict = false;
                                    if (!isAdded(widget.annData?['code'], widget.student!)) {
                                      final dates = widget.annData?['date'];
                                      // print("LENGTHOO ${dates.length}");
                                      bool flag = true;
                                      for(int i=0; i<dates.length; i++) {

                                        if (UserData().usedschslot.contains(dates[i])) {
                                          print("GOTCHA CONFLICTS");
                                          showDialog(
                                            context: context,
                                            builder:
                                                (c) => AlertDialog(
                                              title: const Text('Warning'),
                                              content: const Text('Schedule Conflict!'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(c),
                                                  child: const Text('OK'),
                                                ),
                                              ],
                                            ),
                                          );
                                          flag = false;
                                          break;
                                        }
                                        if (i == dates.length-1) {
                                          flag = true;
                                        }
                                      }
                                      flag == false ? hasConflict = true : hasConflict = false;
                                      if (hasConflict == false) {
                                        for(int j=0; j<dates.length; j++) {
                                          addusedschslot(dates[j]);
                                        }
                                      }
                                    } else {
                                      final dates = widget.annData?['date'];
                                      // print("LENGTHOO ${dates.length}");
                                      for(int i=0; i<dates.length; i++) {
                                        // print("DDDD $date");
                                        // print("WWWW $slot");
                                        // print("WLWLWL ${extractSlots(slot[1])}");
                                        removeusedschslot(dates[i]);
                                        var slotArr = dates[i].split(" ");
                                        print("EEEE ${slotArr}");
                                        removeusedslot(slotArr[1]);
                                      }
                                    }

                                    print("SLOTS: ${UserData().usedschslot}");

                                    if (!hasConflict) {
                                      setState(
                                            () => addRemoveAnnAdd(
                                          widget.annData?['code'],
                                          widget.student!,
                                        ),
                                      );
                                    }
                                  },
                                  child: Icon(
                                    isAdded(
                                      widget.annData?['code'],
                                      widget.student!,
                                    )
                                        ? Icons.delete
                                        : Icons.add,
                                    color: const Color(0xFF7A9AC4),
                                  ),

                                  // IconButton(
                                  //   icon: const Icon(Icons.add),
                                  //   iconSize: 32,
                                  //   color: const Color.fromARGB(
                                  //     90,
                                  //     122,
                                  //     154,
                                  //     196,
                                  //   ),
                                  //   onPressed: () {},
                                  // ),
                                ),
                                GestureDetector(
                                  onTap:
                                      () => setState(
                                        () => addRemoveSaved(
                                      widget.annData?['code'],
                                      widget.student!,
                                    ),
                                  ),
                                  child: Icon(
                                    isSaved(
                                      widget.annData?['code'],
                                      widget.student!,
                                    )
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: const Color(0xFF7A9AC4),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          widget.annData?['english_title'],
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF7A9AC4),
                          ),
                        ),
                      ),

                      // Publisher
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 5,
                        ),
                        child: Text(
                          'Published by\n${widget.annData?['publisher']}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: isDarkMode? Color(0xFF5A6BA5) : Color(0xFFB4BFE5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),

                    // Image Placeholder
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: SizedBox(
                          height: 200,
                          child: Card(
                            color: Colors.white24,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child:
                              widget.annData?['imgurl'].isNotEmpty
                                  ? Image.network(
                                widget.annData?['imgurl'],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                loadingBuilder: (
                                    context,
                                    child,
                                    loadingProgress,
                                    ) {
                                  if (loadingProgress == null)
                                    return child;
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                                errorBuilder: (
                                    context,
                                    error,
                                    stackTrace,
                                    ) {
                                  return const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 50,
                                      color: Colors.white38,
                                    ),
                                  );
                                },
                              )
                                  : const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.white38,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Sticky Translucent Label
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(right: 60),
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(20, 255, 255, 255),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Text(
                        'Announcement Details',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.annData?['description'],
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),

                          Text(
                            formattedDate,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
