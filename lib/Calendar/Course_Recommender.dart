import '../Data/UserData.dart';
import 'get_calendar_recom.dart';
import '../Data/course_rec_data.dart';

class CourseRecommender {
  Future<List<Map<String, dynamic>>> generateRecommendations(
    Set<String> usedSlots,
    List<String> preferredCourseTypes,
  ) async {
    print(usedSlots);
    final List<Map<String, dynamic>> allCourses = await getcalrec(
      usedSlots,
      preferredCourseTypes,
    );
    // Sample course data - in a real app, this would come from a database
    // final List<Map<String, dynamic>> allCourses = [
    //   {
    //     'title': 'Advanced Algorithms',
    //     'location': 'Delta 101',
    //     'scheduleString': 'W1W2W3',
    //     'professorName': 'Dr. Smith',
    //     'referenceDate': 1, // Semester 2
    //     'isWeekly': true,
    //     'isRecommended': true,
    //     'courseType': 'AL', // Algorithms
    //   },
    //   {
    //     'title': 'Machine Learning',
    //     'location': 'Delta 205',
    //     'scheduleString': 'T3R2',
    //     'professorName': 'Dr. Johnson',
    //     'referenceDate': 1, // Semester 2
    //     'isWeekly': true,
    //     'isRecommended': true,
    //     'courseType': 'AI', // Artificial Intelligence
    //   },
    //   {
    //     'title': 'Database Systems',
    //     'location': 'Delta 301',
    //     'scheduleString': 'M3M4',
    //     'professorName': 'Dr. Williams',
    //     'referenceDate': 1,
    //     'isWeekly': true,
    //     'isRecommended': true,
    //     'courseType': 'AI', // Database and Information Systems
    //   },
    //   {
    //     'title': 'Computer Networks',
    //     'location': 'Delta 102',
    //     'scheduleString': 'T5T6',
    //     'professorName': 'Dr. Brown',
    //     'referenceDate': 1,
    //     'isWeekly': true,
    //     'isRecommended': true,
    //     'courseType': 'AI', // Computer Networks
    //   },
    //   {
    //     'title': 'Software Engineering',
    //     'location': 'Delta 202',
    //     'scheduleString': 'F1F2',
    //     'professorName': 'Dr. Davis',
    //     'referenceDate': 1,
    //     'isWeekly': true,
    //     'isRecommended': true,
    //     'courseType': 'SD', // Software Engineering
    //   },
    //   {
    //     'title': 'Operating Systems',
    //     'location': 'Delta 302',
    //     'scheduleString': 'R3R4',
    //     'professorName': 'Dr. Miller',
    //     'referenceDate': 1,
    //     'isWeekly': true,
    //     'isRecommended': true,
    //     'courseType': 'OS', // Operating Systems
    //   },
    // ];

    final filteredCourses = allCourses;

    final recommendations = <Map<String, dynamic>>[];
    final tempUsedSlots = Set<String>.from(
      UserData().usedslot,
    ); // Copy original used slots

    for (final course in filteredCourses) {
      if (recommendations.length >= 5) break;

      final scheduleString = course['scheduleString'] as String;
      bool hasConflict = false;

      // Check each slot in the course's schedule
      for (int i = 0; i < scheduleString.length; i += 2) {
        if (i + 1 >= scheduleString.length) break;

        final dayCode = scheduleString[i];
        final slotCode = scheduleString[i + 1];
        final slotKey = '$dayCode$slotCode';

        // Conflict if slot is already used
        if (tempUsedSlots.contains(slotKey)) {
          hasConflict = true;
          break;
        }
      }

      // Only add if no conflicts
      if (!hasConflict) {
        recommendations.add(course);

        // Reserve these slots to prevent overlaps in remaining recommendations
        for (int i = 0; i < scheduleString.length; i += 2) {
          if (i + 1 >= scheduleString.length) break;

          final dayCode = scheduleString[i];
          final slotCode = scheduleString[i + 1];
          tempUsedSlots.add('$dayCode$slotCode');
        }
      }
    }
    return recommendations;
  }

