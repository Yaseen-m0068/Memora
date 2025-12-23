import 'models.dart';

class Scorebook {
  final Map<Domain, int> domainTotals = {
    Domain.attention: 0, Domain.memory: 0, Domain.fluency: 0,
    Domain.language: 0, Domain.visuospatial: 0,
  };
  int get total => domainTotals.values.fold(0, (a, b) => a + b);

  void add(Domain d, int s) => domainTotals[d] = (domainTotals[d] ?? 0) + s;
}

int scoreFluency(Map<String, dynamic> payload, int producedCount) {
  // thresholds array with gt/min/max like in tasks.dart
  for (final t in (payload["thresholds"] as List)) {
    if (t.containsKey("gt") && producedCount > t["gt"]) return t["score"];
    if (t.containsKey("min") && t.containsKey("max") &&
        producedCount >= t["min"] && producedCount <= t["max"]) return t["score"];
    if (t.containsKey("max") && producedCount <= t["max"]) return t["score"];
  }
  return 0;
}

int scoreDots(List<int?> user, List<dynamic> answers) {
  int s = 0;
  for (var i = 0; i < answers.length; i++) {
    if (i < user.length && user[i] == answers[i]) s++;
  }
  return s; // p7: 8,10,9,7 on the sheet. :contentReference[oaicite:3]{index=3}
}
