import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

List<String> courses = [
  'Logic Design',
  'Introduction to Programming I',
  'Introduction to Programming II',
  'Probability',
  'Linear Algebra',
  'Calculus I',
  'Calculus II',
  'Operating Systems',
  'Software Studio',
  'Data Structures',
  'Discrete Mathematics',
  'Computer Architecture',
  'Signal and Systems',
  'Introduction to Computer Networks',
  'Electric Circuits',
  'Algorithms',
  'Machine Learning',
];

String normalize(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[,-]'), ' ')
      .replaceAll(RegExp(r'[^\w\s]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

Future<List<String>> getSearchRecommendations(String query) async {
  final firestore = FirebaseFirestore.instance;
  final questionsCollection = firestore.collection('Questions');
  final lowerQuery = normalize(query);

  final snapshot = await questionsCollection.get();

  List<MapEntry<String, int>> scoredResults = [];

  for (final doc in snapshot.docs) {
    String text = doc.data()['text']?.toString() ?? '';
    String normalizedText = normalize(text);

    if (!normalizedText.contains(lowerQuery)) continue;

    text = _replaceCoursePlaceholders(text);

    int score = 0;

    if (normalizedText == lowerQuery) {
      score += 100;
    } else if (normalizedText.contains(lowerQuery)) {
      score += 50;
    } else {
      List<String> queryWords = lowerQuery.split(' ');
      List<String> textWords = normalizedText.split(' ');

      for (String word in queryWords) {
        if (textWords.contains(word)) {
          score += 10;
        }
      }
    }

    if (score > 0) {
      scoredResults.add(MapEntry(text, score));
    }
  }

  // if (scoredResults.isEmpty) {
  //   for (final doc in snapshot.docs) {
  //     String text = doc.data()['text']?.toString() ?? '';
  //     String normalizedText = normalize(text);

  //     for (String word in lowerQuery.split(' ')) {
  //       if (normalizedText.contains(word)) {
  //         text = _replaceCoursePlaceholders(text);
  //         scoredResults.add(MapEntry(text, 5));
  //         break;
  //       }
  //     }
  //   }
  // }

  scoredResults.sort((a, b) => b.value.compareTo(a.value));

  return scoredResults.take(5).map((e) => e.key).toList();
}

String _replaceCoursePlaceholders(String text) {
  final random = Random();
  if (text.contains('[course]')) {
    text = text.replaceAll('[course]', courses[random.nextInt(courses.length)]);
  }
  if (text.contains('[course1]')) {
    text = text.replaceAll(
      '[course1]',
      courses[random.nextInt(courses.length)],
    );
  }
  if (text.contains('[course2]')) {
    text = text.replaceAll(
      '[course2]',
      courses[random.nextInt(courses.length)],
    );
  }
  return text;
}

String getFirstWord(String input) {
  List<String> words = input.trim().split(RegExp(r'\s+'));
  return words[0];
}

String getFromSecondWord(String input) {
  List<String> words = input.trim().split(RegExp(r'\s+'));
  if (words.length <= 1) return "";
  return words.sublist(1).join(' ');
}

String extractCourseCode(String courseName) {
  RegExp regex = RegExp(r'\((.*?)\)');
  final matches = regex.allMatches(courseName);
  if (matches.isEmpty) return '';

  String rawCode = matches.last.group(1) ?? '';

  return rawCode.replaceAll(RegExp(r'\s+'), ' ').trim();
}

Future<List<String>> getNormalRecommendations(String query, String cat) async {
  final firestore = FirebaseFirestore.instance;
  final questionsCollection = firestore.collection('Search');
  final normalizedQuery = normalize(query);

  final snapshot = await questionsCollection.get();

  List<MapEntry<String, int>> scoredResults = [];

  if (query.isNotEmpty) {
    for (final doc in snapshot.docs) {
      String text = doc.data()['text']?.toString() ?? '';
      String firstWord = getFirstWord(text);
      String normalizedText = normalize(text);
      //print('$normalizedQuery $normalizedText');

      if (!cat.contains(firstWord)) continue;

      int score = 0;

      if (normalizedText == normalizedQuery) {
        score += 100;
      } else if (normalizedText.contains(normalizedQuery)) {
        score += 50;
      } else {
        List<String> queryWords = normalizedQuery.split(' ');
        List<String> textWords = normalizedText.split(' ');

        for (String word in queryWords) {
          if (textWords.contains(word)) {
            score += 10;
          }
        }
      }

      if (score > 0) {
        scoredResults.add(MapEntry(text, score));
      }
    }

    scoredResults.sort((a, b) => b.value.compareTo(a.value));

    List<String> matchingTexts = scoredResults.map((e) => e.key).toList();

    // if (matchingTexts.isEmpty) {
    //   for (final doc in snapshot.docs) {
    //     String text = doc.data()['text']?.toString() ?? '';
    //     String firstWord = getFirstWord(text);
    //     if (cat.contains(firstWord)) {
    //       matchingTexts.add(text);
    //     }
    //   }
    // }

    return matchingTexts.take(5).toList();
  } else {
    List<String> matchingTexts = [];
    for (final doc in snapshot.docs) {
      String text = doc.data()['text']?.toString() ?? '';
      String firstWord = getFirstWord(text);
      if (cat.contains(firstWord)) {
        matchingTexts.add(text);
      }
    }
    matchingTexts.shuffle(Random());
    return matchingTexts.take(5).toList();
  }
}
