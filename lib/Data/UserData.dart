import '../Login/Loading.dart';
import '../Data/GraduationRequirement.dart';
import 'package:hive/hive.dart';
part 'UserData.g.dart';

@HiveType(typeId: 0)
class UserData extends HiveObject {
  static final UserData _instance = UserData._internal();

  factory UserData() => _instance;

  UserData._internal();

  @HiveField(0)
  String id = '';

  @HiveField(1)
  String name = '';

  @HiveField(2)
  String chinese_name = '';

  @HiveField(3)
  double gpa = 0.0;

  @HiveField(4)
  int credits = 0;

  @HiveField(5)
  int withdrawals = 0;

  @HiveField(6)
  int passed = 0;

  @HiveField(7)
  int semester = 0;

  @HiveField(8)
  List<int> rank = [];

  @HiveField(9)
  List<String> preferences = [];

  @HiveField(10)
  Map<String, List<String>> selectedData = {};

  @HiveField(11)
  String? profile;

  @HiveField(12)
  List<Map<String, dynamic>> coursestaken = [];

  @HiveField(13)
  Set<String> recommended = {};

  @HiveField(14)
  Set<String> usedslot = {};

  @HiveField(15)
  Set<String> usedschslot = {};

  void fromMap(Map<String, dynamic> map) {
    id = map['id'] ?? '';
    name = map['name'] ?? '';
    chinese_name = map['chinese_name'] ?? '';
    semester = map['semester'] ?? 0;
    profile = map['profile'] ?? '';
    rank = map['rank'] ?? [];
    preferences = map['preferences'] ?? '';
    selectedData = map['selectedData'] ?? '';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'chinese_name': chinese_name,
      'coursestaken': coursestaken,
    };
  }

  void setCourses(List<Map<String, dynamic>> courseList) {
    coursestaken =
        courseList.map((course) {
          return {
            'code': course['code'] ?? '',
            'name': course['name'] ?? '',
            'gpa': course['gpa'] ?? 0.0,
            't-score': course['t-score'] ?? 0.0,
            'semester': course['semester'] ?? 0,
            'credit': course['credit'] ?? 0,
          };
        }).toList();
    print(coursestaken);
  }

  /// Adds a single course with structured data
  void addCourse(
    String code,
    String name,
    double gpa,
    double tscore,
    int semester,
    int credit,
  ) {
    coursestaken.add({
      'code': code,
      'name': name,
      'gpa': gpa,
      't-score': tscore,
      'semester': semester,
      'credit': credit,
    });
  }

  Map<int, Map<String, List<Map<String, dynamic>>>> getCoursesBySemester() {
    final Map<int, Map<String, List<Map<String, dynamic>>>> semesterMap = {};

    for (final course in coursestaken) {
      if (course['semester'] >= UserData().semester) continue;
      final semester = course['semester'] as int;
      final code = course['code'] as String;
      final match = RegExp(r'^[a-zA-Z]+').firstMatch(code.replaceAll(' ', ''));
      final dept = match?.group(0) ?? 'Unknown';

      if (!semesterMap.containsKey(semester)) {
        semesterMap[semester] = {};
      }

      if (!semesterMap[semester]!.containsKey(dept)) {
        semesterMap[semester]![dept] = [];
      }

      semesterMap[semester]![dept]!.add(course);
    }

    return semesterMap;
  }

  List<List<Map<String, dynamic>>> getSemesterData() {
    final semesterDeptMap = getCoursesBySemester();

    final sortedSemesters = semesterDeptMap.keys.toList()..sort();

    return sortedSemesters.map((semester) {
      final departments = semesterDeptMap[semester]!;

      return departments.entries.map((deptEntry) {
        return {
          'department': deptEntry.key,
          'courses':
              deptEntry.value.map((course) {
                return {
                  'code': course['code'],
                  'name': course['name'],
                  'grade': course['gpa'],
                };
              }).toList(),
        };
      }).toList();
    }).toList();
  }

  Map<int, double> getGPApersemester() {
    final Map<int, double> gpaPerSemester = {};
    final Map<int, double> totalCreditsPerSemester = {};
    final Map<int, double> totalWeightedGPA = {};

    for (final course in coursestaken) {
      if (course['gpa'] == 'W' || course['semester'] >= UserData().semester)
        continue;
      final int semester = course['semester'] ?? 0;
      final double gpa = (gpachart[course['gpa']] ?? 0.0).toDouble();
      final int credit = (course['credit'] ?? 0).toInt();

      totalCreditsPerSemester[semester] =
          (totalCreditsPerSemester[semester] ?? 0) + credit;
      totalWeightedGPA[semester] =
          (totalWeightedGPA[semester] ?? 0) + gpa * credit;
    }

    for (final semester in totalCreditsPerSemester.keys) {
      final totalCredits = totalCreditsPerSemester[semester]!;
      final totalGPA = totalWeightedGPA[semester]!;
      gpaPerSemester[semester] =
          totalCredits > 0 ? totalGPA / totalCredits : 0.0;
    }

    print(gpaPerSemester);

    return gpaPerSemester;
  }

  Map<int, double> getTScorepersemester() {
    final Map<int, double> TscorePerSemester = {};
    final Map<int, double> totalCreditsPerSemester = {};
    final Map<int, double> totalWeightedTscore = {};

    for (final course in coursestaken) {
      if (course['gpa'] == 'W' || course['semester'] >= UserData().semester)
        continue;
      final int semester = course['semester'] ?? 0;
      final double tscore = (course['t-score'] ?? 0.0).toDouble();
      final int credit = (course['credit'] ?? 0).toInt();

      totalCreditsPerSemester[semester] =
          (totalCreditsPerSemester[semester] ?? 0) + credit;
      totalWeightedTscore[semester] =
          (totalWeightedTscore[semester] ?? 0) + tscore * credit;
    }

    for (final semester in totalCreditsPerSemester.keys) {
      final totalCredits = totalCreditsPerSemester[semester]!;
      final totalTscore = totalWeightedTscore[semester]!;
      TscorePerSemester[semester] =
          totalCredits > 0 ? totalTscore / totalCredits : 0.0;
    }

    return TscorePerSemester;
  }

  String ordinal(int number) {
    if (number == 1) return '1ST';
    if (number == 2) return '2ND';
    if (number == 3) return '3RD';
    return '${number}TH';
  }

  List<Map<String, dynamic>> buildSemesterData() {
    final Map<int, Map<String, List<Map<String, dynamic>>>> semesterMap =
        getCoursesBySemester();
    print('tetst:$semesterMap');
    final Map<int, double> gpaPerSemester = getGPApersemester();
    final Map<int, double> tscorePerSemester = getTScorepersemester();
    final sortedSemesters = semesterMap.keys.toList()..sort();

    final Set<String> allRequiredCodes = allRequiredCourses.keys.toSet();
    final Map<String, Map<String, dynamic>> courseStatusMap = {
      for (var code in allRequiredCodes)
        code: {'status': 'NOT TAKEN', 'grade': '', 'color': 'grey'},
    };

    final List<Map<String, dynamic>> semesterData = [];

    for (final semester in sortedSemesters) {
      final deptCourses = semesterMap[semester]!;

      final coursesUpToThisSemester = coursestaken.where((course) {
        return course['semester'] <= semester;
      });

      for (final course in coursesUpToThisSemester) {
        final String code = course['code'];
        final grade = course['gpa'];

        final requiredCode = allRequiredCodes.firstWhere(
          (requiredCode) => code.contains(requiredCode),
          orElse: () => '',
        );

        if (requiredCode.isNotEmpty) {
          if (course['gpa'] == 'W') {
            courseStatusMap[requiredCode] = {
              'status': 'WITHDRAWED',
              'grade': grade,
              'color': 'orangeAccent',
            };
          } else if (course['gpa'] == 'D' ||
              course['gpa'] == 'E' ||
              course['gpa'] == 'X') {
            courseStatusMap[requiredCode] = {
              'status': 'FAILED',
              'grade': grade,
              'color': 'redAccent',
            };
          } else {
            courseStatusMap[requiredCode] = {
              'status': 'PASSED',
              'grade': grade,
              'color': 'greenAccent',
            };
          }
        }
      }

      final requiredStatusSnapshot = <String, Map<String, dynamic>>{};
      for (final code in courseStatusMap.keys) {
        requiredStatusSnapshot[code] = Map<String, dynamic>.from(
          courseStatusMap[code]!,
        );
      }

      final List<Map<String, dynamic>> transcript =
          deptCourses.entries.map((entry) {
            return {
              'department': entry.key,
              'courses':
                  entry.value.map((course) {
                    return {
                      'code': course['code'],
                      'name': course['name'],
                      'grade': course['gpa'],
                    };
                  }).toList(),
            };
          }).toList();

      final double gpa = gpaPerSemester[semester] ?? 0.0;
      final double tscore = tscorePerSemester[semester] ?? 0.0;

      semesterData.add({
        'semester': '${ordinal(semester)} SEMESTER',
        'gpa': gpa.toStringAsFixed(1),
        'average': convertGPAtoLetterGrade(
          double.tryParse(gpa.toStringAsFixed(1)) ?? 0,
        ),
        'tscore': '${tscore.toStringAsFixed(1)}%',
        'rank': rank[semester - 1],
        'courses': {
          'transcript': transcript,
          'requiredStatus': requiredStatusSnapshot,
        },
      });
    }

    return semesterData;
  }

  Set<String> getAllCourseNames() {
    return coursestaken
        .where(
          (course) =>
              course['gpa'] != 'W' &&
              course['gpa'] != 'X' &&
              course['gpa'] != 'D' &&
              course['gpa'] != 'E' &&
              course['semester'] < UserData().semester,
        )
        .map((course) => course['name'] as String)
        .toSet();
  }

  void clear() {
    id = '';
    name = '';
    chinese_name = '';
    gpa = 0.0;
    credits = 0;
    withdrawals = 0;
    passed = 0;
    profile = '';
    coursestaken.clear();
    recommended.clear();
    usedslot.clear();
    usedschslot.clear();
  }
}
