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

  // ── Fixed layout constants — no screen-size math ──────────────────────────
  static const double _dayBtnHeight           = 68.0;
  static const double _dayBtnWidth            = 156.0;
  static const double _dayFont                = 40.0;
  static const double _dayPickerHorizontalPad = 20.0;
  static const double _dayPickerTopPad        = 4.0;
  static const double _scheduleTopExtra       = 16.0;
  static const double _scheduleMargin         = 25.0;
  static const double _scheduleRadius         = 25.0;
  static const double _stageFontSize          = 12.0;
  static const double _stageDistFontSize      = 9.0;
  static const double _pixelsPerMinute        = 10.0;

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

  // ── isTablet() removed — uses _pixelsPerMinute constant directly ──────────
  void _scrollToEventTime(String time) {
    final start = parseTimeToMinutes(time);
    const base = 660; // 11:00 in minutes
    final offset = (start - base) * _pixelsPerMinute;
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── No w, h, tablet, dayBtnHeight, dayBtnWidth, dayFont variables ─────
    final svc = Provider.of<ScheduleDataService>(context);
    final schedule =
        selectedDay == 1 ? svc.day1ScheduleData : svc.day2ScheduleData;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: (isShowingDetail && _fromHomeTap)
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: const BackButton(color: Colors.white),
            )
          : null,
      body: Stack(
        children: [
          // Background gradient
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

          // ── SafeArea replaces manual MediaQuery.of(context).padding.top ──
          SafeArea(
            child: Stack(
              children: [
                // Day selectors — const EdgeInsets replaces w/h multiplications
                Positioned(
                  left: _dayPickerHorizontalPad,
                  top: _dayPickerTopPad,
                  child: _dayPicker('Day 1', 1),
                ),
                Positioned(
                  right: _dayPickerHorizontalPad,
                  top: _dayPickerTopPad,
                  child: _dayPicker('Day 2', 2),
                ),

                // Schedule content
                Column(
                  children: [
                    // Fixed spacing below day buttons — no h * 0.015 math
                    const SizedBox(
                      height: _dayBtnHeight + _scheduleTopExtra,
                    ),
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
                            // Stage selector buttons
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Row(
                                children: List.generate(
                                  _stageNames.length,
                                  (i) {
                                    final isSelected =
                                        selectedStage == _stageNames[i];
                                    final loc = context.watch<LocationService>();
                                    final dist =
                                        loc.formatDistance(_stageNames[i]);
                                    return Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(
                                          () => selectedStage = _stageNames[i],
                                        ),
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFF0B3775)
                                                : const Color(0xFF8D8D97),
                                            borderRadius:
                                                BorderRadius.circular(36),
                                          ),
                                          alignment: Alignment.center,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                _stageLabels[i],
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  // Fixed const — tablet?15:12 removed
                                                  fontSize: _stageFontSize,
                                                  fontWeight: isSelected
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
                                                    // Fixed const — tablet?11:9 removed
                                                    fontSize:
                                                        _stageDistFontSize,
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
                                  },
                                ),
                              ),
                            ),

                            // Schedule list
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

          // Event detail overlay
          if (isShowingDetail && selectedEvent != null)
            EventDetailPopup(
              event: selectedEvent!,
              onClose: () => setState(() => isShowingDetail = false),
            ),
        ],
      ),
    );
  }

  // ── _dayPicker: removed w/h/fs params — uses static const directly ────────
  // ── isTablet scaling inside removed ──────────────────────────────────────
  Widget _dayPicker(String text, int day) {
    return GestureDetector(
      onTap: () => setState(() {
        selectedDay = day;
        if (day == 2) selectedStage = 'Main Stage';
      }),
      child: Container(
        width: _dayBtnWidth,
        height: _dayBtnHeight,
        alignment:
            day == 1 ? const Alignment(-0.3, 0) : const Alignment(0.3, 0),
        decoration: ShapeDecoration(
          color: day == 1
              ? selectedDay == day
                  ? const Color.fromARGB(38, 191, 29, 35)
                  : const Color.fromARGB(175, 224, 224, 224)
              : selectedDay == day
                  ? const Color.fromARGB(38, 11, 55, 117)
                  : const Color.fromARGB(175, 224, 224, 224),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
            side: day == 1
                ? selectedDay == day
                    ? const BorderSide(
                        color: Color.fromARGB(255, 191, 29, 35),
                        width: 2,
                      )
                    : const BorderSide(color: Colors.transparent, width: 2)
                : selectedDay == day
                    ? const BorderSide(
                        color: Color.fromARGB(255, 11, 55, 117),
                        width: 2,
                      )
                    : const BorderSide(color: Colors.transparent, width: 2),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: _dayFont,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
  // ── _buildStageButtons removed — was defined but never called (dead code) ──
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

  // ── Fixed constants — no screenWidth math ─────────────────────────────────
  static const double _timeColumnWidth = 52.0;   // was screenWidth * 0.14
  static const double _timeFontSize    = 14.0;   // was 16.0 * (screenWidth / 375)
  static const double _pixelsPerMinute = 10.0;

  @override
  Widget build(BuildContext context) {
    // ── screenWidth, baseFontSize, responsiveFontSize removed ────────────
    if (scheduleItems.isEmpty) return const SizedBox.shrink();

    final timelineSlots = scheduleItems.map((item) => item.time).toList();
    final baseTime = parseTimeToMinutes(timelineSlots.first);

    int latestEventEndTime = baseTime;
    for (var item in scheduleItems) {
      final itemStartTime = parseTimeToMinutes(item.time);
      for (var eventList in item.eventsByStage.values) {
        for (var event in eventList) {
          final eventEndTime = itemStartTime + event.duration;
          if (eventEndTime > latestEventEndTime) {
            latestEventEndTime = eventEndTime;
          }
        }
      }
    }

    final latestTime = latestEventEndTime + 35;
    final timelineHeight = (latestTime - baseTime) * _pixelsPerMinute;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Time column: fixed _timeColumnWidth replaces screenWidth * 0.14 ─
        Padding(
          padding: const EdgeInsets.only(left: 13),
          child: SizedBox(
            width: _timeColumnWidth,
            height: timelineHeight,
            child: Stack(
              children: timelineSlots.map((timeString) {
                final timeInMinutes = parseTimeToMinutes(timeString);
                final displayLabel = _minutesToDisplayFormat(timeInMinutes);
                final timeParts = displayLabel.split(" ");
                final timeText =
                    timeParts.isNotEmpty ? timeParts[0] : displayLabel;
                final ampm = timeParts.length > 1 ? timeParts[1] : "";
                final topPosition =
                    (timeInMinutes - baseTime) * _pixelsPerMinute;

                return Positioned(
                  top: topPosition,
                  left: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeText,
                        // Fixed const — responsiveFontSize removed
                        style: const TextStyle(
                          fontSize: _timeFontSize,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      Text(
                        ampm,
                        style: const TextStyle(
                          fontSize: _timeFontSize,
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
                // ── width param removed — it was passed but never used ────
                _buildTimelineLines(
                  baseTime: baseTime,
                  latestTime: latestTime,
                ),
                SizedBox(
                  height: timelineHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: _buildEventColumn(
                      stageName,
                      _pixelsPerMinute,
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

  // ── width parameter removed — was never used inside the function ──────────
  Widget _buildTimelineLines({
    required int baseTime,
    required int latestTime,
  }) {
    final List<Widget> lines = [];
    for (int t = baseTime; t <= latestTime; t += 30) {
      final top = (t - baseTime) * _pixelsPerMinute;
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
    final events = scheduleItems
        .expand((item) => item.eventsByStage[stageName] ?? [])
        .where((e) => e.performanceName.isNotEmpty)
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    return [
      for (var i = 0; i < events.length; i++)
        Positioned(
          top: (parseTimeToMinutes(events[i].time) - baseTime) *
                  pixelsPerMinute +
              4,
          left: 3,
          right: 3,
          child: SizedBox(
            height: events[i].duration * pixelsPerMinute - 4,
            child: Performance(eventItem: events[i], onTap: onEventTap),
          ),
        ),
    ];
  }
}

String _minutesToDisplayFormat(int minutes) {
  final hour = minutes ~/ 60;
  final minute = minutes % 60;
  final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
  final meridiem = hour >= 12 ? 'pm' : 'am';
  return '${displayHour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')} $meridiem';
}