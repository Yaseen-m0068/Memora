import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // for Ticker
import '../models.dart';
import '../scoring.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';


/// ========== COMMON MINI HELPERS ==========

Widget _padded(Widget child) => Padding(padding: const EdgeInsets.all(12), child: child);

int _clampScore(int v, int max) => v < 0 ? 0 : (v > max ? max : v);

/// Simple labeled slider scorer
class _ScoreSlider extends StatefulWidget {
  final int max;
  final void Function(int) onSet;
  final String? label;
  const _ScoreSlider({required this.max, required this.onSet, this.label});
  @override
  State<_ScoreSlider> createState() => _ScoreSliderState();
}
class _ScoreSliderState extends State<_ScoreSlider> {
  int s = 0;
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (widget.label != null) Text(widget.label!),
      Slider(
        value: s.toDouble(),
        min: 0,
        max: widget.max.toDouble(),
        divisions: widget.max,
        label: '$s',
        onChanged: (v) => setState(() => s = v.round()),
      ),
      FilledButton(onPressed: () => widget.onSet(s), child: const Text('Next')),
    ]);
  }
}

/// ========== ORIENTATION (auto-score per non-empty for demo) ==========
class OrientationTask extends StatefulWidget {
  final TaskSpec spec;
  final void Function(int, Map<String, dynamic>) onDone;
  const OrientationTask({super.key, required this.spec, required this.onDone});
  @override
  State<OrientationTask> createState() => _OrientationTaskState();
}
class _OrientationTaskState extends State<OrientationTask> {
  late final List<String> fields =
  (widget.spec.payload['fields'] as List).cast<String>();
  late final List<TextEditingController> ctrls =
  List.generate(fields.length, (_) => TextEditingController());

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Text('Orientation'),
      Expanded(
        child: ListView.separated(
          itemCount: fields.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => TextField(
            controller: ctrls[i],
            decoration: InputDecoration(labelText: fields[i], border: const OutlineInputBorder()),
          ),
        ),
      ),
      FilledButton(
        onPressed: () {
          int score = 0;
          for (final c in ctrls) {
            if (c.text.trim().isNotEmpty) score++;
          }
          score = _clampScore(score, widget.spec.max);
          widget.onDone(score, {
            "answers": List.generate(ctrls.length, (i) => {fields[i]: ctrls[i].text.trim()}),
          });
        },
        child: const Text('Next'),
      ),
    ]);
  }
}
/// ========== ATTENTION (auto-score per non-empty for demo) ==========


class AttentionAudioTask extends StatefulWidget {
  final TaskSpec spec;
  final void Function(int, Map<String, dynamic>) onDone;

  const AttentionAudioTask({
    super.key,
    required this.spec,
    required this.onDone,
  });

  @override
  State<AttentionAudioTask> createState() => _AttentionAudioTaskState();
}

class _AttentionAudioTaskState extends State<AttentionAudioTask> {
  final FlutterTts _tts = FlutterTts();
  final ctrls = List.generate(3, (_) => TextEditingController());

  bool showInputs = false;
  bool spoken = false;

  @override
  void initState() {
    super.initState();
    _playWords();
  }

  Future<void> _playWords() async {
    final words = (widget.spec.payload['words'] as List).cast<String>();

    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.4);

    for (int i = 0; i < words.length; i++) {
      await _tts.speak(words[i]);

      // ✅ 2-second gap ONLY between words
      if (i != words.length - 1) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    // ✅ immediately allow input after last word
    setState(() {
      spoken = true;
      showInputs = true;
    });
  }


  @override
  void dispose() {
    _tts.stop();
    for (final c in ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = (widget.spec.payload['words'] as List).cast<String>();

    return _padded(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Listen carefully to the words.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),

        if (!spoken)
          const Text('🔊 Playing words…')
        else if (!showInputs)
          const Text('⏱ Please wait…'),

        if (showInputs) ...[
          const SizedBox(height: 12),
          const Text('Enter the words you heard:'),
          const SizedBox(height: 8),

          for (int i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: TextField(
                controller: ctrls[i],
                decoration: InputDecoration(
                  labelText: 'Word ${i + 1}',
                  border: const OutlineInputBorder(),
                ),
              ),
            ),

          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => _finish(words),
            child: const Text('Next'),
          ),
        ]
      ],
    ));
  }

  void _finish(List<String> target) {
    final user = ctrls.map((c) => c.text.trim().toLowerCase()).toList();
    final tgt = target.map((e) => e.toLowerCase()).toList();

    int score = 0;
    for (final u in user) {
      if (tgt.contains(u)) score++;
    }

    widget.onDone(
      score,
      {
        "target": tgt,
        "user": user,
        "instruction": "Remember these words. You will be asked again later.",
      },
    );
  }
}



