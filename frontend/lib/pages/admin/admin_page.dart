import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'edit_performance_page.dart';
import '../../data/timetable_data.dart';
import 'package:provider/provider.dart';
import '../../config/supabase_config.dart';
import './components/stage_selector_pill.dart';
import './components/performance_box.dart';
import 'package:http/http.dart' as http;

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  AdminPageState createState() => AdminPageState();
}

class AdminPageState extends State<AdminPage> {
  String selectedStage = ScheduleDataService.stageNames.first;
  int selectedDay = 1;
  Set<int> selectedPerformanceIds = {};

  @override
  Widget build(BuildContext context) {
    final scheduleService = Provider.of<ScheduleDataService>(context);
    final scheduleData =
        selectedDay == 1
            ? scheduleService.day1ScheduleData
            : scheduleService.day2ScheduleData;

    List<EventItem> sortedStageEvents =
        scheduleData
            .expand(
              (item) => item.eventsByStage[selectedStage] ?? <EventItem>[],
            )
            .where((event) => event.performanceName.isNotEmpty)
            .toList();

    // Sort events in chronological order
    sortedStageEvents.sort((a, b) => a.time.compareTo(b.time));

    final Map<String, String> stageOptions = {
      for (String stageName in ScheduleDataService.stageNames)
        stageName: stageName,
    };

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: FractionallySizedBox(
            widthFactor: 0.9,
            heightFactor: 0.95,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 1, label: Text('Day 1')),
                    ButtonSegment(value: 2, label: Text('Day 2')),
                  ],
                  selected: {selectedDay},
                  onSelectionChanged: (Set<int> newSelection) {
                    setState(() {
                      selectedDay = newSelection.first;
                    });
                  },
                  style: SegmentedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    selectedBackgroundColor: Colors.black,
                    selectedForegroundColor: Colors.white,
                    iconColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    // FIX: Replaced the outer SingleChildScrollView and Row with just the Column
                    child: Column(
                      children: [
                        // 1. FIXED HEADER
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StageSelectorPill(
                              selectedValue: selectedStage,
                              options: stageOptions,
                              onSelected: (String newValue) {
                                setState(() {
                                  selectedStage = newValue;
                                });
                              },
                            ),
                            ElevatedButton(
                              onPressed:
                                  selectedPerformanceIds.isEmpty
                                      ? null
                                      : () => _showDelayDialog(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[800],
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey[300],
                                disabledForegroundColor: Colors.grey[500],
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 17.5,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                ),
                              ),
                              child: const Text("Delay"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 2. SCROLLABLE MIDDLE SECTION
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                ...sortedStageEvents.map((event) {
                                  return PerformanceBox(
                                    key: ValueKey(event.id),
                                    title: event.performanceName,
                                    startTime: event.time,
                                    duration: event.duration,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder:
                                              (context) => EditPerformancePage(
                                                existingData: event,
                                              ),
                                        ),
                                      );
                                    },
                                    isChecked: selectedPerformanceIds.contains(
                                      event.id,
                                    ),
                                    onCheckboxChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          selectedPerformanceIds.add(event.id);
                                        } else {
                                          selectedPerformanceIds.remove(
                                            event.id,
                                          );
                                        }
                                      });
                                    },
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) => const EditPerformancePage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              backgroundColor: Colors.grey[800],
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              "Add Performance",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Popup dialogue when delay button is clicked
  Future<void> _showDelayDialog(BuildContext context) async {
    int hours = 0;
    int minutes = 0;

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delay Performances"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: "Hours to delay"),
                keyboardType: TextInputType.number,
                onChanged: (value) => hours = int.tryParse(value) ?? 0,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: "Minutes to delay",
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => minutes = int.tryParse(value) ?? 0,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                _processDelay(hours, minutes); // Call the backend logic
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  // Process delay with call to backend
  Future<void> _processDelay(int hours, int minutes) async {
    final baseUrl = dotenv.env['API_URL_CHROME']!;
    final url = Uri.parse('$baseUrl/api/schedule/delay');
    final session = supabase.auth.currentSession;
    final jwt = session?.accessToken;

    if (hours == 0 && minutes == 0) return; // Prevent unnecessary calls

    int totalMinutes = hours * 60 + minutes;
    List<int> idsList = selectedPerformanceIds.toList();

    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'ids': idsList, 'minutes': totalMinutes}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              idsList.length == 1
                  ? "Successfully delayed performance"
                  : "Successfully delayed performances",
            ),
          ),
        );

        // 1. Manually fetch the new, correctly sorted data and WAIT for it to finish
        if (context.mounted) {
          await Provider.of<ScheduleDataService>(
            context,
            listen: false,
          ).refreshAllData();
        }

        // 2. ONLY clear the UI selection after the fresh data has arrived
        if (context.mounted) {
          setState(() {
            selectedPerformanceIds.clear();
          });
        }
      }
    } catch (e) {
      // Handle backend errors
      print("Error updating performances: $e");
    }
  }
}
