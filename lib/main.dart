import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';
import 'data/tasks.dart';
import 'scoring.dart';
import 'auth/auth_service.dart';

// UI
import 'ui/task_widgets.dart';
import 'ui/result_screen.dart';
import 'ui/login_screen.dart';
import 'ui/register_screen.dart';

final assessmentProvider = StateProvider<Assessment>((ref) {
  return Assessment(id: const Uuid().v4(), language: "ml", startedAt: DateTime.now());
});

// --- Auth providers ---
final authServiceProvider = Provider<AuthService>((_) => AuthService());
final authUserProvider = FutureProvider<AuthUser?>((ref) async {
  return ref.read(authServiceProvider).currentUser();
});

void main() => runApp(const ProviderScope(child: MemoraApp()));

class MemoraApp extends ConsumerWidget {
  const MemoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/gate', builder: (_, __) => const _AuthGate()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/task/:idx', builder: (_, s) {
          final idx = int.parse(s.pathParameters['idx']!);
          return TaskHost(index: idx);
        }),
        GoRoute(path: '/result', builder: (_, __) => const ResultScreen()),
      ],
      redirect: (context, state) async {
        // We keep a simple gate via /gate; no global redirect here
        return null;
      },
    );

    return MaterialApp.router(
      title: 'Memora',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      routerConfig: router,
    );
  }
}

// --- Shows login or home based on current user ---
class _AuthGate extends ConsumerWidget {
  const _AuthGate({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authUserProvider);
    return userAsync.when(
      data: (u) {
        if (u == null) {
          // not logged in -> login
          Future.microtask(() => context.go('/login'));
        } else {
          Future.microtask(() => context.go('/'));
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: Center(child: Text('Error loading auth state'))),
    );
  }
}

// --- Your existing Start screen becomes Home ---
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memora (ACE-III)'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authServiceProvider).logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.go('/task/0'),
          child: const Text('Start test'),
        ),
      ),
    );
  }
}

class TaskHost extends ConsumerStatefulWidget {
  final int index;
  const TaskHost({super.key, required this.index});
  @override
  ConsumerState<TaskHost> createState() => _TaskHostState();
}

class _TaskHostState extends ConsumerState<TaskHost> {
  void _finish(int s, Map<String, dynamic> d) {
    final spec = kAceTasks[widget.index];
    final a = ref.read(assessmentProvider);
    final updated = a.copyWith(responses: [
      ...a.responses,
      ResponseModel(taskId: spec.id, data: d, score: s)
    ]);
    ref.read(assessmentProvider.notifier).state = updated;

    if (widget.index + 1 < kAceTasks.length) {
      context.go('/task/${widget.index + 1}');
    } else {
      context.go('/result');
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = kAceTasks[widget.index];

    Widget body;
    // inside _TaskHostState.build -> switch(spec.type)
    switch (spec.type) {
      case TaskType.orientation:        body = OrientationTask(spec: spec, onDone: _finish); break;
      case TaskType.digitSpan:          body = DigitSpanTask(spec: spec, onDone: _finish); break;
      case TaskType.serial7:            body = Serial7(spec: spec, onDone: _finish); break;
      case TaskType.recall3:            body = Recall3Task(spec: spec, onDone: _finish); break;
      case TaskType.fluencyLetter:
      case TaskType.fluencyAnimals:     body = Fluency(spec: spec, onDone: _finish); break;

      case TaskType.nameAddressLearn:   body = NameAddressLearnTask(spec: spec, onDone: _finish); break;
      case TaskType.famousPeople:       body = FamousPeopleTask(spec: spec, onDone: _finish); break;
      case TaskType.comprehension:      body = ComprehensionTask(spec: spec, onDone: _finish); break;
      case TaskType.sentenceWriting:    body = SentenceWritingTask(spec: spec, onDone: _finish); break;
      case TaskType.wordRepetition:     body = WordRepetitionTask(spec: spec, onDone: _finish); break;
      case TaskType.proverbRepetition:  body = ProverbRepetitionTask(spec: spec, onDone: _finish); break;
      case TaskType.objectNaming:       body = ObjectNamingTask(spec: spec, onDone: _finish); break;
      case TaskType.multiStepCommand:   body = MultiStepCommandTask(spec: spec, onDone: _finish); break;
      case TaskType.readingWords:       body = ReadingWordsTask(spec: spec, onDone: _finish); break;
      case TaskType.loopsTracing:       body = LoopsTracingTask(spec: spec, onDone: _finish); break;
      case TaskType.cubeCopy:           body = CubeCopyTask(spec: spec, onDone: _finish); break;
      case TaskType.countDots:          body = CountDots(spec: spec, onDone: _finish); break;
      case TaskType.clockDraw:          body = ClockDraw(spec: spec, onDone: _finish); break;
      case TaskType.huntingLetters:     body = HuntingLettersTask(spec: spec, onDone: _finish); break;
      case TaskType.nameAddressDelayed: body = NameAddressDelayedTask(spec: spec, onDone: _finish); break;
      case TaskType.nameAddressRecognize: body = NameAddressRecognizeTask(spec: spec, onDone: _finish); break;
    }

    return Scaffold(
      appBar: AppBar(title: Text('${widget.index + 1}/${kAceTasks.length}')),
      body: Padding(padding: const EdgeInsets.all(12), child: body),
    );
  }
}
