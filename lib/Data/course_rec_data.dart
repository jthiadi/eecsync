import 'dart:ffi';

import 'UserData.dart';
import '../Recommendation/get_ai_response.dart';
import 'CourseData.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'GraduationRequirement.dart';
import '../Recommendation/recom_list.dart';
import '../Calendar/get_calendar_recom.dart';
import '../Calendar/schedule_data.dart';
import '../Calendar/get_rectangle_recom.dart';
import '../Recommendation/find_alternative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

List<Map<String, dynamic>> getCourses() {
  final courseBox = Hive.box<CourseData>('all_courses');
  final takenCodes = UserData().coursestaken.map((e) => e['code']).toSet();

  String getCoursePrefix(String courseId) {
    final letters = courseId.split(RegExp(r'[0-9]')).first.trim();
    final numbers = courseId.substring(letters.length).replaceAll(' ', '');
    final firstFourDigits =
    numbers.length >= 4 ? numbers.substring(0, 4) : numbers;
    if (courseId.contains(' ')) {
      return '$letters $firstFourDigits';
    } else {
      return '$letters$firstFourDigits';
    }
  }

  final takenPrefixes = takenCodes.map((code) => getCoursePrefix(code)).toSet();

  print(UserData().recommended);

  final Courses =
  courseBox.values
      .where((course) {
    if ((!course.id.contains('CS') &&
        !course.id.contains('EE') &&
        !course.id.contains('EECS') &&
        !course.id.contains('MATH') &&
        !course.id.contains('PHYS') &&
        !course.id.contains('COM') &&
        !course.id.contains('ENE') &&
        !course.id.contains('IPT') &&
        !course.id.contains('ISA') &&
        !course.id.contains('IIS')) ||
        course.id.contains('EE 39') ||
        course.id.contains('CS 39'))
      return false;
    if (UserData().recommended.contains(course.id)) {
      print('exclude: ${course.name}');
      return false;
    }

    final coursePrefix = getCoursePrefix(course.id);
    return !takenPrefixes.contains(coursePrefix) &&
        !UserData().recommended.contains(coursePrefix);
  })
      .map((course) => course.toJson())
      .toList();
  print(Courses.length);
  return Courses;
}

List<Map<String, dynamic>> getAllCourses() {
  final courseBox = Hive.box<CourseData>('all_courses');
  final takenCodes = UserData().coursestaken.map((e) => e['code']).toSet();

  String getCoursePrefix(String courseId) {
    final letters = courseId.split(RegExp(r'[0-9]')).first.trim();
    final numbers = courseId.substring(letters.length).replaceAll(' ', '');
    final firstFourDigits =
    numbers.length >= 4 ? numbers.substring(0, 4) : numbers;
    if (courseId.contains(' ')) {
      return '$letters $firstFourDigits';
    } else {
      return '$letters$firstFourDigits';
    }
  }

  final takenPrefixes = takenCodes.map((code) => getCoursePrefix(code)).toSet();

  final Courses = courseBox.values.map((course) => course.toJson()).toList();
  print(Courses.length);
  return Courses;
}

Map<String, dynamic> buildGraduationSummary() {
  Set<String> temp = {};
  Map<String, dynamic> summary = {};
  final takenCodes =
  UserData().coursestaken
      .where((e) => !['W', 'F', 'D', 'X'].contains(e['gpa']))
      .map((e) => e['code'])
      .toSet();
  print(takenCodes);

  String getCoursePrefix(String courseId) {
    final letters = courseId.split(RegExp(r'[0-9]')).first.trim();
    final numbers = courseId.substring(letters.length).replaceAll(' ', '');
    final firstFourDigits =
    numbers.length >= 4 ? numbers.substring(0, 4) : numbers;
    if (courseId.contains(' ')) {
      return '$letters $firstFourDigits';
    } else {
      return '$letters$firstFourDigits';
    }
  }

  final takenPrefixes = takenCodes.map((code) => getCoursePrefix(code)).toSet();

  print(takenPrefixes);

  groupedRequirements.forEach((category, requirements) {
    if (requirements.length == 1) return;
    int? originalCredits = int.tryParse(requirements[0][0]);
    int remainingCredits = originalCredits ?? 0;
    List<List<String>> neededCourses = [];

    for (int i = 1; i < requirements.length; i++) {
      var req = requirements[i];

      String? takenCourseInGroup;
      for (var course in req) {
        final prefix = getCoursePrefix(course);
        if (takenPrefixes.contains(prefix)) {
          takenCourseInGroup = course;
          break;
        }
      }

      if (takenCourseInGroup != null) {
        final matchedCourse = UserData().coursestaken.firstWhere(
              (e) =>
          getCoursePrefix(e['code']) ==
              getCoursePrefix(takenCourseInGroup!),
        );
        temp.add(matchedCourse['code']);
        if (matchedCourse != null && matchedCourse['credit'] != null) {
          remainingCredits -=
              int.tryParse(matchedCourse['credit'].toString()) ?? 0;
        }
      } else {
        neededCourses.add(req);
      }
    }

    summary[category] = {
      "credits_needed": remainingCredits < 0 ? 0 : remainingCredits,
      "courses_needed": neededCourses,
    };
  });

  final unmatchedCourses = takenCodes.difference(temp.toSet()).toList();
  int? remainingCredits = int.tryParse(
    groupedRequirements['Professional Courses']?[0]?[0] ?? '0',
  );
  for (var code in unmatchedCourses) {
    print(code);
    if (code.startsWith('EECS') ||
        code.startsWith('CS') ||
        code.startsWith('EE') ||
        code.startsWith('COM') ||
        code.startsWith('ENE') ||
        code.startsWith('IPT') ||
        code.startsWith('ISA') ||
        code.startsWith('IIS')) {
      final matched = UserData().coursestaken.firstWhere(
            (e) => e['code'] == code,
      );

      if (matched != null && matched['credit'] != null) {
        remainingCredits =
            (remainingCredits ?? 0) -
                int.tryParse(matched['credit'].toString())!;
      }
    }
  }

  print(summary);

  summary['Professional Courses'] = {
    "credits_needed": remainingCredits! < 0 ? 0 : remainingCredits,
  };
  print(summary);
  return summary;
}

