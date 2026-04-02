import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'edit_performance_page.dart';
import '../../data/timetable_data.dart';
import 'package:provider/provider.dart';
import '../../utils/time_utils.dart';
import '../../config/supabase_config.dart';
import 'package:http/http.dart' as http;

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  AdminPageState createState() => AdminPageState();
}

class AdminPageState extends State<AdminPage> {
  String selectedStage = 'Main Stage 1';
  int selectedDay = 1;
  Set<int> selectedPerformanceIds = {};

  @override
  Widget build(BuildContext context) {
    final scheduleService = Provider.of<ScheduleDataService>(context);
    final scheduleData =
        selectedDay == 1
            ? scheduleService.day1ScheduleData
            : scheduleService.day2ScheduleData;

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

                SizedBox(height: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: SingleChildScrollView(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _stageSelectorPill(selectedStage),

                                    ElevatedButton(
                                      // If the set is empty, onPressed is null (disables the button)
                                      onPressed:
                                          selectedPerformanceIds.isEmpty
                                              ? null
                                              : () => _showDelayDialog(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[800],
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor:
                                            Colors.grey[300],
                                        disabledForegroundColor:
                                            Colors.grey[500],
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 17.5,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            9999,
                                          ),
                                        ),
                                        textStyle: const TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 14,
                                        ),
                                      ),
                                      child: const Text("Delay Performance"),
                                    ),

                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        iconColor: Colors.white,
                                        padding: const EdgeInsets.all(12),
                                        shape: const CircleBorder(),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    const EditPerformancePage(),
                                          ),
                                        );
                                      },
                                      child: const Icon(Icons.add, size: 24),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Dynamically populate the events based on the selected stage
                                ...scheduleData.expand((scheduleItem) {
                                  List<EventItem>? eventsForSelectedStage;

                                  eventsForSelectedStage =
                                      scheduleItem.eventsByStage[selectedStage];

                                  // If there are no events for this time bracket on this stage, render nothing
                                  if (eventsForSelectedStage == null) {
                                    return <Widget>[];
                                  }

                                  // Filter out the empty placeholder events and map the real ones to UI
                                  return eventsForSelectedStage
                                      .where(
                                        (event) =>
                                            event.performanceName.isNotEmpty,
                                      )
                                      .map((event) {
                                        return _buildPerformanceBox(
                                          title: event.performanceName,
                                          startTime: event.time,
                                          duration: event.duration,
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        EditPerformancePage(
                                                          existingData: event,
                                                        ),
                                              ),
                                            );
                                          },
                                          isChecked: selectedPerformanceIds
                                              .contains(event.id),

                                          onCheckboxChanged: (bool? value) {
                                            setState(() {
                                              if (value == true) {
                                                selectedPerformanceIds.add(
                                                  event.id,
                                                );
                                              } else {
                                                selectedPerformanceIds.remove(
                                                  event.id,
                                                );
                                              }
                                            });
                                          },
                                        );
                                      });
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  Widget _stageSelectorPill(String text) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800], // Dark pill background for contrast
        borderRadius: BorderRadius.circular(9999), // Perfect pill shape
      ),
      child: PopupMenuButton<String>(
        initialValue: selectedStage,
        // Pushes the dropdown menu items down
        offset: const Offset(0, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.grey[900],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17.5, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedStage,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white),
            ],
          ),
        ),
        onSelected: (String newValue) {
          setState(() {
            selectedStage = newValue;
          });
        },
        itemBuilder:
            (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'Main Stage 1',
                child: Text(
                  'Main Stage 1',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'Downtown Stage 1',
                child: Text(
                  'Downtown 1',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'Downtown Stage 2',
                child: Text(
                  'Downtown 2',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
      ),
    );
  }

  // Helper method to create the Clickable Performance Boxes
  Widget _buildPerformanceBox({
    required String title,
    required String startTime,
    required int duration,
    required VoidCallback onTap,
    required bool isChecked,
    required ValueChanged<bool?> onCheckboxChanged,
  }) {
    String endTime = findEndTime(startTime, duration);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Checkbox added on the left
                  Checkbox(
                    value: isChecked,
                    onChanged: onCheckboxChanged,
                    activeColor:
                        Colors.blue, // Feel free to customize the color
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$startTime - $endTime",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Click Indicator Arrow
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
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
      }

      // Once finished, clear the selection and rebuild the UI
      setState(() {
        selectedPerformanceIds.clear();
      });
    } catch (e) {
      // Handle backend errors
      print("Error updating performances: $e");
    }
  }
}
