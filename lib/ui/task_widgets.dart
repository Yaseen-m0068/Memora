import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // for Ticker
import '../models.dart';
import '../scoring.dart';

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

/// ========== DIGIT SPAN (auto-score exact sequences) ==========
class DigitSpanTask extends StatefulWidget {
  final TaskSpec spec;
  final void Function(int, Map<String, dynamic>) onDone;
  const DigitSpanTask({super.key, required this.spec, required this.onDone});
  @override
  State<DigitSpanTask> createState() => _DigitSpanTaskState();
}
class _DigitSpanTaskState extends State<DigitSpanTask> {
  late final List<String> forward = (widget.spec.payload['forward'] as List).cast<String>();
  late final List<String> backward = (widget.spec.payload['backward'] as List).cast<String>();

  final _f = <TextEditingController>[];
  final _b = <TextEditingController>[];

  @override
  void initState() {
    super.initState();
    for (var _ in forward) _f.add(TextEditingController());
    for (var _ in backward) _b.add(TextEditingController());
  }

  @override
  Widget build(BuildContext context) {
    return _padded(ListView(children: [
      const Text('Digit Span — enter exactly as heard (spaces allowed)'),
      const SizedBox(height: 8),
      ...List.generate(forward.length, (i) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Forward ${i + 1}: ${forward[i]}'),
          TextField(controller: _f[i], decoration: const InputDecoration(hintText: 'Your attempt')),
          const SizedBox(height: 8),
        ],
      )),
      const SizedBox(height: 8),
      ...List.generate(backward.length, (i) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Backward ${i + 1}: ${backward[i]}'),
          TextField(controller: _b[i], decoration: const InputDecoration(hintText: 'Your attempt')),
          const SizedBox(height: 8),
        ],
      )),
      FilledButton(
        onPressed: () {
          int s = 0;
          final tr = RegExp(r'\s+');
          for (var i = 0; i < forward.length; i++) {
            if (_f[i].text.trim().replaceAll(tr, ' ') == forward[i]) s++;
          }
          for (var i = 0; i < backward.length; i++) {
            if (_b[i].text.trim().replaceAll(tr, ' ') == backward[i]) s++;
          }
          s = _clampScore(s, widget.spec.max);
          widget.onDone(s, {
            "forward": List.generate(forward.length, (i) => _f[i].text),
            "backward": List.generate(backward.length, (i) => _b[i].text),
          });
        },
        child: const Text('Next'),
      )
    ]));
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
  final _ctrl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return _padded(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Starting from 100, subtract 7 each time. Enter 5 numbers.'),
        TextField(
          controller: _ctrl,
          decoration: const InputDecoration(hintText: "e.g., 93 86 79 72 65"),
        ),
        const Spacer(),
        FilledButton(
          onPressed: () {
            final parts = _ctrl.text.split(RegExp(r'[\s,]+')).where((e) => e.isNotEmpty).toList();
            int s = 0, cur = widget.spec.payload["start"] as int;
            for (int i = 0; i < parts.length && i < 5; i++) {
              cur -= (widget.spec.payload["steps"] as int);
              if (int.tryParse(parts[i]) == cur) s++;
            }
            widget.onDone(s, {"answers": parts});
          },
          child: const Text('Next'),
        )
      ],
    ));
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
class _FluencyState extends State<Fluency> with SingleTickerProviderStateMixin {
  final setWords = <String>{};
  bool running = false;
  int secs = 60;

  late final Ticker ticker = Ticker(_tick);
  void _tick(Duration _) {
    if (secs > 0) {
      setState(() => secs--);
    } else {
      ticker.stop();
      _finish();
    }
  }