/// ========== SERIAL 7s (auto) ==========
class Serial7 extends StatefulWidget {
  final TaskSpec spec;
  final void Function(int, Map<String, dynamic>) onDone;
  const Serial7({super.key, required this.spec, required this.onDone});

  @override
  State<Serial7> createState() => _Serial7State();
}

class _Serial7State extends State<Serial7> {
  final List<TextEditingController> ctrls =
  List.generate(5, (_) => TextEditingController());

  @override
  void dispose() {
    for (final c in ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _padded(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Starting from 100, subtract 7 each time.\nEnter each answer in order.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),

        // ✅ Five clear input boxes
        ...List.generate(5, (i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: TextField(
            controller: ctrls[i],
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Answer ${i + 1}',
              border: const OutlineInputBorder(),
            ),
          ),
        )),

        const Spacer(),

        FilledButton(
          onPressed: _submit,
          child: const Text('Next'),
        ),
      ],
    ));
  }

  void _submit() {
    int score = 0;
    int current = widget.spec.payload['start'] as int;
    final step = widget.spec.payload['steps'] as int;

    final userAnswers = <int?>[];

    for (int i = 0; i < 5; i++) {
      current -= step;
      final val = int.tryParse(ctrls[i].text.trim());
      userAnswers.add(val);

      if (val == current) {
        score++;
      }
    }

    widget.onDone(
      score,
      {
        "userAnswers": userAnswers,
        "max": 5,
      },
    );
  }
}

/// ========== RECALL 3 (auto — exact word match, case-insensitive) ==========
class Recall3Task extends StatefulWidget {
  final TaskSpec spec;
  final void Function(int, Map<String, dynamic>) onDone;
  const Recall3Task({super.key, required this.spec, required this.onDone});
  @override
  State<Recall3Task> createState() => _Recall3TaskState();
}
class _Recall3TaskState extends State<Recall3Task> {
  final ctrls = List.generate(3, (_) => TextEditingController());
  @override
  Widget build(BuildContext context) {
    final words = (widget.spec.payload['words'] as List).cast<String>();
    return _padded(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Recall the three words:'),
      const SizedBox(height: 8),
      ...List.generate(3, (i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(controller: ctrls[i], decoration: InputDecoration(labelText: 'Word ${i+1}', border: const OutlineInputBorder())),
      )),
      const Spacer(),
      FilledButton(
        onPressed: () {
          int score = 0;
          final lower = words.map((w) => w.toLowerCase().trim()).toList();
          final user = ctrls.map((c) => c.text.toLowerCase().trim()).toList();
          for (final u in user) { if (lower.contains(u)) score++; }
          score = _clampScore(score, widget.spec.max);
          widget.onDone(score, {"user": user, "target": words});
        },
        child: const Text('Next'),
      )
    ]));
  }
}

/// ========== FLUENCY (auto via thresholds) ==========
class Fluency extends StatefulWidget {
  final TaskSpec spec;
  final void Function(int, Map<String, dynamic>) onDone;
  const Fluency({super.key, required this.spec, required this.onDone});

  @override
  State<Fluency> createState() => _FluencyState();
}

class _FluencyState extends State<Fluency> {
  late final String targetLetter;
  final TextEditingController _textCtrl = TextEditingController();

