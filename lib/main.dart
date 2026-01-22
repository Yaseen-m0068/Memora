import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


import 'models.dart';
import 'data/tasks.dart';
import 'scoring.dart';
import 'auth/auth_service.dart';

// UI
import 'ui/home_screen.dart';
import 'ui/app_gate.dart';
import 'ui/task_widgets.dart';
import 'ui/result_screen.dart';
import 'ui/login_screen.dart';
import 'ui/register_screen.dart';
import 'theme/app_colors.dart';


final assessmentProvider = StateProvider<Assessment>((ref) {
  return Assessment(
    id: const Uuid().v4(),
    language: "ml",
    startedAt: DateTime.now(),
  );
});

// --- Auth providers ---
final authServiceProvider = Provider<AuthService>((_) => AuthService());
final authUserProvider = FutureProvider<AuthUser?>((ref) async {
  return ref.read(authServiceProvider).currentUser();
});

/// 🔥 IMPORTANT: Firebase initialization
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: MemoraApp()));
}

class MemoraApp extends ConsumerWidget {
  const MemoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter(
      initialLocation: '/gate',
      routes: [
        GoRoute(
          path: '/gate',
          builder: (_, __) => const AppGate(),
        ),

        GoRoute(
          path: '/',
          builder: (_, __) => const HomeScreen(),
        ),

        GoRoute(
          path: '/task/:idx',
          builder: (context, state) {
            final idx = int.parse(state.pathParameters['idx']!);
            return TaskHost(index: idx);
          },
        ),

        GoRoute(
          path: '/result',
          builder: (_, __) => const ResultScreen(),
        ),

        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginScreen(),
        ),

        GoRoute(
          path: '/register',
          builder: (_, __) => const RegisterScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Memora',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,

        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),

        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: AppColors.textGrey,
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.softGreen,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.border),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
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
          Future.microtask(() => context.go('/login'));
        } else {
          Future.microtask(() => context.go('/'));
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Scaffold(
        body: Center(child: Text('Error loading auth state')),
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
  Future<void> _saveAssessmentToFirestore(Assessment assessment) async {
    final firestore = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    final userId = user.uid;

    final totalScore =
    assessment.responses.fold<int>(0, (sum, r) => sum + r.score);

    await firestore
        .collection('users')
        .doc(userId)
        .collection('assessments')
        .doc(assessment.id)
        .set({
      'assessmentId': assessment.id,
      'language': assessment.language,
      'startedAt': assessment.startedAt,
      'completedAt': DateTime.now(),
      'totalScore': totalScore,
      'responses': assessment.responses.map((r) {
        return {
          'taskId': r.taskId,
          'score': r.score,
          'data': r.data,
        };
      }).toList(),
    });
  }


  Future<void> _finish(int score, Map<String, dynamic> data) async {
    final spec = kAceTasks[widget.index];
    final assessment = ref.read(assessmentProvider);

    final updated = assessment.copyWith(
      responses: [
        ...assessment.responses,
        ResponseModel(taskId: spec.id, data: data, score: score),
      ],
    );

    ref.read(assessmentProvider.notifier).state = updated;

    if (widget.index + 1 < kAceTasks.length) {
      context.go('/task/${widget.index + 1}');
    } else {
      await _saveAssessmentToFirestore(
      ref.read(assessmentProvider),
      );

      context.go('/result');
    }

  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Test'),
        content: const Text(
          'Are you sure you want to exit the test?\nYour progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);

              // OPTIONAL: clear current assessment
              ref.read(assessmentProvider.notifier).state =
                  Assessment(
                    id: const Uuid().v4(),
                    language: "ml",
                    startedAt: DateTime.now(),
                  );

              context.go('/'); // back to Home
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spec = kAceTasks[widget.index];

    late Widget body;

    switch (spec.type) {
      case TaskType.orientation:
        body = OrientationTask(spec: spec, onDone: _finish);
        break;
      case TaskType.attentionAudio:
        body = AttentionAudioTask(spec: spec, onDone: _finish);
        break;
      case TaskType.serial7:
        body = Serial7(spec: spec, onDone: _finish);
        break;
      case TaskType.recall3:
        body = Recall3Task(spec: spec, onDone: _finish);
        break;
      case TaskType.fluencyLetter:
      case TaskType.fluencyAnimals:
      body = Fluency(
        key: ValueKey(spec.id), // 🔥 forces fresh state per task
        spec: spec,
        onDone: _finish,
      );
      break;
      case TaskType.nameAddressLearn:
        body = NameAddressLearnTask(spec: spec, onDone: _finish);
        break;
      case TaskType.famousPeople:
        body = FamousPeopleTask(spec: spec, onDone: _finish);
        break;
      case TaskType.comprehension:
        body = ComprehensionTask(spec: spec, onDone: _finish);
        break;
      case TaskType.sentenceWriting:
        body = SentenceWritingTask(spec: spec, onDone: _finish);
        break;
      case TaskType.wordRepetition:
        body = WordRepetitionTask(spec: spec, onDone: _finish);
        break;
      case TaskType.proverbRepetition:
        body = ProverbRepetitionTask(spec: spec, onDone: _finish);
        break;
      case TaskType.objectNaming:
        body = ObjectNamingTask(spec: spec, onDone: _finish);
        break;
      case TaskType.multiStepCommand:
        body = MultiStepCommandTask(spec: spec, onDone: _finish);
        break;
      case TaskType.readingWords:
        body = ReadingWordsTask(spec: spec, onDone: _finish);
        break;
      case TaskType.loopsTracing:
        body = LoopsTracingTask(spec: spec, onDone: _finish);
        break;
      case TaskType.cubeCopy:
        body = CubeCopyTask(spec: spec, onDone: _finish);
        break;
      case TaskType.countDots:
        body = CountDots(spec: spec, onDone: _finish);
        break;
      case TaskType.clockDraw:
        body = ClockDraw(spec: spec, onDone: _finish);
        break;
      case TaskType.huntingLetters:
        body = HuntingLettersTask(spec: spec, onDone: _finish);
        break;
      case TaskType.nameAddressDelayed:
        body = NameAddressDelayedTask(spec: spec, onDone: _finish);
        break;
      case TaskType.nameAddressRecognize:
        body = NameAddressRecognizeTask(spec: spec, onDone: _finish);
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.index + 1}/${kAceTasks.length}'),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.exit_to_app, color: AppColors.primary),
            label: const Text('Exit', style: TextStyle(color: AppColors.primary)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: body,
      ),
    );
  }
}
