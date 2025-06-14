import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/Data/api_key.dart';

Future<void> generateAndUploadSyllabi() async {
  final firestore = FirebaseFirestore.instance;
  final endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';

  try {
    final querySnapshot = await firestore.collection('Course').get();

    for (final doc in querySnapshot.docs) {
      final courseId = doc.id;

      if (!courseId.startsWith('11320CLC')&&!courseId.startsWith('11320GE')&&!courseId.startsWith('11320GEC')) continue;

      final courseData = doc.data();

      final String title = courseData['english_title'] ??
          courseData['chinese_title'] ??
          "Unnamed Course";

      final prompt = '''
You are an AI assistant helping to draft National Tsing Hua University course syllabi.

Based on the course title: "$title", generate a syllabus strictly in this structure example (no need to follow the content) (the course is 16 weeks) (just write each cahpters, no need to write course title or course description):

CHAP1: INTRODUCTION TO DATABASE SYSTEMS
CHAP2: DATA MODELS
CHAP3: RELATIONAL MODEL
CHAP4: SQL
CHAP5: DATABASE DESIGN
CHAP6: NORMALIZATION
CHAP7: ER DIAGRAMS
CHAP8: TRANSACTION MANAGEMENT
CHAP9: ACID PROPERTIES
CHAP10: CONCURRENCY CONTROL
CHAP11: DATABASE SECURITY
CHAP12: DATA WAREHOUSING
CHAP13: DATA MINING
CHAP14: NOSQL DATABASES

rules:
no additional message to add, STRICTLY FOLLOW THE SHOWED FORMAT
the description should only be very short, not long description
add newline after each criteria
the syllabus should be based on the course name 
''';

      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      });

      final headers = {'Content-Type': 'application/json'};

      try {
        print('Generating grading for $courseId...');

        final response = await http.post(
          Uri.parse(endpoint),
          headers: headers,
          body: body,
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content =
              data['candidates'][0]['content']['parts'][0]['text'];

          await firestore.collection('Course').doc(courseId).update({
            'syllabus': content,
          });

          print('✅ Grading added for $courseId');
        } else {
          print('❌ Failed for $courseId — HTTP ${response.statusCode}');
          print('Response: ${response.body}');
        }
      } catch (e) {
        print('🔥 Error generating grading for $courseId: $e');
      }
    }

    print('🎉 Finished processing all applicable courses.');
  } catch (e) {
    print('❗ Firestore error: $e');
  }
}
