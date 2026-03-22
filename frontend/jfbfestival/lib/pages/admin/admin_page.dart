import 'package:flutter/material.dart';
import 'package:jfbfestival/pages/admin/edit_performance_page.dart';
import 'package:jfbfestival/data/timetable_data.dart';
import 'package:provider/provider.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  AdminPageState createState() => AdminPageState();
}

class AdminPageState extends State<AdminPage> {
  String selectedStage = 'Main Stage';

  @override
  Widget build(BuildContext context) {
    final scheduleService = Provider.of<ScheduleDataService>(context);
    final scheduleData = scheduleService.day1ScheduleData;

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
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: PopupMenuButton<String>(
                        initialValue: selectedStage,
                        // Pushes the dropdown menu items down
                        offset: const Offset(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Colors.grey[900],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 17.5,
                            vertical: 10,
                          ),
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
                              const SizedBox(
                                width: 8,
                              ), // Little space between text and arrow
                              const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white,
                              ),
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
                                value: 'Main Stage',
                                child: Text(
                                  'Main Stage',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'Downtown 1',
                                child: Text(
                                  'Downtown 1',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'Downtown 2',
                                child: Text(
                                  'Downtown 2',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                      ),
                    ),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.black, // The solid black background
                        foregroundColor:
                            Colors.white, // Makes the text white for contrast
                        padding: const EdgeInsets.symmetric(
                          horizontal: 17.5,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            12,
                          ), // Controls the roundness
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const EditPerformancePage(),
                          ),
                        );
                      },
                      child: const Text(
                        "Add Performance",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
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
                          // --- Main Column ---
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildHeaderPill(selectedStage),
                                const SizedBox(height: 16),

                                // Dynamically populate the events based on the selected stage
                                ...scheduleData.expand((scheduleItem) {
                                  // 1. Figure out which list of events to use based on the dropdown variable
                                  List<EventItem>? eventsForSelectedStage;

                                  switch (selectedStage) {
                                    case 'Main Stage':
                                      eventsForSelectedStage =
                                          scheduleItem.stage1Events;
                                      break;
                                    case 'Downtown 1':
                                      eventsForSelectedStage =
                                          scheduleItem.stage2Events;
                                      break;
                                    case 'Downtown 2':
                                      // Note: Your ScheduleDataService currently only processes 2 stages.
                                      // This will safely return empty until you add 'stage3Events' to your service!
                                      eventsForSelectedStage = [];
                                      break;
                                    default:
                                      eventsForSelectedStage =
                                          scheduleItem.stage1Events;
                                  }

                                  // 2. If there are no events for this time bracket on this stage, render nothing
                                  if (eventsForSelectedStage == null)
                                    return <Widget>[];

                                  // Filter out the empty placeholder events and map the real ones to UI
                                  return eventsForSelectedStage
                                      .where(
                                        (event) =>
                                            event.performanceName.isNotEmpty,
                                      )
                                      .map((event) {
                                        return _buildPerformanceBox(
                                          title: event.performanceName,
                                          time: event.time,
                                          onTap: () {
                                            // Navigate to details page here
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

  Widget _buildHeaderPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800], // Dark pill background for contrast
        borderRadius: BorderRadius.circular(9999), // Perfect pill shape
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  // Helper method to create the Clickable Performance Boxes
  Widget _buildPerformanceBox({
    required String title,
    required String time,
    required VoidCallback onTap,
  }) {
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
                  // Text Content wrapped in Expanded to prevent overflow on small screens
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
                          time,
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
}