  Timer? _timer;
  int secs = 60;
  bool running = false;

  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _resetState();
  }

  void _resetState() {
    _timer?.cancel();
    secs = 60;
    running = false;
    _completed = false; // ✅ RESET
    _textCtrl.clear();

    if (widget.spec.type == TaskType.fluencyLetter) {
      const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      targetLetter =
      letters[DateTime.now().millisecondsSinceEpoch % letters.length];
    }
  }



  @override
  void dispose() {
    _timer?.cancel();
    _textCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secs > 0) {
        setState(() => secs--);
      } else {
        timer.cancel();
        _finish();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _padded(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.spec.type == TaskType.fluencyAnimals
              ? 'Name as many animals as you can'
              : 'Say as many words as you can starting with the letter:',
          style: const TextStyle(fontSize: 16),
        ),

        if (widget.spec.type == TaskType.fluencyLetter)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                targetLetter,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        Text('Time remaining: $secs seconds'),
        const SizedBox(height: 12),

        Row(
          children: [
            FilledButton(
              onPressed: running
                  ? null
                  : () {
                setState(() => running = true);
                _startTimer();
              },
              child: const Text('Start'),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: (running && !_completed) ? _finish : null,
              child: const Text('Finish'),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Expanded(
          child: TextField(
            controller: _textCtrl,
            enabled: running,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              hintText: 'Type words here (space or new line separated)',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    ));
  }

  void _finish() {
    if (_completed) return; // prevent double fire
    _completed = true;

    _timer?.cancel();

    final rawWords = _textCtrl.text
        .toLowerCase()
        .split(RegExp(r'[\s,\n]+'))
        .where((w) => w.isNotEmpty)
        .toSet();

    final words = widget.spec.type == TaskType.fluencyLetter
        ? rawWords
        .where((w) => w.startsWith(targetLetter.toLowerCase()))
        .toList()
        : rawWords.toList();

    final count = words.length;
    final score = scoreFluency(widget.spec.payload, count);

    // 🔥 THIS MUST ALWAYS EXECUTE
    widget.onDone(score, {
      "taskType": widget.spec.type.name,
      "letter": widget.spec.type == TaskType.fluencyLetter ? targetLetter : null,
      "count": count,
      "words": words,
      "timeUsed": 60 - secs,
    });
  }
}

/// ========== NAME & ADDRESS — LEARNING (manual) ==========
class NameAddressLearnTask extends StatelessWidget {
  final TaskSpec spec;
  final void Function(int, Map<String, dynamic>) onDone;

  const NameAddressLearnTask({
    super.key,
    required this.spec,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final elements = (spec.payload['elements'] as List).cast<String>();

    return _padded(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Memory Task',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          const Text(
            'Please carefully read and remember the following name and address.\n'
                'You will be asked to recall this information later in the test.',
            style: TextStyle(fontSize: 14),
          ),

          const SizedBox(height: 20),

          ...elements.map(
                (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                e,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const Spacer(),

          FilledButton(
            onPressed: () {
              // No scoring here — only learning phase
              onDone(
                0,
                {
                  "shown": elements,
                  "instruction":
                  "User instructed to memorize the address for later recall",
                },
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

/// ========== FAMOUS PEOPLE (manual count) ==========
class FamousPeopleTask extends StatefulWidget {
  final TaskSpec spec;
  final void Function(int, Map<String, dynamic>) onDone;

  const FamousPeopleTask({
    super.key,
    required this.spec,
    required this.onDone,
  });

  @override
  State<FamousPeopleTask> createState() => _FamousPeopleTaskState();
}

class _FamousPeopleTaskState extends State<FamousPeopleTask> {
  final ctrls = List.generate(4, (_) => TextEditingController());

  final questions = const [
    'Who is the Prime Minister of India?',
    'Who is the President of India?',
    'Who is the Chief Minister of your state?',
    'Who is the Father of the Nation?',
  ];

  /// ✅ Correct answers (can be made dynamic later)
  final answers = const [
    'narendra modi',
    'droupadi murmu',
    '', // Chief Minister → allow examiner/manual review
    'mahatma gandhi',
  ];

  @override
  void dispose() {
    for (final c in ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _padded(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'General Knowledge',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          const Text(
            'Please answer the following questions:',
            style: TextStyle(fontSize: 14),
          ),

          const SizedBox(height: 16),

          ...List.generate(questions.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: TextField(
                controller: ctrls[i],
                decoration: InputDecoration(
                  labelText: questions[i],
                  border: const OutlineInputBorder(),
                ),
              ),
            );
          }),

          const Spacer(),

          FilledButton(
            onPressed: _finish,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  void _finish() {
    int score = 0;
    final userAnswers =
    ctrls.map((c) => c.text.trim().toLowerCase()).toList();

    for (int i = 0; i < answers.length; i++) {
      if (answers[i].isEmpty) continue; // CM handled manually / later
      if (userAnswers[i] == answers[i]) score++;
    }

    widget.onDone(
      score.clamp(0, widget.spec.max),
      {
        'questions': questions,
        'userAnswers': userAnswers,
        'note':
        'Chief Minister answer may require manual verification based on state',
      },
    );
  }
}

/// ========== COMPREHENSION (per-command toggles, auto-sum) ==========
class ComprehensionTask extends StatefulWidget {
  final TaskSpec spec;
  final void Function(int, Map<String, dynamic>) onDone;

  const ComprehensionTask({
    super.key,
    required this.spec,
    required this.onDone,
  });

  @override
  State<ComprehensionTask> createState() => _ComprehensionTaskState();
}

class _ComprehensionTaskState extends State<ComprehensionTask> {
  int index = 0;
  int score = 0;
  final List<Map<String, dynamic>> responses = [];

  @override
  Widget build(BuildContext context) {
    final questions =
    (widget.spec.payload['questions'] as List).cast<Map<String, dynamic>>();
    final q = questions[index];

    return _padded(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Instruction ${index + 1} of ${questions.length}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Text(
            q['instruction'],
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),

          ...q['options'].map<Widget>((opt) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: FilledButton.tonal(
                onPressed: () => _select(opt),
                child: Text(opt),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _select(String choice) {
    final questions =
    (widget.spec.payload['questions'] as List).cast<Map<String, dynamic>>();
    final q = questions[index];

    if (choice == q['answer']) {
      score++;
    }

    responses.add({
      "question": q['instruction'],
      "selected": choice,
      "correct": q['answer'],
    });

    if (index + 1 < questions.length) {
      setState(() => index++);
    } else {
      widget.onDone(
        score,
        {
          "responses": responses,
        },
      );
    }
  }
}

/// ========== SENTENCE WRITING (manual) ==========
class SentenceWritingTask extends StatefulWidget {
  final TaskSpec spec;
  final void Function(int, Map<String, dynamic>) onDone;

  const SentenceWritingTask({
    super.key,
    required this.spec,
    required this.onDone,
  });

  @override
  State<SentenceWritingTask> createState() => _SentenceWritingTaskState();
}

class _SentenceWritingTaskState extends State<SentenceWritingTask> {
  final c1 = TextEditingController();
  final c2 = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return _padded(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Write TWO meaningful sentences about your last holiday.',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: c1,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Sentence 1',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: c2,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Sentence 2',
            border: OutlineInputBorder(),
          ),
        ),

        const Spacer(),

        FilledButton(
          onPressed: () {
            final score = scoreSentenceWriting(
              c1.text,
              c2.text,
              maxScore: widget.spec.max,
            );

            widget.onDone(score, {
              "sentence1": c1.text,
              "sentence2": c2.text,
            });
          },
          child: const Text('Next'),
        ),
      ],
    ));
  }
}

/// ========== WORD REPETITION (per-word toggles) ==========
class WordRepetitionTask extends StatefulWidget {
  final TaskSpec spec; final void Function(int, Map<String, dynamic>) onDone;
  const WordRepetitionTask({super.key, required this.spec, required this.onDone});
  @override
  State<WordRepetitionTask> createState() => _WordRepetitionTaskState();
}
class _WordRepetitionTaskState extends State<WordRepetitionTask> {
  late final List<String> words = (widget.spec.payload['words'] as List).cast<String>();
  late final List<bool> ok = List<bool>.filled(words.length, false);
  @override
  Widget build(BuildContext context) {
    return _padded(Column(children: [
      const Text('Repeat the words correctly. Mark correct ones.'),
      ...List.generate(words.length, (i) => CheckboxListTile(
        title: Text(words[i]),
        value: ok[i],
        onChanged: (v) => setState(() => ok[i] = v ?? false),
      )),
      FilledButton(
        onPressed: () {
          int s = ok.where((e) => e).length;
          s = _clampScore(s, widget.spec.max);
          widget.onDone(s, {"results": ok});
        },
        child: const Text('Next'),
      ),
    ]));
  }
}

/// ========== PROVERB REPETITION (per-proverb toggles) ==========
class ProverbRepetitionTask extends StatefulWidget {
  final TaskSpec spec; final void Function(int, Map<String, dynamic>) onDone;
  const ProverbRepetitionTask({super.key, required this.spec, required this.onDone});
  @override
  State<ProverbRepetitionTask> createState() => _ProverbRepetitionTaskState();
}
class _ProverbRepetitionTaskState extends State<ProverbRepetitionTask> {
  late final List<String> prov = (widget.spec.payload['proverbs'] as List).cast<String>();
  late final List<bool> ok = List<bool>.filled(prov.length, false);
  @override
  Widget build(BuildContext context) {
    return _padded(Column(children: [
      const Text('Repeat the proverbs correctly. Mark correct ones.'),
      ...List.generate(prov.length, (i) => CheckboxListTile(
        title: Text(prov[i]),
        value: ok[i],
        onChanged: (v) => setState(() => ok[i] = v ?? false),
      )),
      FilledButton(
        onPressed: () {
          int s = ok.where((e) => e).length;
          s = _clampScore(s, widget.spec.max);
          widget.onDone(s, {"results": ok});
        },
        child: const Text('Next'),
      ),
    ]));
  }
}

/// ========== OBJECT NAMING (manual) ==========
class ObjectNamingTask extends StatelessWidget {
  final TaskSpec spec; final void Function(int, Map<String, dynamic>) onDone;
  const ObjectNamingTask({super.key, required this.spec, required this.onDone});
  @override
  Widget build(BuildContext context) {
    return _padded(_ScoreSlider(
      max: spec.max,
      label: 'How many objects named correctly? (max ${spec.max})',
      onSet: (s) => onDone(s, {}),
    ));
  }
}

/// ========== MULTI-STEP COMMAND (manual steps completed) ==========
class MultiStepCommandTask extends StatefulWidget {
  final TaskSpec spec; final void Function(int, Map<String, dynamic>) onDone;
  const MultiStepCommandTask({super.key, required this.spec, required this.onDone});
  @override
  State<MultiStepCommandTask> createState() => _MultiStepCommandTaskState();
}
class _MultiStepCommandTaskState extends State<MultiStepCommandTask> {
  late final int steps = (widget.spec.payload['steps'] as int);
  late final List<bool> ok = List<bool>.filled(steps, false);

  @override
  Widget build(BuildContext context) {
    return _padded(Column(children: [
      Text('Mark each step performed (total $steps)'),
      ...List.generate(steps, (i) => CheckboxListTile(
        title: Text('Step ${i+1}'),
        value: ok[i],
        onChanged: (v) => setState(() => ok[i] = v ?? false),
      )),
      FilledButton(
        onPressed: () {
          int s = ok.where((e) => e).length;
          s = _clampScore(s, widget.spec.max);
          widget.onDone(s, {"results": ok});
        },
        child: const Text('Next'),
      )
    ]));
  }
}

/// ========== READING WORDS (auto per-word toggle) ==========
class ReadingWordsTask extends StatefulWidget {
  final TaskSpec spec; final void Function(int, Map<String, dynamic>) onDone;
  const ReadingWordsTask({super.key, required this.spec, required this.onDone});
  @override
  State<ReadingWordsTask> createState() => _ReadingWordsTaskState();
}
class _ReadingWordsTaskState extends State<ReadingWordsTask> {
  late final List<String> words = (widget.spec.payload['words'] as List).cast<String>();
  late final List<bool> ok = List<bool>.filled(words.length, false);
  @override
  Widget build(BuildContext context) {
    return _padded(Column(children: [
      const Text('Reading words — mark correct pronunciations'),
      Expanded(child: ListView.builder(
        itemCount: words.length,
        itemBuilder: (_, i) => CheckboxListTile(
          title: Text(words[i]),
          value: ok[i],
          onChanged: (v) => setState(() => ok[i] = v ?? false),
        ),
      )),
      FilledButton(
        onPressed: () {
          // Sheet’s max = 1; give 1 if majority correct, else 0 (simple rubric)
          final correct = ok.where((e) => e).length;
          final s = correct >= (words.length / 2).ceil() ? 1 : 0;
          widget.onDone(_clampScore(s, widget.spec.max), {"results": ok});
        },
        child: const Text('Next'),
      )
    ]));
  }
}

/// ========== LOOPS TRACING / CUBE COPY (manual) ==========
class LoopsTracingTask extends StatelessWidget {
  final TaskSpec spec; final void Function(int, Map<String, dynamic>) onDone;
  const LoopsTracingTask({super.key, required this.spec, required this.onDone});
  @override
  Widget build(BuildContext context) {
    return _padded(_ScoreSlider(max: spec.max, label: 'Loops quality score', onSet: (s) => onDone(s, {})));
  }
}
class CubeCopyTask extends StatelessWidget {
  final TaskSpec spec; final void Function(int, Map<String, dynamic>) onDone;
  const CubeCopyTask({super.key, required this.spec, required this.onDone});
  @override
  Widget build(BuildContext context) {
    return _padded(_ScoreSlider(max: spec.max, label: 'Cube copy score', onSet: (s) => onDone(s, {})));
  }
}

/// ========== COUNT DOTS (auto) ==========
class CountDots extends StatefulWidget {
  final TaskSpec spec;
  final void Function(int, Map<String, dynamic>) onDone;
  const CountDots({super.key, required this.spec, required this.onDone});
  @override
  State<CountDots> createState() => _CountDotsState();
}
class _CountDotsState extends State<CountDots> {
  final List<TextEditingController> ctrls = List.generate(4, (_) => TextEditingController());
  @override
  Widget build(BuildContext context) {
    return _padded(ListView(
      children: List.generate(4, (i) => ListTile(
        title: Text('Panel ${i + 1} — enter count'),
        subtitle: TextField(controller: ctrls[i], keyboardType: TextInputType.number),
      ))
        ..add(
          FilledButton(
            onPressed: () {
              final u = ctrls.map((c) => int.tryParse(c.text)).toList();
              final s = scoreDots(u, widget.spec.payload["answers"]);
              widget.onDone(s, {"user": u});
            },
            child: const Text('Next'),
          ),
        ),
    ));
  }
}

/// ========== CLOCK DRAW (manual rubric 0–5) ==========
class ClockDraw extends StatefulWidget {
  final TaskSpec spec;
  final void Function(int, Map<String, dynamic>) onDone;
  const ClockDraw({super.key, required this.spec, required this.onDone});
  @override
  State<ClockDraw> createState() => _ClockDrawState();
}
class _ClockDrawState extends State<ClockDraw> {
  final points = <Offset>[];
  int rubric = 0;
  @override
  Widget build(BuildContext context) {
    return _padded(Column(children: [
      Text('Draw a clock showing ${widget.spec.payload["time"]}'),
      Expanded(
        child: GestureDetector(
          onPanUpdate: (d) => setState(() => points.add(d.localPosition)),
          onPanEnd: (_) => points.add(Offset.infinite),
          child: CustomPaint(painter: _Sketch(points), child: Container(color: Colors.white)),
        ),
      ),
      Wrap(
        spacing: 6,
        children: List.generate(6, (i) => ChoiceChip(
          label: Text('$i'), selected: rubric == i, onSelected: (_) => setState(() => rubric = i),
        )),
      ),
      FilledButton(onPressed: () => widget.onDone(rubric, {"strokes": points.length}), child: const Text('Next')),
    ]));
  }
}
class _Sketch extends CustomPainter {
  final List<Offset> pts;
  _Sketch(this.pts);
  @override void paint(Canvas c, Size s) {
    final p = Paint()..strokeWidth = 2..style = PaintingStyle.stroke;
    for (var i = 0; i < pts.length - 1; i++) {
      if (pts[i] != Offset.infinite && pts[i + 1] != Offset.infinite) {
        c.drawLine(pts[i], pts[i + 1], p);
      }
    }
  }
  @override bool shouldRepaint(_) => true;
}

/// ========== HUNTING LETTERS (manual) ==========
class HuntingLettersTask extends StatelessWidget {
  final TaskSpec spec; final void Function(int, Map<String, dynamic>) onDone;
  const HuntingLettersTask({super.key, required this.spec, required this.onDone});
  @override
  Widget build(BuildContext context) {
    return _padded(_ScoreSlider(
      max: spec.max,
      label: 'Hunting letters score (manual)',
      onSet: (s) => onDone(s, {}),
    ));
  }
}

/// ========== NAME & ADDRESS — DELAYED (auto exact match per element) ==========
class NameAddressDelayedTask extends StatefulWidget {
  final TaskSpec spec; final void Function(int, Map<String, dynamic>) onDone;
  const NameAddressDelayedTask({super.key, required this.spec, required this.onDone});
  @override
  State<NameAddressDelayedTask> createState() => _NameAddressDelayedTaskState();
}
class _NameAddressDelayedTaskState extends State<NameAddressDelayedTask> {
  final ctrls = List.generate(4, (_) => TextEditingController());
  @override
  Widget build(BuildContext context) {
    return _padded(Column(children: [
      const Text('Recall the Name & Address elements'),
      const SizedBox(height: 8),
      ...List.generate(4, (i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(controller: ctrls[i], decoration: InputDecoration(labelText: 'Element ${i+1}', border: const OutlineInputBorder())),
      )),
      FilledButton(
        onPressed: () {
          final target = (widget.spec.payload['elements'] ?? const []) as List?; // if present
          final user = ctrls.map((c) => c.text.trim().toLowerCase()).toList();
          int s = 0;
          if (target != null && target.isNotEmpty) {
            final low = target.map((e) => e.toString().trim().toLowerCase()).toList();
            for (final u in user) { if (low.contains(u) && u.isNotEmpty) s++; }
          } else {
            // If no targets provided here, just count non-empty
            for (final u in user) { if (u.isNotEmpty) s++; }
          }
          s = _clampScore(s, widget.spec.max);
          widget.onDone(s, {"user": user});
        },
        child: const Text('Next'),
      )
    ]));
  }
}

/// ========== NAME & ADDRESS — RECOGNITION (auto per toggle) ==========
class NameAddressRecognizeTask extends StatefulWidget {
  final TaskSpec spec; final void Function(int, Map<String, dynamic>) onDone;
  const NameAddressRecognizeTask({super.key, required this.spec, required this.onDone});
  @override
  State<NameAddressRecognizeTask> createState() => _NameAddressRecognizeTaskState();
}
class _NameAddressRecognizeTaskState extends State<NameAddressRecognizeTask> {
  // simple multiple correct toggles (examiner checks which elements recognized)
  late final List<String> options = ((widget.spec.payload['elements']) ??
      ["Velayudhan Thampi", "42 Kovil Road", "Chengamanad", "Elanji"]).cast<String>();
  late final List<bool> ok = List<bool>.filled(options.length, false);

  @override
  Widget build(BuildContext context) {
    return _padded(Column(children: [
      const Text('Recognize elements from Name & Address'),
      Expanded(child: ListView.builder(
        itemCount: options.length,
        itemBuilder: (_, i) => CheckboxListTile(
          title: Text(options[i]),
          value: ok[i],
          onChanged: (v) => setState(() => ok[i] = v ?? false),
        ),
      )),
      FilledButton(
        onPressed: () {
          int s = ok.where((e) => e).length;
          s = _clampScore(s, widget.spec.max);
          widget.onDone(s, {"recognized": ok});
        },
        child: const Text('Next'),
      )
    ]));
  }
}

/// ========== FALLBACK SIMPLE MANUAL SCORE ==========
class SimpleScored extends StatefulWidget {
  final TaskSpec spec;
  final void Function(int, Map<String, dynamic>) onDone;
  const SimpleScored({super.key, required this.spec, required this.onDone});
  @override
  State<SimpleScored> createState() => _SimpleScoredState();
}
class _SimpleScoredState extends State<SimpleScored> {
  int score = 0;
  @override
  Widget build(BuildContext context) {
    return _padded(Column(children: [
      Text('Mark score for: ${widget.spec.id} (max ${widget.spec.max})'),
      Slider(
        value: score.toDouble(),
        min: 0,
        max: widget.spec.max.toDouble(),
        divisions: widget.spec.max,
        label: '$score',
        onChanged: (v) => setState(() => score = v.round()),
      ),
      const Spacer(),
      FilledButton(onPressed: () => widget.onDone(score, {}), child: const Text('Next')),
    ]));
  }
}
