import 'package:hive/hive.dart';
part 'CourseData.g.dart';

@HiveType(typeId: 1)
class CourseData extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int credit;

  @HiveField(3)
  String professor;

  @HiveField(4)
  String? classTime;

  @HiveField(5)
  String? location;

  @HiveField(6)
  String? syllabus;

  @HiveField(7)
  String? grading;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'credit': credit,
      'professor': professor,
      'classTime': classTime,
      'location': location,
      'syllabus': syllabus,
      'grading': grading,
    };
  }

  CourseData({
    required this.id,
    required this.name,
    required this.credit,
    required this.professor,
    this.classTime,
    this.location,
    this.syllabus,
    this.grading,
  });
}