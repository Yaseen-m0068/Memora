// lib/scoring.dart
import 'models.dart';

class Scorebook {
  final Map<String, int> _domainScores = {};

  void add(Domain domain, int? score) {
    final key = domain.name;
    _domainScores[key] = (_domainScores[key] ?? 0) + (score ?? 0);
  }

  int getDomainScore(Domain domain) {
    return _domainScores[domain.name] ?? 0;
  }

  int get total {
    return _domainScores.values.fold(0, (a, b) => a + b);
  }
}

/// ===============================
/// BASIC HELPERS
/// ===============================

bool _isSentenceLike(String s) {
  if (s.trim().length < 5) return false;
  final hasVerb = RegExp(r'\b(is|was|were|went|had|have|enjoyed|visited|saw)\b',
      caseSensitive: false)
      .hasMatch(s);
  final startsWithCapital =
      s.trim().isNotEmpty && s.trim()[0].toUpperCase() == s.trim()[0];
  final endsWithPunctuation =
      s.trim().endsWith('.') || s.trim().endsWith('!');

  return hasVerb && startsWithCapital && endsWithPunctuation;
}

/// ===============================
/// ATTENTION / SERIAL 7
/// ===============================

int scoreSerial7(List<int?> user, int start, int step) {
  int score = 0;
  int current = start;

  for (final ans in user) {
    current -= step;
    if (ans == current) score++;
  }
  return score;
}

/// ===============================
/// WORD RECALL (3 words)
/// ===============================

int scoreRecall3(List<String> user, List<String> target) {
  final t = target.map((e) => e.toLowerCase()).toSet();
  int score = 0;
  for (final u in user) {
    if (t.contains(u.toLowerCase())) score++;
  }
  return score;
}

/// ===============================
/// FLUENCY
/// ===============================

int scoreFluency(Map? payload, int count) {
  if (count <= 0) return 0;
  
  final thresholds = payload?['thresholds'] as List?;
  if (thresholds != null) {
    for (final t in thresholds) {
      final map = t as Map<dynamic, dynamic>;
      final scoreVal = map['score'] as int;
      
      bool match = true;
      if (map.containsKey('gt') && count <= (map['gt'] as int)) match = false;
      if (map.containsKey('min') && count < (map['min'] as int)) match = false;
      if (map.containsKey('max') && count > (map['max'] as int)) match = false;
      
      if (match) return scoreVal;
    }
  }
  
  // Fallback for custom ranges or missing thresholds
  if (count >= 15) return 7;
  if (count >= 12) return 5;
  if (count >= 8) return 3;
  if (count >= 4) return 1;
  return 0;
}

/// ===============================
/// COUNT DOTS
/// ===============================

int scoreDots(List<int?> user, List<int> answers) {
  int score = 0;
  for (int i = 0; i < answers.length; i++) {
    if (i < user.length && user[i] == answers[i]) score++;
  }
  return score;
}

/// ===============================
/// SENTENCE WRITING (NEW)
/// ===============================

int scoreSentenceWriting(
    String s1,
    String s2, {
      required int maxScore,
    }) {
  int score = 0;

  if (_isSentenceLike(s1)) score += 2;
  if (_isSentenceLike(s2)) score += 2;

  // Bonus for relevance keywords
  final combined = (s1 + " " + s2).toLowerCase();
  if (combined.contains('holiday') ||
      combined.contains('trip') ||
      combined.contains('travel') ||
      combined.contains('vacation')) {
    score += 1;
  }

  return score.clamp(0, maxScore);
}

/// ===============================
/// COMPREHENSION (MCQ)
/// ===============================

int scoreComprehension(
    List<String> userAnswers,
    List<String> correctAnswers,
    ) {
  int score = 0;
  for (int i = 0; i < userAnswers.length; i++) {
    if (userAnswers[i] == correctAnswers[i]) score++;
  }
  return score;
}
