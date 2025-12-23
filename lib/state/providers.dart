import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';

final assessmentProvider = StateProvider<Assessment>((ref) {
  return Assessment(id: const Uuid().v4(), language: "ml", startedAt: DateTime.now());
});
