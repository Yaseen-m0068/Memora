import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<void> saveAssessment({
    required String userId, // email or uid
    required Assessment assessment,
    required int totalScore,
  }) async {
    final data = {
      "startedAt": assessment.startedAt,
      "completedAt": assessment.completedAt ?? Timestamp.now(),
      "language": assessment.language,
      "totalScore": totalScore,
      "responses": assessment.responses.map((r) => {
        "taskId": r.taskId,
        "score": r.score,
        "data": r.data,
      }).toList(),
    };

    await _db
        .collection("users")
        .doc(userId)
        .collection("assessments")
        .add(data);
  }
}
