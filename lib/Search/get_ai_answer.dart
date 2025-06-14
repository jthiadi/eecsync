import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Data/api_key.dart';
import '../Data/UserData.dart';

import 'dart:io';

Future<String> getaianswer(
  Map<String, dynamic> requirement,
  List<Map<String, dynamic>> availablecourses,
  List<String> takenCourses,
  List<Map<String, dynamic>> jobsavailable,
  String question,
) async {
  print(availablecourses);
  final endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';

  try {
    final url = Uri.http('generativelanguage.googleapis.com', '/');
    final request = await HttpClient().getUrl(url);
    final response = await request.close();
    print('✅ Connected: ${response.statusCode}');
  } catch (e) {
    print('❌ Connection failed: $e');
  }

  final prompt = '''
You are an academic assistant for a National Tsing Hua University app. Your job is to answer student's question related to their courses, grades, job applications, or graduation.

The student's question is: "$question"

Context:
- Taken courses: ${takenCourses.join(', ')}
- Available courses: ${availablecourses}
- Graduation requirements: ${requirement}
- The student's preference: ${UserData().preferences}
- the gpa chart is:
  'A+': 4.3,
  'A': 4.0,
  'A-': 3.7,
  'B+': 3.3,
  'B': 3.0,
  'B-': 2.7,
  'C+': 2.3,
  'C': 2.0,
  'C-': 1.7,
  'D': 1.0,
  'E': 0.0,
  'X': 0.0,
  'W': means they withdrawed in the middle of the semester, so its not counted
  The passing grade is C-
- Available jobs: ${jobsavailable};

Be personalized - Answer based on the user's data given in the context above
Be concise – Give short, direct answers.
Stay on topic – Only answer based on available info; don’t speculate.
User-friendly language – Keep explanations simple and clear.
Avoid disclaimers – Skip phrases like "based on available info" or "we don’t know."
Prioritize actionable fixes – Lead with solutions, not just explanations.
If listing courses, use course names instead of codes.
Never answer anything that implies uncertainty about our data.
Don't answer anything that cannot be answered using the context provided.
For questions regarding job applications, you need to follow the job's applications qualification compared to the student's taken courses to get the qualification. Also consider the status of other applicants and number of slot available.
Give a rough percentage of probability for questions regarding job applications.
Only answer related to the question.
''';

  final headers = {'Content-Type': 'application/json'};

  final body = jsonEncode({
    "contents": [
      {
        "parts": [
          {"text": prompt},
        ],
      },
    ],
  });

  final response = await http.post(
    Uri.parse(endpoint),
    headers: headers,
    body: body,
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['candidates'][0]['content']['parts'][0]['text'];
  } else {
    print('❌ Status code: ${response.statusCode}');
    print('❌ Response body: ${response.body}');
    throw Exception('failed to get response');
  }
}
