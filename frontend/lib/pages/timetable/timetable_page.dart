import 'package:flutter/material.dart';
import '../../data/timetable_data.dart';
import '../../services/location_service.dart';
import 'components/event_detail_popup.dart';
import 'components/performance.dart';
import 'package:provider/provider.dart';
import '../../utils/time_utils.dart';

class TimetablePage extends StatefulWidget {
  final EventItem? selectedEvent;
  final int? selectedDay;

  const TimetablePage({super.key, this.selectedEvent, this.selectedDay});

  @override
  _TimetablePageState createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  int selectedDay = 1;
  String selectedStage = 'Main Stage';
  EventItem? selectedEvent;
  bool isShowingDetail = false;
  late ScrollController _scrollController;
  bool _fromHomeTap = true;

  static const List<String> _stageNames = [
    'Main Stage',
    'Sakura Stage',
    'Fuji Stage',
  ];
  static const List<String> _stageLabels = [
    'Boston Common',
    'Sakura Stage',
    'Fuji Stage',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.selectedDay != null) selectedDay = widget.selectedDay!;
    _scrollController = ScrollController();
    if (widget.selectedEvent != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _highlightSelectedEvent(widget.selectedEvent!);
      });
    }
  }

  void _highlightSelectedEvent(EventItem selected) {
    final svc = Provider.of<ScheduleDataService>(context, listen: false);
    final schedule =
        selectedDay == 1 ? svc.day1ScheduleData : svc.day2ScheduleData;

    for (var slot in schedule) {
      final eventsForStage = slot.eventsByStage[selected.stage];

      if (eventsForStage != null) {
        for (var e in eventsForStage) {
          if (e.performanceName == selected.performanceName &&
              e.time == selected.time) {
            setState(() {
              selectedEvent = e;
              isShowingDetail = true;
            });
            _scrollToEventTime(e.time);
            return;
          }
        }
      }
    }
  }

  void _scrollToEventTime(String time) {
    // Parse time in HH:MM format to minutes
    var start = parseTimeToMinutes(time);
    // Use 11:00 as base reference (11*60 = 660 minutes)
    var base = 660; // 11:00 in minutes
    var offset = (start - base) * (isTablet(context) ? 12.0 : 10.0);
    _scrollController.animateTo(
      offset,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool isTablet(BuildContext c) => MediaQuery.of(c).size.width >= 600;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final tablet = isTablet(context);

    // Day buttons adapt
    final dayBtnHeight = h * (tablet ? 0.10 : 0.082);
    final dayBtnWidth = w * (tablet ? 0.4 : 0.52);
    final dayFont = tablet ? 48.0 : 40.0;
    final topPad = dayBtnHeight;

    final svc = Provider.of<ScheduleDataService>(context);
    final schedule =
        selectedDay == 1 ? svc.day1ScheduleData : svc.day2ScheduleData;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar:
          (isShowingDetail && _fromHomeTap)
              ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: BackButton(color: Colors.white),
              )
              : null,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0B3775).withValues(alpha: 0.15),
                  const Color(0xFFBF1D23).withValues(alpha: 0.15),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Stack(
              children: [
                // Day selectors
                Positioned(
                  left: w * 0.06,
                  top: h * 0.002,
                  child: _dayPicker(
                    'Day 1',
                    1,
                    dayBtnWidth,
                    dayBtnHeight,
                    dayFont,
                  ),
                ),
                Positioned(
                  right: w * 0.06,
                  top: h * 0.002,
                  child: _dayPicker(
                    'Day 2',
                    2,
                    dayBtnWidth,
                    dayBtnHeight,
                    dayFont,
                  ),
                ),
                // Schedule list
                Column(
                  children: [
                    SizedBox(height: topPad + h * 0.015),
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.all(tablet ? 32 : 25),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(tablet ? 32 : 25),
                          gradient: LinearGradient(
                            colors: [Color(0x260A3875), Color(0x26BF1C24)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Row(
                                children: List.generate(_stageNames.length, (
                                  i,
                                ) {
                                  final isSelected =
                                      selectedStage == _stageNames[i];
                                  final loc = context.watch<LocationService>();
                                  final dist = loc.formatDistance(
                                    _stageNames[i],
                                  );
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap:
                                          () => setState(
                                            () =>
                                                selectedStage = _stageNames[i],
                                          ),
                                      child: Container(
                                        margin: EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              isSelected
                                                  ? const Color(0xFF0B3775)
                                                  : const Color(0xFF8D8D97),
                                          borderRadius: BorderRadius.circular(
                                            36,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _stageLabels[i],
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: tablet ? 15 : 12,
                                                fontWeight:
                                                    isSelected
                                                        ? FontWeight.w700
                                                        : FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                            if (dist.isNotEmpty)
                                              Text(
                                                dist,
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.85),
                                                  fontSize: tablet ? 11 : 9,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                child: ScheduleList(
                                  scheduleItems: schedule,
                                  stageName: selectedStage,
                                  onEventTap: (e) {
                                    setState(() {
                                      selectedEvent = e;
                                      isShowingDetail = true;
                                      _fromHomeTap = false;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isShowingDetail && selectedEvent != null)
            EventDetailPopup(
              event: selectedEvent!,
              onClose: () {
                setState(() => isShowingDetail = false);
              },
            ),
        ],
      ),
    );
  }

  Widget _dayPicker(String text, int day, double w, double h, double fs) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    // scale up a bit on tablets
    final width = isTablet ? w * 1.2 : w;
    final height = isTablet ? h * 1.2 : h;
    final font = isTablet ? fs * 1.2 : fs;

    return GestureDetector(
      onTap:
          () => setState(() {
            selectedDay = day;
            // Day 2 only has Boston Common
            if (day == 2) selectedStage = 'Main Stage';
          }),
      child: Container(
        width: width,
        height: height,
        alignment: day == 1 ? Alignment(-0.3, 0) : Alignment(0.3, 0),
        decoration: ShapeDecoration(
          color:
              day == 1
                  ? selectedDay == day
                      ? const Color.fromARGB(38, 191, 29, 35)
                      : const Color.fromARGB(175, 224, 224, 224)
                  : selectedDay == day
                  ? const Color.fromARGB(38, 11, 55, 117)
                  : const Color.fromARGB(175, 224, 224, 224),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
            side:
                day == 1
                    ? selectedDay == day
                        ? BorderSide(
                          color: Color.fromARGB(255, 191, 29, 35),
                          width: 2,
                        )
                        : BorderSide(color: Colors.transparent, width: 2)
                    : selectedDay == day
                    ? BorderSide(
                      color: Color.fromARGB(255, 11, 55, 117),
                      width: 2,
                    )
                    : BorderSide(color: Colors.transparent, width: 2),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: font, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }

  Widget _buildStageButtons(BuildContext context, bool tablet) {
    final loc = context.watch<LocationService>();
    final names = selectedDay == 1 ? _stageNames : [_stageNames[0]];
    final labels = selectedDay == 1 ? _stageLabels : [_stageLabels[0]];

    return Row(
      children: List.generate(names.length, (i) {
        final isSelected = selectedStage == names[i];
        final dist = loc.formatDistance(names[i]);
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => selectedStage = names[i]),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? const Color(0xFF0B3775)
                        : const Color(0xFF8D8D97),
                borderRadius: BorderRadius.circular(36),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    labels[i],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: tablet ? 13 : 10.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (dist.isNotEmpty)
                    Text(
                      dist,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: tablet ? 11 : 9,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class ScheduleList extends StatelessWidget {
  final List<ScheduleItem> scheduleItems;
  final void Function(EventItem) onEventTap;
  final String stageName;

  const ScheduleList({
    required this.scheduleItems,
    required this.onEventTap,
    required this.stageName,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseFontSize = 16.0;
    final responsiveFontSize = baseFontSize * (screenWidth / 375);
    final pixelsPerMinute = 10.0;

    // If scheduleItems is empty, return an empty container
    if (scheduleItems.isEmpty) {
      return Container();
    }

    // Get all bracket times from schedule items (these are the 30-min brackets)
    final timelineSlots = scheduleItems.map((item) => item.time).toList();
    final baseTime = parseTimeToMinutes(timelineSlots.first);

    // Get the last event's duration from both stages based on scheduleItems
    int latestEventEndTime = baseTime;

    for (var item in scheduleItems) {
      final itemStartTime = parseTimeToMinutes(item.time);

      for (var eventList in item.eventsByStage.values) {
        if (eventList.isEmpty) continue;

        for (var event in eventList) {
          final eventEndTime = itemStartTime + event.duration;

          if (eventEndTime > latestEventEndTime) {
            latestEventEndTime = eventEndTime;
          }
        }
      }
    }

    // Add padding to latest time
    final latestTime = latestEventEndTime + 35;
    final timelineHeight = (latestTime - baseTime) * pixelsPerMinute;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time Column
        Padding(
          padding: const EdgeInsets.only(left: 13),
          child: SizedBox(
            width: screenWidth * 0.14,
            height: timelineHeight, // Set explicit height for time column
            child: Stack(
              children:
                  timelineSlots.map((timeString) {
                    final timeInMinutes = parseTimeToMinutes(timeString);
                    final displayLabel = _minutesToDisplayFormat(timeInMinutes);
                    final timeParts = displayLabel.split(" ");
                    final timeText =
                        timeParts.isNotEmpty ? timeParts[0] : displayLabel;
                    final ampm = timeParts.length > 1 ? timeParts[1] : "";
                    final topPosition =
                        (timeInMinutes - baseTime) * pixelsPerMinute;

                    return Positioned(
                      top: topPosition,
                      left: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timeText,
                            style: TextStyle(
                              fontSize: responsiveFontSize,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          Text(
                            ampm,
                            style: TextStyle(
                              fontSize: responsiveFontSize,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),

        Expanded(
          child: SizedBox(
            height: timelineHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildTimelineLines(
                  baseTime: baseTime,
                  latestTime: latestTime,
                  pixelsPerMinute: pixelsPerMinute,
                  width: screenWidth,
                ),
                SizedBox(
                  height: timelineHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: _buildEventColumn(
                      stageName,
                      pixelsPerMinute,
                      baseTime,
                      latestTime,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineLines({
    required int baseTime,
    required int latestTime,
    required double pixelsPerMinute,
    required double width,
  }) {
    final List<Widget> lines = [];

    for (int t = baseTime; t <= latestTime; t += 30) {
      final top = (t - baseTime) * pixelsPerMinute;
      lines.add(
        Positioned(
          top: top,
          left: 0,
          right: 0,
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: const Color.fromARGB(8, 0, 0, 0),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 0),
                  blurRadius: 1,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(children: lines);
  }

  List<Widget> _buildEventColumn(
    String stageName,
    double pixelsPerMinute,
    int baseTime,
    int latestTime,
  ) {
    final events =
        scheduleItems
            .expand((item) => item.eventsByStage[stageName] ?? [])
            .where((e) => e.performanceName.isNotEmpty)
            .toList();
    // Sort events by time if needed
    events.sort((a, b) => a.time.compareTo(b.time));

    return [
      for (var i = 0; i < events.length; i++)
        Positioned(
          top:
              (parseTimeToMinutes(events[i].time) - baseTime) *
                  pixelsPerMinute +
              4,
          left: 3,
          right: 3,
          child: SizedBox(
            height: (events[i].duration) * pixelsPerMinute - 4,
            child: Performance(eventItem: events[i], onTap: onEventTap),
          ),
        ),
    ];
  }
}

// Convert minutes since midnight to HH:MM am/pm format
String _minutesToDisplayFormat(int minutes) {
  final hour = minutes ~/ 60;
  final minute = minutes % 60;

  final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
  final meridiem = hour >= 12 ? 'pm' : 'am';

  return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $meridiem';
}
