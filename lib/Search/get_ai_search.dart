import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Data/api_key.dart';

import 'dart:io';

Future<String> getaisearch(
  Map<String, dynamic> requirement,
  List<Map<String, dynamic>> availablecourses,
  List<String> takenCourses,
  String query
) async {
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
You are an academic assistant for a university app. Your job is to suggest smart, helpful autocomplete suggestions as the student types a query related to their courses, grades, or graduation.

The student has typed: "$query"

Context:
- Taken courses: ${takenCourses.join(', ')}
- Available courses: ${availablecourses}
- Graduation requirements: ${requirement}

Suggest up to 5 relevant query completions or questions they might be asking. Examples:
- "What is the easiest course to fulfill [requirement]?"
- "Am I eligible to take [Course X]?"
- "Can I graduate if I take these courses?"

The questions you suggest should be the answer that you can answer from the context available.

Return only a JSON array of 5 strings like:
[
  "What is the probability of passing Linear Algebra?",
  "Courses I can take to meet the core EE requirements",
  ...
]
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
