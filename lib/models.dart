// Basic data shapes for tasks, responses, and assessment
enum Domain { attention, memory, fluency, language, visuospatial, perceptual }

enum TaskType {
  orientation,
  attentionAudio,// p1
  serial7,           // p1
  recall3,            // p2
  fluencyLetter,      // p2
  fluencyAnimals,     // p2
  nameAddressLearn,   // p3 + delayed p9
  famousPeople,       // p3
  comprehension,      // p3
  sentenceWriting,    // p4
  wordRepetition,     // p4
  proverbRepetition,  // p4
  objectNaming,       // p5 (requires licensed images)
  multiStepCommand,   // p5 bottom
  readingWords,       // p6
  loopsTracing,       // p6
  cubeCopy,           // p6
  countDots,          // p7 answers 8,10,9,7
  clockDraw,          // p8 time 5:10
  huntingLetters,     // p8 (requires licensed images)
  nameAddressDelayed, // p9
  nameAddressRecognize// p9
}

class TaskSpec {
  final String id;
  final TaskType type;
  final Domain domain;
  final int max;
  final Map<String, dynamic> payload;
  const TaskSpec({
    required this.id, required this.type, required this.domain,
    required this.max, this.payload = const {},
  });
}

class ResponseModel {
  final String taskId;
  final Map<String, dynamic> data;
  final int score;
  const ResponseModel({required this.taskId, required this.data, required this.score});
}

class Assessment {
  final String id;
  final String language; // "en" | "ml"
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<ResponseModel> responses;
  const Assessment({
    required this.id, required this.language, required this.startedAt,
    this.completedAt, this.responses = const [],
  });

  Assessment copyWith({List<ResponseModel>? responses, DateTime? completedAt}) => Assessment(
      id: id, language: language, startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt, responses: responses ?? this.responses);
}
