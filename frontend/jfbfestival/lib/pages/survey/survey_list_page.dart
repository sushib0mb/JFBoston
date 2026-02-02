import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/survey_entry.dart';

class SurveyListPage extends StatelessWidget {
  static const routeName = '/surveyList';
  const SurveyListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<SurveyEntry>('survey');

    return Scaffold(
      appBar: AppBar(title: const Text('Collected Surveys')),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (_, __, ___) {
          final entries = box.values.toList().cast<SurveyEntry>();
          if (entries.isEmpty) {
            return const Center(child: Text('No feedback submitted yet.'));
          }
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (_, i) {
              final e = entries[i];
              return ListTile(
                title: Text(
                  '${e.timestamp}: Usability ${e.usabilityRating}, Features ${e.featureRating}'
                ),
                subtitle: Text(e.comments),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => box.deleteAt(i),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
