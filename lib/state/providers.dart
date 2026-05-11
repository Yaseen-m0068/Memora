import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';

class AssessmentController extends StateNotifier<Assessment> {
  AssessmentController()
      : super(
    Assessment(
      id: const Uuid().v4(),
      language: "ml",
      startedAt: DateTime.now(),
      responses: [],
    ),
  );

  void addResponse(ResponseModel response) {
    state = state.copyWith(
      responses: [...state.responses, response],
    );
  }

  Assessment get current => state;
}
final assessmentProvider = StateProvider<Assessment>((ref) {
  return Assessment(
    id: const Uuid().v4(),
    language: "ml",
    startedAt: DateTime.now(),
  );
});
