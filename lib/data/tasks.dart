import '../models.dart';

/// Minimal spec list in the same order as the sheet pages. Fill Malayalam/English text
/// once licensed/approved by your clinician. Page refs in comments map to the PDF. :contentReference[oaicite:1]{index=1}
final List<TaskSpec> kAceTasks = [
  TaskSpec(id: "t.orientation", type: TaskType.orientation, domain: Domain.attention, max: 10, payload: {
    // date, month, year, day/season; place: floor/hospital/city/state/country (edit rubric to 18 if you use full).
    "fields": ["day","date","month","year","season","floor","hospital","city","state","country"],
  }), // p1
  TaskSpec(
    id: "t.attention.audio",
    type: TaskType.attentionAudio,
    domain: Domain.attention,
    max: 3,
    payload: {
      "words": ["lemon", "key", "ball"],
      "ttsDelayMs": 1200,
      "inputDelaySec": 10,
    },
  ),



  TaskSpec(id: "t.serial7", type: TaskType.serial7, domain: Domain.attention, max: 5, payload: {"start": 100, "steps": 7}), // p1

  TaskSpec(
    id: "t.recall3.audio",
    type: TaskType.recall3,
    domain: Domain.memory,
    max: 3,
    payload: {
      "words": ["lemon", "ball", "key"],
      "ttsDelayMs": 1200,   // delay between words
      "inputDelaySec": 5    // wait before showing text fields
    },
  ),


  TaskSpec(id: "t.fluency.letter", type: TaskType.fluencyLetter, domain: Domain.fluency, max: 7, payload: {
    "letter": "ക", // sample Malayalam letter; confirm with clinician.
    "thresholds": [ // p2: example rubric; tune to your local norms
      { "gt": 18, "score": 7 }, { "min": 14, "max": 17, "score": 6 },
      { "min": 11, "max": 13, "score": 5 }, { "min": 8, "max": 10, "score": 4 },
      { "min": 4, "max": 7, "score": 3 }, { "min": 2, "max": 3, "score": 1 },
      { "max": 1, "score": 0 }
    ]
  }), // p2

  TaskSpec(id: "t.fluency.animals", type: TaskType.fluencyAnimals, domain: Domain.fluency, max: 7, payload: {
    "category": "animals",
    "thresholds": [ // p2
      { "gt": 22, "score": 7 }, { "min": 17, "max": 21, "score": 6 },
      { "min": 14, "max": 16, "score": 5 }, { "min": 11, "max": 13, "score": 4 },
      { "min": 9, "max": 10, "score": 3 }, { "min": 5, "max": 8, "score": 2 },
      { "max": 4, "score": 1 }
    ]
  }), // p2

  TaskSpec(
    id: "t.nameaddr.learn",
    type: TaskType.nameAddressLearn,
    domain: Domain.memory,
    max: 0, // ⚠️ No score at learning stage
    payload: {
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
max: 4,
payload: {
"questions": [
"Who is the Prime Minister of India?",
"Who is the President of India?",
"Who is the Chief Minister of your state?",
"Who is the Father of the Nation?",
]
},
), // p3

  TaskSpec(
    id: 'language_comprehension',
    type: TaskType.comprehension,
    domain: Domain.language,
    max: 3,
    payload: {
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
// p3

  TaskSpec(id: "t.sentence", type: TaskType.sentenceWriting, domain: Domain.language, max: 5),

  TaskSpec(id: "t.word.rep", type: TaskType.wordRepetition, domain: Domain.language, max: 2, payload: {
    "words": ["—","—"] // p4: add short ML words once licensed.
  }),

  TaskSpec(id: "t.proverb.rep", type: TaskType.proverbRepetition, domain: Domain.language, max: 2, payload: {
    "proverbs": ["—","—"] // p4: add ML proverbs once licensed.
  }),

  TaskSpec(id: "t.object.naming", type: TaskType.objectNaming, domain: Domain.language, max: 12, payload: {
    "imagePaths": List.generate(12, (i) => "assets/pictures/obj_${i+1}.png") // p5 placeholders
  }),

  TaskSpec(id: "t.multi.step", type: TaskType.multiStepCommand, domain: Domain.language, max: 4, payload: {
    "steps": 4 // p5
  }),

  TaskSpec(id: "t.reading", type: TaskType.readingWords, domain: Domain.language, max: 1, payload: {
    "words": ["സജ്ജ","സുന്ദരി","ഫലితం","ഉഷ്ണം","ബ്രഹ്മാണ്ഡം"] // p6 sample lines; match your sheet.
  }),

  TaskSpec(id: "t.loops", type: TaskType.loopsTracing, domain: Domain.visuospatial, max: 1),

  TaskSpec(id: "t.cube", type: TaskType.cubeCopy, domain: Domain.visuospatial, max: 2),

  TaskSpec(id: "t.dots", type: TaskType.countDots, domain: Domain.visuospatial, max: 4, payload: {
    "answers": [8,10,9,7] // p7 explicitly printed on sheet.
  }), // :contentReference[oaicite:2]{index=2}

  TaskSpec(id: "t.clock", type: TaskType.clockDraw, domain: Domain.visuospatial, max: 5, payload: {"time": "5:10"}), // p8

  TaskSpec(id: "t.hunt", type: TaskType.huntingLetters, domain: Domain.perceptual /* map to visuospatial if you prefer */, max: 2, payload: {
    "imagePaths": List.generate(4, (i) => "assets/pictures/hunt_${i+1}.png")
  }), // p8

  TaskSpec(id: "t.nameaddr.delayed", type: TaskType.nameAddressDelayed, domain: Domain.memory, max: 7),
  TaskSpec(id: "t.nameaddr.recog", type: TaskType.nameAddressRecognize, domain: Domain.memory, max: 5),
];
