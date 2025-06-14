import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Data/api_key.dart';

import 'dart:io';

Future<String> aisimilarresponse(
  Map<String, dynamic> job,
  List<Map<String, dynamic>> availableJobs,
) async {
  print('testt:$availableJobs');
  final endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';

  try {
    final url = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/chat-bison-001:generateMessage',
    );
    final request = await HttpClient().getUrl(url);
    final response = await request.close();
    print("AVAILABLE: $availableJobs");
  } catch (e) {
    print('❌ Connection failed: $e');
  }

  final prompt = '''
    You are an academic advisor assistant. Your task is to recommend up to 3 similar job positions to the following job: ${job}

    You must choose from the following list of available jobs:
    ${availableJobs}

    Use the following scoring system to evaluate how similar each job is to the given job. The higher the total score, the higher the job should be ranked in the result:

    - +4 points: Job has a similar or closely matching English title.
    - +4 points: Job is taught by the same professor (exact match on full name).
    - +1 point for each matching prerequisite (based on the list: ${job['qualifications']['prerequisites']}). If the prerequisite list is empty, skip this criterion.
    - +2 point: Job has the same major prefix (i.e., if course code contains "CS", other "CS" jobs get this point).

    🛑 Do NOT include the original job (${job['code']}) in the recommendations.

    Output exactly 3 recommended job codes with the highest total scores based on the criteria above.

    Respond strictly with only a JSON array of exactly the job codes (no other text, no Markdown formatting, no code blocks, only the raw JSON array):

     [
      "Job Code 1",
      "Job Code 2",
      "Job Code 3",
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
    print(data);
    return data['candidates'][0]['content']['parts'][0]['text'];
  } else {
    print('❌ Status code: ${response.statusCode}');
    print('❌ Response body: ${response.body}');
    throw Exception('failed to get response');
  }
}
