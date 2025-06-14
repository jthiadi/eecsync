import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Data/api_key.dart';
import '../Data/UserData.dart';

import 'dart:io';

Future<String> getalternative_response(
  Map<String, dynamic> requirement,
  List<Map<String, dynamic>> availablecourses,
  List<String> takenCourses,
  Map<String,dynamic> course,
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
    You are an academic advisor assistant. Your job is to recommend an alternative course from the available course list that is similar to ${course}.
    - Do NOT recommend already taken courses (the course with the same letter id and with the same first 4 number digit eg CS 355021 is the same as CS 355035).
    - Only recommend the needed one (eg if the requirement stated EE 2310 or CS 1355 and the user has taken course with prefix EE 2310, do not recommend the course with prefix CS 1355 since the credit will not be counted)
    - Prioritize fulfilling graduation requirements based on the urgency of each requirement. (first priority)
    - If a course code starts with a required prefix, it counts toward that requirement.
    - Professional course is the last priority among other requirements

    Here are the student's interest:
    ${UserData().preferences}
  
    Here are the available courses:
    ${availablecourses}
  
    Here are the courses already taken:
    ${takenCourses.join(', ')}
    (W means the student withdraw from the class in the middle of the semester which means its not counted toward the record)
    
    If you want to check the name of the courses taken from the code, you can refer to the available course which gives more detailed info.
    If the name is unknown than just refer to the course id.
    
    Graduation requirements are as follows (the first array of every requirement is the number of credits needed for that requirement and the rest is the course code 
    prefix of the course neeeded in the requirement (for professional courses, any courses provided by EECS, EE, CS, COM, ENE, IPT, ISA, IIS)):
    ${requirement}
      
    Based on this information, suggest an alternative course from the courses available given that could be suitable for this student. 
    If there are no similar course, just pick a course that would suit the student's need (it must be in the available course list).
    Please respond strictly with only a JSON of exactly the course codes (no other text, no Markdown formatting, no code blocks, only the raw JSON):

     "Course code"
    
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