  Future<List<Map<String, dynamic>>> generateRecommendations2(
    Set<String> slots,
    List<String> preferredCourseTypes,
  ) async {
    final List<Map<String, dynamic>> allCourses = await getrectanglerec(
      slots,
      preferredCourseTypes,
    );
    // Sample course data - in a real app, this would come from a database
    // final List<Map<String, dynamic>> allCourses = [
    //   {
    //     'title': 'Advanced Algorithms',
    //     'location': 'Delta 101',
    //     'scheduleString': 'W1W2W3',
    //     'professorName': 'Dr. Smith',
    //     'referenceDate': 1, // Semester 2
    //     'isWeekly': true,
    //     'isRecommended': true,
    //     'courseType': 'AL', // Algorithms
    //   },
    //   {
    //     'title': 'Machine Learning',
    //     'location': 'Delta 205',
    //     'scheduleString': 'T3R2',
    //     'professorName': 'Dr. Johnson',
    //     'referenceDate': 1, // Semester 2
    //     'isWeekly': true,
    //     'isRecommended': true,
    //     'courseType': 'AI', // Artificial Intelligence
    //   },
    //   {
    //     'title': 'Database Systems',
    //     'location': 'Delta 301',
    //     'scheduleString': 'M3M4',
    //     'professorName': 'Dr. Williams',
    //     'referenceDate': 1,
    //     'isWeekly': true,
    //     'isRecommended': true,
    //     'courseType': 'AI', // Database and Information Systems
    //   },
    //   {
    //     'title': 'Computer Networks',
    //     'location': 'Delta 102',
    //     'scheduleString': 'T5T6',
    //     'professorName': 'Dr. Brown',
    //     'referenceDate': 1,
    //     'isWeekly': true,
    //     'isRecommended': true,
    //     'courseType': 'AI', // Computer Networks
    //   },
    //   {
    //     'title': 'Software Engineering',
    //     'location': 'Delta 202',
    //     'scheduleString': 'F1F2',
    //     'professorName': 'Dr. Davis',
    //     'referenceDate': 1,
    //     'isWeekly': true,
    //     'isRecommended': true,
    //     'courseType': 'SD', // Software Engineering
    //   },
    //   {
    //     'title': 'Operating Systems',
    //     'location': 'Delta 302',
    //     'scheduleString': 'R3R4',
    //     'professorName': 'Dr. Miller',
    //     'referenceDate': 1,
    //     'isWeekly': true,
    //     'isRecommended': true,
    //     'courseType': 'OS', // Operating Systems
    //   },
    // ];

    final filteredCourses = allCourses;

    final recommendations = <Map<String, dynamic>>[];
    final tempUsedSlots = Set<String>.from(
      UserData().usedslot,
    ); // Copy original used slots

    for (final course in filteredCourses) {
      if (recommendations.length >= 5) break;

      final scheduleString = course['scheduleString'] as String;
      bool hasConflict = false;

      // Check each slot in the course's schedule
      for (int i = 0; i < scheduleString.length; i += 2) {
        if (i + 1 >= scheduleString.length) break;

        final dayCode = scheduleString[i];
        final slotCode = scheduleString[i + 1];
        final slotKey = '$dayCode$slotCode';

        // Conflict if slot is already used
        if (tempUsedSlots.contains(slotKey)) {
          hasConflict = true;
          break;
        }
      }

      // Only add if no conflicts
      if (!hasConflict) {
        recommendations.add(course);

        // Reserve these slots to prevent overlaps in remaining recommendations
        for (int i = 0; i < scheduleString.length; i += 2) {
          if (i + 1 >= scheduleString.length) break;

          final dayCode = scheduleString[i];
          final slotCode = scheduleString[i + 1];
          tempUsedSlots.add('$dayCode$slotCode');
        }
      }
    }
    return recommendations;
  }
}