  @override
  void dispose() { ticker.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return _padded(Column(children: [
      Text(widget.spec.type == TaskType.fluencyAnimals
          ? 'Name as many animals as you can'
          : 'Say words starting with the target letter.'),
      Text('Time: $secs s'),
      Row(children: [
        FilledButton(
          onPressed: () {
            if (!running) { running = true; ticker.start(); setState((){}); }
          },
          child: const Text('Start'),
        ),
        const SizedBox(width: 8),
        FilledButton(onPressed: _finish, child: const Text('Finish early')),
      ]),
      Expanded(child: ListView(children: setWords.map((w) => ListTile(title: Text(w))).toList())),
      TextField(
        onSubmitted: (v) { if (v.trim().isNotEmpty) setState(() => setWords.add(v.trim())); },
        decoration: const InputDecoration(hintText: 'type & Enter'),
      ),
    ]));
  }

  void _finish() {
    final count = setWords.length;
    final s = scoreFluency(widget.spec.payload, count);
    widget.onDone(s, {"count": count, "words": setWords.toList()});
  }
}

/// ========== NAME & ADDRESS — LEARNING (manual) ==========
class NameAddressLearnTask extends StatelessWidget {
  final TaskSpec spec;
  final void Function(int, Map<String, dynamic>) onDone;
  const NameAddressLearnTask({super.key, required this.spec, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final elements = (spec.payload['elements'] as List).cast<String>();
    final weights = (spec.payload['perElementScores'] as List).cast<int>();
    return _padded(Column(children: [
      const Text('Name & Address — Learning'),
      const SizedBox(height: 8),
      ...List.generate(elements.length, (i) => ListTile(
        title: Text(elements[i]),
        subtitle: Text('Weight: ${weights[i]}'),
      )),
      const SizedBox(height: 8),
      _ScoreSlider(
        max: spec.max,
        label: 'Mark total learned this trial (max ${spec.max})',
        onSet: (s) => onDone(s, {"noted": true}),
      ),
    ]));
  }
}

/// ========== FAMOUS PEOPLE (manual count) ==========
class FamousPeopleTask extends StatelessWidget {
  final TaskSpec spec; final void Function(int, Map<String, dynamic>) onDone;
  const FamousPeopleTask({super.key, required this.spec, required this.onDone});
  @override
  Widget build(BuildContext context) {
    return _padded(_ScoreSlider(
      max: spec.max,
      label: 'How many correctly named? (max ${spec.max})',
      onSet: (s) => onDone(s, {}),
    ));
  }
}

/// ========== COMPREHENSION (per-command toggles, auto-sum) ==========
class ComprehensionTask extends StatefulWidget {
  final TaskSpec spec; final void Function(int, Map<String, dynamic>) onDone;
  const ComprehensionTask({super.key, required this.spec, required this.onDone});
  @override
  State<ComprehensionTask> createState() => _ComprehensionTaskState();
}
class _ComprehensionTaskState extends State<ComprehensionTask> {
  late final List<String> cmds = (widget.spec.payload['commands'] as List).cast<String>();
  late final List<bool> ok = List<bool>.filled(cmds.length, false);

  @override
  Widget build(BuildContext context) {
    return _padded(Column(children: [
      const Text('Follow the commands: mark correct ones'),
      Expanded(child: ListView.builder(
        itemCount: cmds.length,
        itemBuilder: (_, i) => CheckboxListTile(
          title: Text(cmds[i]),
          value: ok[i],
          onChanged: (v) => setState(() => ok[i] = v ?? false),
        ),
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

/// ========== SENTENCE WRITING (manual) ==========
class SentenceWritingTask extends StatelessWidget {
  final TaskSpec spec; final void Function(int, Map<String, dynamic>) onDone;
  const SentenceWritingTask({super.key, required this.spec, required this.onDone});
  @override
  Widget build(BuildContext context) {
    final c = TextEditingController();
    return _padded(Column(children: [
      const Text('Write a meaningful sentence:'),
      const SizedBox(height: 8),
      TextField(controller: c, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder())),
      const SizedBox(height: 8),
      _ScoreSlider(max: spec.max, onSet: (s) => onDone(s, {"sentence": c.text})),
    ]));
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
