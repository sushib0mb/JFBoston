import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/timetable_data.dart';
import '../../services/location_service.dart';
import '../../utils/time_utils.dart';
import 'components/event_detail_popup.dart';
import 'components/performance.dart';

class TimetablePage extends StatefulWidget {
  final EventItem? selectedEvent;
  final int? selectedDay;
  final String? initialStage;
  final bool isVisible;

  const TimetablePage({
    super.key,
    this.selectedEvent,
    this.selectedDay,
    this.initialStage,
    this.isVisible = true,
  });

  @override
  _TimetablePageState createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  int selectedDay = 1;
  String selectedStage = 'Main Stage';
  EventItem? selectedEvent;
  bool isShowingDetail = false;
  bool _hasAutoScrolled = false;
  late ScrollController _scrollController;

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

  // ── Layout Constants ──────────────────────────────────────────────────────
  static const double _dayBtnHeight = 68.0;
  static const double _dayBtnWidth = 221.0;
  static const double _dayFont = 40.0;
  static const double logoSize = 68;
  static const double _dayPickerTopPad = 4.0;
  static const double _dayPickerMargin = 25;
  static const double _scheduleTopExtra = 16.0;
  static const double _scheduleMargin = 25.0;
  static const double _scheduleRadius = 25.0;
  static const double _stageFontSize = 10.0;
  static const double _stageDistFontSize = 9.0;
  static const double _pixelsPerMinute = 10.0;

