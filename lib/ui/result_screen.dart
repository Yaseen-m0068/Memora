import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models.dart';
import '../data/tasks.dart';
import '../scoring.dart';
import '../state/providers.dart';



class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(assessmentProvider);
    final sb = Scorebook();
    for (final r in a.responses) {
      final spec = kAceTasks.firstWhere((t) => t.id == r.taskId);
      sb.add(spec.domain, r.score);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Image.asset('assets/avatars/result.png', height: 260),
          Text('Total: ${sb.total} / 100', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          _row('Attention', sb.forDomain(Domain.attention), 18),
          _row('Memory', sb.forDomain(Domain.memory), 26),
          _row('Fluency', sb.forDomain(Domain.fluency), 14),
          _row('Language', sb.forDomain(Domain.language), 26),
          _row('Visuospatial', sb.forDomain(Domain.visuospatial), 16),
          const Spacer(),
          FilledButton.icon(
            onPressed: () {
              // TODO: generate PDF + share via share_plus; or forward to doctor (email/WhatsApp).
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share/report coming next.')));
            },
            icon: const Icon(Icons.share), label: const Text('Forward to doctor'),
          )
        ]),
      ),
    );
  }

  Widget _row(String name, int got, int max) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Expanded(child: Text(name)),
      Text('$got / $max'),
    ]),
  );
}
