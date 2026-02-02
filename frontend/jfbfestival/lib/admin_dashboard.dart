import 'package:flutter/material.dart';
import '../../config/supabase_config.dart';

class AdminDashboardPage extends StatelessWidget {
  static const routeName = '/admin';
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // real‑time stream of the whole `surveys` table
    final Stream<List<Map<String, dynamic>>> surveyStream = supabase
        .from('survey')
        .stream(
          primaryKey: ['id'],
        ) // 🔄 real‑time :contentReference[oaicite:1]{index=1}
        .order('timestamp', ascending: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Survey Dashboard')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: surveyStream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rows = snap.data!;
          final total = rows.length;

          final Map<int, int> usability = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
          final Map<int, int> features = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

          for (final r in rows) {
            final u = r['usability'] as int?;
            final f = r['features'] as int?;
            if (u != null) usability[u] = usability[u]! + 1;
            if (f != null) features[f] = features[f]! + 1;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Total submissions: $total',
                style: const TextStyle(fontSize: 18),
              ),

              const SizedBox(height: 16),
              const Text(
                'Usability ratings',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...usability.entries.map((e) => Text('${e.key}: ${e.value}')),

              const SizedBox(height: 24),
              const Text(
                'Feature ratings',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...features.entries.map((e) => Text('${e.key}: ${e.value}')),

              const SizedBox(height: 24),
              const Text(
                'Comments',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...rows.map(
                (r) => ListTile(
                  leading: Text(r['usability']?.toString() ?? ''),
                  title: Text(r['comments'] ?? ''),
                  subtitle: Text(r['timestamp']?.toString() ?? ''),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