  @override
  void initState() {
    super.initState();
    if (widget.selectedDay != null) selectedDay = widget.selectedDay!;
    if (widget.initialStage != null) selectedStage = widget.initialStage!;
    _scrollController = ScrollController();

    if (widget.selectedEvent != null) {
      selectedEvent = widget.selectedEvent;
      isShowingDetail = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasAutoScrolled) return;
    final svc = Provider.of<ScheduleDataService>(context);
    final schedule = selectedDay == 1 ? svc.day1ScheduleData : svc.day2ScheduleData;
    if (schedule.isEmpty) return;
    _hasAutoScrolled = true;
    final baseTime = parseTimeToMinutes(schedule.first.time);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.selectedEvent != null) {
        _scrollToEventTime(widget.selectedEvent!.time);
      } else {
        _scrollToCurrentTime(baseTime);
      }
    });
  }

  void _scrollToEventTime(String time) {
    final start = parseTimeToMinutes(time);
    const base = 660; // 11:00 AM reference
    final offset = (start - base) * _pixelsPerMinute;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        offset.clamp(0.0, double.infinity),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToCurrentTime(int baseTime) {
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted || !_scrollController.hasClients) return;
      final viewportHeight = _scrollController.position.viewportDimension;
      final redLinePosition = (nowMinutes - baseTime) * _pixelsPerMinute;
      final offset = (redLinePosition - viewportHeight / 3).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void didUpdateWidget(TimetablePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      final svc = Provider.of<ScheduleDataService>(context, listen: false);
      final schedule = selectedDay == 1 ? svc.day1ScheduleData : svc.day2ScheduleData;
      if (schedule.isNotEmpty) {
        _scrollToCurrentTime(parseTimeToMinutes(schedule.first.time));
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = Provider.of<ScheduleDataService>(context);
    final schedule =
        selectedDay == 1 ? svc.day1ScheduleData : svc.day2ScheduleData;

    // Logic from Version 1: Filter stages based on day
    final currentStageNames = selectedDay == 1 ? _stageNames : [_stageNames[0]];
    final currentStageLabels =
        selectedDay == 1 ? _stageLabels : [_stageLabels[0]];

    return Scaffold(
      backgroundColor: const Color(0xFFECE0CF),
      body: Stack(
        children: [
          // Background
          Container(color: const Color(0xFFECE0CF)),

          SafeArea(
            child: Stack(
              children: [
                // Day Selectors
                // Day Selectors
                Positioned(
                  left: 0.0,
                  right: 0.0,
                  top: _dayPickerTopPad,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate the exact width: half the screen + your 34px overlap
                      final buttonWidth =
                          (constraints.maxWidth / 2) +
                          logoSize / 2 -
                          _dayPickerMargin;

                      return SizedBox(
                        height: _dayBtnHeight,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 25,
                              width: buttonWidth,
                              child: _dayPicker('Day 1', 1),
                            ),
                            Positioned(
                              right: 25,
                              width: buttonWidth,
                              child: _dayPicker('Day 2', 2),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Schedule Content
                Column(
                  children: [
                    const SizedBox(height: _dayBtnHeight + _scheduleTopExtra),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(_scheduleMargin),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(_scheduleRadius),
                          gradient: const LinearGradient(
                            colors: [Color(0x260A3875), Color(0x26BF1C24)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Stage Selector
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Row(
                                children: List.generate(
                                  currentStageNames.length,
                                  (i) {
                                    final isSelected =
                                        selectedStage == currentStageNames[i];
                                    final loc =
                                        context.watch<LocationService>();
                                    final dist = loc.formatDistance(
                                      currentStageNames[i],
                                    );
                                    return Expanded(
                                      child: GestureDetector(
                                        onTap:
                                            () => setState(
                                              () =>
                                                  selectedStage =
                                                      currentStageNames[i],
                                            ),
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? const Color(0xFFBF1D23)
                                                    : const Color(0xFFD4706E),
                                            borderRadius: BorderRadius.circular(
                                              36,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                currentStageLabels[i],
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: _stageFontSize,
                                                  fontWeight:
                                                      isSelected
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (dist.isNotEmpty)
                                                Text(
                                                  dist,
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize:
                                                        _stageDistFontSize,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            // Main Schedule List
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
                if (selectedEvent != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToEventTime(selectedEvent!.time);
                  });
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _dayPicker(String text, int day) {
    bool isSelected = selectedDay == day;
    return GestureDetector(
      onTap:
          () => setState(() {
            selectedDay = day;
            if (day == 2) selectedStage = 'Main Stage';
          }),
      child: Container(
        width: _dayBtnWidth,
        height: _dayBtnHeight,
        alignment:
            day == 1 ? const Alignment(-0.2, 0) : const Alignment(0.2, 0),
        decoration: ShapeDecoration(
          color:
              isSelected
                  ? const Color(0x26BF1D23)
                  : const Color.fromARGB(173, 197, 195, 195),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
            side: BorderSide(
              color: isSelected ? const Color(0xFFBF1D23) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Padding(
          // Fixes the text being weirdly too low
          padding: const EdgeInsets.only(top: 5.0),
          child: Text(
            text,
            style: GoogleFonts.bebasNeue(
              fontSize: _dayFont,
              fontWeight: FontWeight.w400,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class ScheduleList extends StatefulWidget {
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
  State<ScheduleList> createState() => _ScheduleListState();
}

class _ScheduleListState extends State<ScheduleList> {
  static const double _timeColumnWidth = 52.0;
  static const double _timeFontSize = 14.0;
  static const double _pixelsPerMinute = 10.0;
  static const double _timeColumnLeftPad = 13.0;

  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _nowMinutes => _now.hour * 60 + _now.minute;

  @override
  Widget build(BuildContext context) {
    if (widget.scheduleItems.isEmpty) return const SizedBox.shrink();

    final timelineSlots = widget.scheduleItems.map((item) => item.time).toList();
    final baseTime = parseTimeToMinutes(timelineSlots.first);

    int latestEventEndTime = baseTime;
    for (var item in widget.scheduleItems) {
      final itemStartTime = parseTimeToMinutes(item.time);
      final events = item.eventsByStage[widget.stageName] ?? [];
      for (var event in events) {
        final end = itemStartTime + event.duration;
        if (end > latestEventEndTime) latestEventEndTime = end;
      }
    }

    final latestTime = latestEventEndTime + 35;
    final timelineHeight = (latestTime - baseTime) * _pixelsPerMinute;

    final nowMinutes = _nowMinutes;
    final bool showNowLine = nowMinutes >= baseTime && nowMinutes <= latestTime;
    final double nowTop = (nowMinutes - baseTime) * _pixelsPerMinute;

    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: _timeColumnLeftPad),
              child: SizedBox(
                width: _timeColumnWidth,
                height: timelineHeight,
                child: Stack(
                  children:
                      timelineSlots.map((timeString) {
                        final timeInMinutes = parseTimeToMinutes(timeString);
                        final displayLabel = _minutesToDisplayFormat(timeInMinutes);
                        final parts = displayLabel.split(" ");
                        return Positioned(
                          top: (timeInMinutes - baseTime) * _pixelsPerMinute,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                parts[0],
                                style: const TextStyle(
                                  fontSize: _timeFontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (parts.length > 1)
                                Text(
                                  parts[1],
                                  style: const TextStyle(fontSize: _timeFontSize),
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
                  children: [
                    _buildTimelineLines(baseTime, latestTime),
                    ..._buildEvents(baseTime),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (showNowLine)
          Positioned(
            top: nowTop,
            left: 0,
            right: 0,
            child: Row(
              children: [
                const SizedBox(width: _timeColumnLeftPad + _timeColumnWidth - 5),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Container(height: 2, color: Colors.red),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTimelineLines(int baseTime, int latestTime) {
    List<Widget> lines = [];
    for (int t = baseTime; t <= latestTime; t += 30) {
      lines.add(
        Positioned(
          top: (t - baseTime) * _pixelsPerMinute,
          left: 4,
          right: 12,
          child: Container(height: 1, color: Colors.black26),
        ),
      );
    }
    return Stack(children: lines);
  }

  List<Widget> _buildEvents(int baseTime) {
    final events =
        widget.scheduleItems
            .expand((item) => item.eventsByStage[widget.stageName] ?? [])
            .where((e) => e.performanceName.isNotEmpty)
            .toList();

    return events.map((e) {
      final top =
          (parseTimeToMinutes(e.time) - baseTime) * _pixelsPerMinute + 4;
      return Positioned(
        top: top,
        left: 3,
        right: 20,
        child: SizedBox(
          height: (e.duration * _pixelsPerMinute) - 4,
          child: Performance(eventItem: e, onTap: widget.onEventTap),
        ),
      );
    }).toList();
  }

  String _minutesToDisplayFormat(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final meridiem = hour >= 12 ? 'pm' : 'am';
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $meridiem';
  }
}
