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
  String selectedStage = 'Main Stage 1';
  int selectedDay = 1;

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
                                    _buildHeaderPill(selectedStage),

                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        iconColor: Colors.white,
                                        padding: const EdgeInsets.all(12),
                                        shape:
                                            const CircleBorder(), // Makes the button a perfect circle
                                        minimumSize:
                                            Size.zero, // Overrides default sizing to allow for a smaller button
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
                                  // Figure out which list of events to use based on the dropdown variable
                                  List<EventItem>? eventsForSelectedStage;

                                  eventsForSelectedStage =
                                      scheduleItem.eventsByStage[selectedStage];

                                  // 2. If there are no events for this time bracket on this stage, render nothing
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
                                          time: event.time,
                                          // '${event.time} - ${int.parse(event.time) + event.duration}',
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