List<dynamic> courseList = [];
List<dynamic> temp = [];
var availablecourses;
var semua = getAllCourses();
var allcourses = getCourses();
// List<String> takenCourses =
//     UserData().coursestaken.map((e) {
//       final code = e['name'];
//       final gpa = e['gpa'] ?? 'N/A';
//       return "$code - GPA: $gpa";
//     }).toList();
List<String> takenCoursess =
UserData().coursestaken.where((e) => e['gpa'] != 99).map((e) {
  final name = e['name'];
  final gpa = e['gpa'] ?? 'N/A';
  final tscore = e['t-score'] ?? 'N/A';
  final credit = e['credit'] ?? 'N/A';
  final semester = e['semester'] ?? 'N/A';
  return "$name - GPA: $gpa - T-score: $tscore - course credit: $credit - semester: $semester";
}).toList();

Future<List<Map<String, dynamic>>> getcalrec(
    Set<String> timeslot,
    List<String> preferredCourseTypes,
    ) async {
  var tmp = getAllCourses();
  String response = await getcalendarrecom(
    buildGraduationSummary(),
    tmp.map((course) => Map<String, dynamic>.from(course)).where((
        course,
        ) {
      final classTime = course['classTime'] as String;
      //print(classTime);
      final courseSlots = extractSlots(classTime).toSet();
      return courseSlots.intersection(timeslot).isEmpty;
    }).toList(),
    takenCoursess,
    preferredCourseTypes,
  );
  String cleanResponse =
  response.replaceAll('```json', '').replaceAll('```', '').trim();
  courseList = jsonDecode(cleanResponse);
  print(courseList);
  courseList.map((course) => course.toString()).toList();
  final courseBox = Hive.box<CourseData>('all_courses');
  List<Map<String, dynamic>> ret = [];
  for (var code in courseList) {
    try {
      final temp = courseBox.values.firstWhere((course) => code == course.id);
      Map<String, dynamic> tmp = {
        'title': temp.name,
        'code': temp.id,
        'location': temp.location,
        'scheduleString': temp.classTime,
        'professorName': temp.professor,
        'referenceDate': 1,
        'isWeekly': true,
        'isRecommended': true,
        'courseType': 'AL',
      };
      ret.add(tmp);
    } catch (e) {
      print('Error processing course code $code: $e');
      continue;
    }
  }
  print(ret);
  return ret;
}

Future<List<Map<String, dynamic>>> getrectanglerec(
    Set<String> slot,
    List<String> preferredCourseTypes,
    ) async {
  var tmp = getAllCourses();
  String response = await getrectanglerecom(
    buildGraduationSummary(),
    tmp.map((course) => Map<String, dynamic>.from(course)).where((
        course,
        ) {
      final classTime = course['classTime'] as String;
      //print(classTime);
      final courseSlots = extractSlots(classTime).toSet();
      return slot.containsAll(courseSlots);
    }).toList(),
    takenCoursess,
    preferredCourseTypes,
  );
  String cleanResponse =
  response.replaceAll('```json', '').replaceAll('```', '').trim();
  courseList = jsonDecode(cleanResponse);
  //print(courseList);
  courseList.map((course) => course.toString()).toList();
  final courseBox = Hive.box<CourseData>('all_courses');
  List<Map<String, dynamic>> ret = [];
  for (var code in courseList) {
    try {
      final temp = courseBox.values.firstWhere((course) => code == course.id);
      Map<String, dynamic> tmp = {
        'title': temp.name,
        'code': temp.id,
        'location': temp.location,
        'scheduleString': temp.classTime,
        'professorName': temp.professor,
        'referenceDate': 1,
        'isWeekly': true,
        'isRecommended': true,
        'courseType': 'AL',
      };
      ret.add(tmp);
    } catch (e) {
      print('Error processing course code $code: $e');
      continue;
    }
  }
  print(ret);
  return ret;
}

