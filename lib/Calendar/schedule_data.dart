import 'package:flutter/material.dart';
import '../Data/UserData.dart';
import '../Data/CourseData.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

List<Map<String, dynamic>> scheduleData = [];
void addusedslot(String text) {
  for (int i = 0; i < text.length; i += 2) {
    if (i + 1 >= text.length) break;
    UserData().usedslot.add('${text[i]}${text[i + 1]}');
  }
}

void addusedschslot(String text) {
  UserData().usedschslot.add(text);
}

void removeusedschslot(String text) {
  if (UserData().usedschslot.contains(text)) {
    UserData().usedschslot.remove(text);
    print('Removed: $text');
  }
}

void removeusedslot(String text) {
  for (int i = 0; i < text.length; i += 2) {
    if (i + 1 >= text.length) break;
    String slot = '${text[i]}${text[i + 1]}';
    print("UUUUU ${slot}");
    if (UserData().usedslot.contains(slot)) {

      UserData().usedslot.remove(slot);
      print('Removed: $slot');
    }
  }
}

List<String> extractSlots(String time) {
  final slots = <String>[];
  for (int i = 0; i < time.length - 1; i += 2) {
    slots.add('${time[i]}${time[i + 1]}');
  }
  return slots;
}

DateTime parseStartDate(String dateStr) {
  final parts = dateStr.split('/');
  if (parts.length != 3) throw FormatException('Invalid date format');
  final day = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  final year = int.parse(parts[2]);
  return DateTime(year, month, day);
}

DateTime parseEndDate(String dateStr) {
  final parts = dateStr.split('/');
  if (parts.length != 3) throw FormatException('Invalid date format');
  final day = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  final year = int.parse(parts[2]);
  return DateTime(year, month, day);
}

// Function to load schedule data asynchronously
Future<void> loadScheduleData() async {
  scheduleData = await createScheduleData();
  print(scheduleData);
}

Future<List<Map<String, dynamic>>> createScheduleData() async {
  int currentSemester = UserData().semester;

  List<Map<String, dynamic>> currentSemesterCourses =
      UserData().coursestaken
          .where((course) => course['semester'] == currentSemester)
          .toList();

  List<Map<String, dynamic>> scheduleData = [];
  final courseBox = await Hive.openBox<CourseData>('all_courses');

  for (var courseTaken in currentSemesterCourses) {
    try {
      final course = courseBox.values.firstWhere(
        (course) => course.id == courseTaken['code'],
        orElse: () => throw Exception('Course not found'),
      );

      scheduleData.add({
        'title': course.name,
        'code': course.id,
        'location': course.location ?? 'TBA',
        'scheduleString': course.classTime ?? 'TBA',
        'referenceDate': 1,
        'isWeekly': true,
        'isRecommended': false,
        'isEvent': false,
      });
    } catch (e) {
      print('Error processing course ${courseTaken['code']}: $e');
      scheduleData.add({
        'title': courseTaken['name'] ?? 'Unknown Course',
        'code': courseTaken['code'],
        'location': 'TBA',
        'scheduleString': 'TBA',
        'referenceDate': 1,
        'isWeekly': true,
        'isRecommended': false,
        'isEvent': false,
      });
    }
    for (var doc in UserData().recommended) {
      print(doc);
      final course = courseBox.values.firstWhere((course) => course.id == doc);
      scheduleData.add({
        'title': course.name ?? 'Unknown Course',
        'code': course.id ?? "Unknown",
        'location': course.location ?? 'TBA',
        'scheduleString': course.classTime ?? 'TBA',
        'referenceDate': 1,
        'isWeekly': true,
        'isRecommended': true,
        'isEvent': false,
      });
    }
  }

  final eventSnapshot = await FirebaseFirestore.instance
  .collection('News')
  .get();

  final box = await Hive.openBox('userBox');
  Map<String, dynamic>? storedUser = box.get('userData');

  final docSnapshot = await FirebaseFirestore.instance
      .collection('Student')
      .doc(storedUser?['id'])
      .get();

  final Map<String, dynamic> studentData = docSnapshot.data()!;
  final List<dynamic> userAnnAdds = studentData['ANNADD'] ?? [];

  for (final doc in eventSnapshot.docs) {
    final data = doc.data();
    final eventCode = data['code'];

    if (!userAnnAdds.contains(eventCode)) continue; // Skip unassigned events

    final dates = (data['date'] as List).cast<String>();

    for (final raw in dates) {
      final parts = raw.split(' ');
      if (parts.length != 2) continue;

      final dateString = parts[0]; // e.g., "22/3/2025"
      final scheduleCode = parts[1]; // e.g., "S3S4"

      try {
        final startDate = parseStartDate(dateString);
        final endDate = parseEndDate(dateString);

        scheduleData.add({
          'title': data['english_title'] ?? 'Event',
          'code': eventCode ?? '',
          'location': data['location'] ?? 'Event Location',
          'scheduleString': scheduleCode,
          'referenceDate': startDate,
          'endDate': endDate,
          'isWeekly': false,
          'isRecommended': false,
          'isEvent': true,
        });
      } catch (e) {
        print('Invalid event date format: $raw');
      }
    }
  }
  
  print('konnnnm: ${scheduleData}');

  return scheduleData;
}

// List<Map<String, dynamic>> scheduleData = [
//   {
//     'title': 'Calculus',
//     'location': 'Delta 101',
//     'scheduleString': 'W1',
//     'referenceDate': 1,
//     'isWeekly': true,
//     'isRecommended': false,
//   },
//   {
//     'title': 'Physics',
//     'location': 'Gamma 202',
//     'scheduleString': 'T3T4F5F6',
//     'referenceDate':1,
//     'isWeekly': true ,
//     'isRecommended': true,
//   },
//   {
//     'title': 'Meowmeow',
//     'location': 'Beta 303',
//     'scheduleString': 'MnM5F1F2',
//     'referenceDate':1,
//     'isWeekly': true ,
//     'isRecommended': false,
//   },
// ];

// Function to add a new course
Map<String, dynamic> addNewCourse(Map<String, dynamic> newCourse) {
  debugPrint('Adding new course');
  if(!scheduleData.contains(newCourse)) scheduleData.add(newCourse);
  debugPrint(scheduleData.toString());
  return newCourse;
}

// Function to remove a course
void removeOldCourse(Map<String, dynamic> oldCourse) {
  final oldRefDate = oldCourse['referenceDate'];

  scheduleData.removeWhere((course) {
    final refDateMatch =
        course['referenceDate'] == oldRefDate ||
        (course['referenceDate'] is int &&
            oldRefDate is int &&
            course['referenceDate'] == oldRefDate) ||
        (course['referenceDate'] is DateTime &&
            oldRefDate is DateTime &&
            course['referenceDate'].isAtSameMomentAs(oldRefDate));

    return course['title'] == oldCourse['title'] &&
        course['code'] == oldCourse['code'] &&
        course['location'] == oldCourse['location'] &&
        course['scheduleString'] == oldCourse['scheduleString'] &&
        refDateMatch &&
        course['isWeekly'] == oldCourse['isWeekly'];
  });

  debugPrint('Removed old course: ${oldCourse['title']}');
  debugPrint('Updated scheduleData: $scheduleData');
  debugPrint('Remaining courses: ${scheduleData.length}');
}
