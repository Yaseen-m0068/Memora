import '../models.dart';

final List<TaskSpec> kAceTasks = [

  TaskSpec(
    id: "t.orientation",
    type: TaskType.orientation,
    domain: Domain.attention,
    maxScore: 10,
    meta: {
      "fields": ["day","date","month","year","season","floor","hospital","city","state","country"],
    },
  ),

  TaskSpec(
    id: "t.attention.audio",
    type: TaskType.attentionAudio,
    domain: Domain.attention,
    maxScore: 3,
    meta: {
      "words": ["lemon", "key", "ball"],
      "ttsDelayMs": 1200,
      "inputDelaySec": 10,
    },
  ),

  TaskSpec(
    id: "serial7",
    type: TaskType.serial7,
    domain: Domain.attention,
    maxScore: 5,
    meta: {
      "start": 100,
      "step": 7,
    },
  ),

  TaskSpec(
    id: "recall3",
    type: TaskType.recall3,
    domain: Domain.memory,
    maxScore: 3,
    meta: {
      "target": ["apple", "penny", "table"]
    },
  ),

  TaskSpec(
    id: "t.fluency.letter",
    type: TaskType.fluencyLetter,
    domain: Domain.fluency,
    maxScore: 7,
    meta: {
      "thresholds": [
        { "gt": 18, "score": 7 },
        { "min": 14, "max": 17, "score": 6 },
        { "min": 11, "max": 13, "score": 5 },
        { "min": 8, "max": 10, "score": 4 },
        { "min": 4, "max": 7, "score": 3 },
        { "min": 2, "max": 3, "score": 1 },
        { "max": 1, "score": 0 }
      ]
    },
  ),

  TaskSpec(
    id: "t.fluency.animals",
    type: TaskType.fluencyAnimals,
    domain: Domain.fluency,
    maxScore: 7,
    meta: {
      "category": "animals",
      "thresholds": [
        { "gt": 22, "score": 7 },
        { "min": 17, "max": 21, "score": 6 },
        { "min": 14, "max": 16, "score": 5 },
        { "min": 11, "max": 13, "score": 4 },
        { "min": 9, "max": 10, "score": 3 },
        { "min": 5, "max": 8, "score": 2 },
        { "max": 4, "score": 1 }
      ]
    },
  ),

  TaskSpec(
    id: "t.nameaddr.learn",
    type: TaskType.nameAddressLearn,
    domain: Domain.memory,
    maxScore: 0,
    meta: {
      "instruction":
      "Please read and remember the name and address below.\nYou will be asked to recall it later in the test.",
      "elements": [
        "Velayudhan Thampi",
        "42 Kovil Road",
        "Chengamanad",
        "Ernakulam",
      ],
    },
  ),

  TaskSpec(
    id: "t.famous",
    type: TaskType.famousPeople,
    domain: Domain.language,
    maxScore: 4,
    meta: {
      "questions": [
        "Who is the Prime Minister of India?",
        "Who is the President of India?",
        "Who is the Chief Minister of your state?",
        "Who is the Father of the Nation?",
      ]
    },
  ),

  TaskSpec(
    id: "language_comprehension",
    type: TaskType.comprehension,
    domain: Domain.language,
    maxScore: 3,
    meta: {
      "questions": [
        {
          "instruction": "Which one is used to write?",
          "options": ["Spoon", "Pen", "Plate"],
          "answer": "Pen",
        },
        {
          "instruction": "Which one do we wear on the foot?",
          "options": ["Hat", "Shoe", "Glove"],
          "answer": "Shoe",
        },
        {
          "instruction": "Which one shows time?",
          "options": ["Clock", "Book", "Bottle"],
          "answer": "Clock",
        },
      ]
    },
  ),

  TaskSpec(
    id: "t.sentence",
    type: TaskType.sentenceWriting,
    domain: Domain.language,
    maxScore: 5,
  ),

  TaskSpec(
    id: "t.word.rep",
    type: TaskType.wordRepetition,
    domain: Domain.language,
    maxScore: 2,
    meta: {"words": ["—","—"]},
  ),

  TaskSpec(
    id: "t.proverb.rep",
    type: TaskType.proverbRepetition,
    domain: Domain.language,
    maxScore: 2,
    meta: {"proverbs": ["—","—"]},
  ),

  TaskSpec(
    id: "t.object.naming",
    type: TaskType.objectNaming,
    domain: Domain.language,
    maxScore: 12,
    meta: {
      "imagePaths": List.generate(12, (i) => "assets/pictures/obj_${i+1}.png")
    },
  ),

  TaskSpec(
    id: "t.multi.step",
    type: TaskType.multiStepCommand,
    domain: Domain.language,
    maxScore: 4,
    meta: {"steps": 4},
  ),

  TaskSpec(
    id: "t.reading",
    type: TaskType.readingWords,
    domain: Domain.language,
    maxScore: 1,
    meta: {"words": ["സജ്ജ","സുന്ദരി","ഫലితం","ഉഷ്ണം","ബ്രഹ്മാണ്ഡം"]},
  ),

  TaskSpec(
    id: "t.loops",
    type: TaskType.loopsTracing,
    domain: Domain.visuospatial,
    maxScore: 1,
  ),

  TaskSpec(
    id: "t.cube",
    type: TaskType.cubeCopy,
    domain: Domain.visuospatial,
    maxScore: 2,
  ),

  TaskSpec(
    id: "countDots",
    type: TaskType.countDots,
    domain: Domain.visuospatial,
    maxScore: 5,
    meta: {
      "answers": [5, 8, 12]
    },
  ),

  TaskSpec(
    id: "t.clock",
    type: TaskType.clockDraw,
    domain: Domain.visuospatial,
    maxScore: 5,
    meta: {"time": "5:10"},
  ),

  TaskSpec(
    id: "t.hunt",
    type: TaskType.huntingLetters,
    domain: Domain.perceptual,
    maxScore: 2,
    meta: {
      "imagePaths": List.generate(4, (i) => "assets/pictures/hunt_${i+1}.png")
    },
  ),

  TaskSpec(
    id: "t.nameaddr.delayed",
    type: TaskType.nameAddressDelayed,
    domain: Domain.memory,
    maxScore: 7,
  ),

  TaskSpec(
    id: "t.nameaddr.recog",
    type: TaskType.nameAddressRecognize,
    domain: Domain.memory,
    maxScore: 5,
  ),
];