Future<List<dynamic>> start_get_rec(
    int targetcredits,
    List<Map<String, dynamic>> preference,
    ) async {
  availablecourses = getCourses();
  print('generating');
  print('temp:${temp}');
  print('requirement: ${buildGraduationSummary()}');
  String response = await getairesponse(
    buildGraduationSummary(),
    availablecourses,
    takenCoursess,
    targetcredits,
    preference,
  );
  String cleanResponse =
  response.replaceAll('```json', '').replaceAll('```', '').trim();
  courseList = jsonDecode(cleanResponse);
  print(courseList);
  temp += courseList;
  return courseList.map((course) => course.toString()).toList();
}

Future<List<dynamic>> regenerate_rec(
    int targetcredits,
    List<Map<String, dynamic>> preference,
    ) async {
  print('temp:${temp}');
  availablecourses =
      availablecourses.where((course) {
        return !temp.contains(course['id']);
      }).toList();
  String response = await getairesponse(
    buildGraduationSummary(),
    availablecourses,
    takenCoursess,
    targetcredits,
    preference,
  );
  String cleanResponse =
  response.replaceAll('```json', '').replaceAll('```', '').trim();
  courseList = jsonDecode(cleanResponse);
  temp += courseList;
  print(temp);
  return courseList;
}

Future<dynamic> generate_alternative(String courseid) async {
  final courseBox = Hive.box<CourseData>('all_courses');

  final course =
  courseBox.values.firstWhere((course) => courseid == course.id).toJson();
  availablecourses =
      availablecourses.where((course) {
        return !temp.contains(course['id']);
      }).toList();
  String response = await getalternative_response(
    buildGraduationSummary(),
    availablecourses,
    takenCoursess,
    course,
  );
  String cleanResponse =
  response.replaceAll('```json', '').replaceAll('```', '').trim();
  var ret = [jsonDecode(cleanResponse)];
  temp += ret;
  return ret;
}

Future<List<CourseRecommendation>> format_result(List<dynamic> response) async {
  final courseBox = await Hive.openBox<CourseData>('all_courses');
  List<CourseRecommendation> ret = [];
  for (var i in response) {
    print("searching for ${i}");
    bool found = true;
    try {
      final course = courseBox.values.firstWhere((course) => i == course.id);

      print(course);

      if (course != null) {
        ret.add(
          CourseRecommendation(
            id: course.id,
            code: course.id,
            name: course.name,
            professor: course.professor,
            status: CourseStatus.available,
            department:
            RegExp(r'[A-Za-z]+')
                .allMatches(course.id)
                .map((match) => match.group(0))
                .where((letters) => letters != null)
                .join(),
            credits: course.credit,
            syllabus: course.syllabus,
            grading: course.grading,
            location: course.location,
            time: course.classTime ?? 'Unknown',
          ),
        );
      }
    } catch (e) {
      continue;
    }
  }
  return ret;
}

Future<List<Map<String, dynamic>>> getalljobs() async {
  final querySnapshot1 =
  await FirebaseFirestore.instance.collection('TA Application').get();

  List<Map<String, dynamic>> ret = [];
  for (var i in querySnapshot1.docs) {
    final applicants = i.data()['applicants'] ?? {};
    final applicantsList =
    applicants is Map
        ? applicants.values.toList()
        : (applicants is List ? applicants : []);
    int pending = 0;
    int rejected = 0;
    int accepted = 0;
    for (var j in applicantsList) {
      if (j['status'] == 'P') {
        pending += 1;
      } else if (j['status'] == 'R') {
        rejected += 1;
      } else if (j['status'] == 'A') {
        accepted += 1;
      }
    }
    Map<String, dynamic> tmp = {
      'code': i.id,
      'title': i['title'],
      'quota': i['quota']['max'],
      'total_applicants': i['applicants'].length,
      'pending_status_student': pending,
      'rejected_student': rejected,
      'accepted_student': accepted,
      'position': i['position'],
      'qualifications': i['qualifications'],
    };
    ret.add(tmp);
  }
  print('r4est:$ret');
  return ret;
}
