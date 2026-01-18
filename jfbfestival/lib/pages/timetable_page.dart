import 'package:flutter/material.dart';
import 'package:jfbfestival/data/timetableData.dart';
import 'package:provider/provider.dart';

/// メインビュー：タイムテーブル
class TimetablePage extends StatefulWidget {
  final EventItem? selectedEvent;
  final int? selectedDay;

  const TimetablePage({Key? key, this.selectedEvent, this.selectedDay})
    : super(key: key);

  @override
  _TimetablePageState createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  int selectedDay = 1;
  EventItem? selectedEvent;
  bool isShowingDetail = false;
  late ScrollController _scrollController;
  bool _fromHomeTap = true;

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
      for (var e in [...?slot.stage1Events, ...?slot.stage2Events]) {
        if (e.performanceName == selected.performanceName &&
            e.time == selected.time &&
            e.stage == selected.stage) {
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

  int _parseTimeToMinutes(String s) {
    try {
      var parts = s.split(' ');
      var hm = parts[0].split(':');
      var h = int.parse(hm[0]);
      var m = hm.length > 1 ? int.parse(hm[1]) : 0;
      var pm = parts.length > 1 && parts[1].toLowerCase() == 'pm';
      if (pm && h < 12) h += 12;
      if (!pm && h == 12) h = 0;
      return h * 60 + m;
    } catch (_) {
      return 0;
    }
  }

  void _scrollToEventTime(String time) {
    // Parse time in HH:MM format to minutes
    var start = _parseTimeToMinutes(time);
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
      backgroundColor: Colors.white,
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
          Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Stack(
              children: [
                // Day selectors
                Positioned(
                  left: w * 0.06,
                  top: h * 0.002,
                  child: _dayButton(
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
                  child: _day2Button(
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
                              padding: EdgeInsets.only(
                                left: w * (tablet ? 0.12 : 0.1),
                              ),
                              child: _buildStageHeader(
                                fontSize: tablet ? 20 : 17,
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                child: ScheduleList(
                                  scheduleItems: schedule,
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
            EventDetailView(
              event: selectedEvent!,
              onClose: () {
                setState(() => isShowingDetail = false);
              },
            ),
        ],
      ),
    );
  }

  Widget _dayButton(String text, int day, double w, double h, double fs) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    // scale up a bit on tablets
    final width = isTablet ? w * 1.2 : w;
    final height = isTablet ? h * 1.2 : h;
    final font = isTablet ? fs * 1.2 : fs;

    return GestureDetector(
      onTap: () => setState(() => selectedDay = day),
      child: Container(
        width: width,
        height: height,
        alignment: Alignment(-0.3, 0),
        decoration: ShapeDecoration(
          color:
              selectedDay == day
                  ? const Color.fromARGB(38, 191, 29, 35)
                  : const Color.fromARGB(175, 224, 224, 224),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
            side:
                selectedDay == day
                    ? BorderSide(
                      color: Color.fromARGB(255, 191, 29, 35),
                      width: 2,
                    )
                    : BorderSide.none,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: font, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }

  Widget _day2Button(String text, int day, double w, double h, double fs) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    // scale up a bit on tablets
    final width = isTablet ? w * 1.2 : w;
    final height = isTablet ? h * 1.2 : h;
    final font = isTablet ? fs * 1.2 : fs;

    return GestureDetector(
      onTap: () => setState(() => selectedDay = day),
      child: Container(
        width: width,
        height: height,
        alignment: Alignment(0.3, 0),
        decoration: ShapeDecoration(
          color:
              selectedDay == day
                  ? const Color.fromARGB(38, 11, 55, 117)
                  : const Color.fromARGB(175, 224, 224, 224),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
            side:
                selectedDay == day
                    ? BorderSide(
                      color: Color.fromARGB(255, 11, 55, 117),
                      width: 2,
                    )
                    : BorderSide.none,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: font, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }

  Widget _buildStageHeader({required double fontSize}) {
    return Padding(
      padding: const EdgeInsets.only(top: 25, bottom: 10),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.64,
        height: 50,
        decoration: BoxDecoration(
          color: Color(0xFF8D8D97),
          borderRadius: BorderRadius.circular(36),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _stageLabel('Boston Common', fontSize - 1.5),
            Container(
              width: 3,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            _stageLabel('Downtown', fontSize),
          ],
        ),
      ),
    );
  }

  Widget _stageLabel(String txt, double fs) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        txt,
        style: TextStyle(
          fontSize: fs,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class ScheduleList extends StatelessWidget {
  final List<ScheduleItem> scheduleItems;
  final void Function(EventItem) onEventTap;

  const ScheduleList({
    required this.scheduleItems,
    required this.onEventTap,
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
    final baseTime = _parseTimeToMinutes(timelineSlots.first);

    // Get the last event's duration from both stages based on scheduleItems
    int latestEventEndTime = baseTime;

    for (var item in scheduleItems) {
      final itemStartTime = _parseTimeToMinutes(item.time);

      // Check stage 1 events
      if (item.stage1Events != null) {
        for (var event in item.stage1Events!) {
          final eventEndTime = itemStartTime + event.duration;
          if (eventEndTime > latestEventEndTime) {
            latestEventEndTime = eventEndTime;
          }
        }
      }

      // Check stage 2 events
      if (item.stage2Events != null) {
        for (var event in item.stage2Events!) {
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
                    final timeInMinutes = _parseTimeToMinutes(timeString);
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
              clipBehavior: Clip.none, // Prevent clipping of children
              children: [
                _buildTimelineLines(
                  baseTime: baseTime,
                  latestTime: latestTime,
                  pixelsPerMinute: pixelsPerMinute,
                  width: screenWidth * 0,
                ),
                SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: SizedBox(
                    height: timelineHeight,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: _buildEventColumn(1, pixelsPerMinute),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: SizedBox(
            height: timelineHeight,
            child: Stack(
              clipBehavior: Clip.none, // Prevent clipping of children
              children: [
                _buildTimelineLines(
                  baseTime: baseTime,
                  latestTime: latestTime,
                  pixelsPerMinute: pixelsPerMinute,
                  width: screenWidth / 2,
                ),
                SingleChildScrollView(
                  physics: NeverScrollableScrollPhysics(),
                  child: SizedBox(
                    height: timelineHeight,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: _buildEventColumn(2, pixelsPerMinute),
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

  List<Widget> _buildEventColumn(int stage, double pixelsPerMinute) {
    final events =
        scheduleItems
            .expand(
              (item) =>
                  stage == 1
                      ? item.stage1Events ?? []
                      : item.stage2Events ?? [],
            )
            .where((e) => e.performanceName.isNotEmpty)
            .toList();

    // Sort events by time if needed
    events.sort((a, b) => a.time.compareTo(b.time));

    return [
      for (var i = 0; i < events.length; i++)
        Column(
          children: [
            SizedBox(height: 4), // Add small gap between events in timetable
            SizedBox(
              height: ((events[i].duration) * pixelsPerMinute) - 4,
              child: PerformanceBox(eventItem: events[i], onTap: onEventTap),
            ),
          ],
        ),
    ];
  }
}

// Parse time string in HH:MM or HH:MM am/pm format to minutes since midnight
int _parseTimeToMinutes(String timeString) {
  try {
    // Remove leading zeros for parsing if needed
    final parts = timeString.trim().split(' ');
    final timePart = parts[0];
    final isPM = parts.length > 1 && parts[1].toLowerCase() == 'pm';

    final hourAndMinute = timePart.split(':');
    int hour = int.parse(hourAndMinute[0]);
    final int minute =
        hourAndMinute.length > 1 ? int.parse(hourAndMinute[1]) : 0;

    // Convert to 24-hour format if PM
    if (isPM && hour < 12) {
      hour += 12;
    }
    // Handle 12 AM edge case
    if (!isPM && hour == 12) {
      hour = 0;
    }

    return hour * 60 + minute;
  } catch (e) {
    return 0; // Default fallback
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

// / パフォーマンスボックス：タップ時に詳細を表示（タップ時のアニメーション付き）
class PerformanceBox extends StatefulWidget {
  final EventItem eventItem;
  final Function(EventItem) onTap;

  const PerformanceBox({Key? key, required this.eventItem, required this.onTap})
    : super(key: key);

  @override
  _PerformanceBoxState createState() => _PerformanceBoxState();
}

class _PerformanceBoxState extends State<PerformanceBox>
    with SingleTickerProviderStateMixin {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 600;

    // adjust sizing for tablets
    final timeSectionHeight = screenHeight * (isTablet ? 0.20 : 0.253);
    final eventHeight =
        widget.eventItem.duration / 60 * timeSectionHeight +
        (isTablet ? 3 : 6.7);
    final containerWidth = screenWidth * (isTablet ? 0.5 : 0.30);
    final horizontalPadding = containerWidth * (isTablet ? 0.06 : 0.05);
    final verticalPadding = isTablet ? 8.0 : 9.0;
    final responsiveScale = screenWidth / (isTablet ? 600 : 380);

    return GestureDetector(
      onTap: () {
        setState(() => isPressed = true);
        Future.delayed(const Duration(milliseconds: 150), () {
          widget.onTap(widget.eventItem);
          setState(() => isPressed = false);
        });
      },
      child: AnimatedScale(
        scale: isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: containerWidth,
          height: eventHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isTablet ? 50 : 45),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isPressed ? 0.05 : 0.1),
                blurRadius: isPressed ? 1 : 3,
                offset: Offset(0, isPressed ? 0 : 1),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: verticalPadding,
              horizontal: horizontalPadding,
            ),
            // pass eventHeight into the builder
            child: _buildInnerContent(isTablet, responsiveScale, eventHeight),
          ),
        ),
      ),
    );
  }

  Widget _buildInnerContent(bool isTablet, double scale, double eventHeight) {
    final iconSize = isTablet ? 40.0 : 30.0;

    if (widget.eventItem.duration < 10) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildIcon(iconSize),
          SizedBox(width: iconSize * (isTablet ? 0.04 : 0.12)),
          _buildTextColumn(
            maxTitle: 17,
            titleScale: 8 * scale,
            timeScale: 6.5 * scale,
            lineHeight: 0.93,
            timeLineHeight: 0.3,
            isTablet: isTablet,
          ),
        ],
      );
    } else if (widget.eventItem.duration == 10) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildIcon(iconSize + 3),
          SizedBox(width: (iconSize + 3) * (isTablet ? 0.036 : 0.054)),
          _buildTextColumn(
            maxTitle: 25,
            titleScale: 9.5 * scale,
            timeScale: 8 * scale,
            lineHeight: 1.2,
            timeLineHeight: 0.9,
            isTablet: isTablet,
          ),
        ],
      );
    } else {
      // now eventHeight is in scope
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIcon(iconSize + 20),
          SizedBox(height: eventHeight * 0.05),
          Text(
            widget.eventItem.performanceName.length > 27
                ? "${widget.eventItem.performanceName.substring(0, 27)}..."
                : widget.eventItem.performanceName,
            style: TextStyle(
              fontSize: scale * 12,
              fontWeight: FontWeight.w500,
              height: 1.1,
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            widget.eventItem.time,
            style: TextStyle(
              fontSize: scale * 10,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
  }

  Widget _buildIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 2),
        ],
      ),
      child:
          widget.eventItem.iconImage.isNotEmpty
              ? Image.network(widget.eventItem.iconImage, fit: BoxFit.cover)
              : Icon(Icons.event, size: size * 0.6),
    );
  }

  Widget _buildTextColumn({
    required int maxTitle,
    required double titleScale,
    required double timeScale,
    required double lineHeight,
    required double timeLineHeight,
    required bool isTablet,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment:
            isTablet ? CrossAxisAlignment.start : CrossAxisAlignment.start,
        children: [
          Text(
            widget.eventItem.performanceName.length > maxTitle
                ? "${widget.eventItem.performanceName.substring(0, maxTitle)}..."
                : widget.eventItem.performanceName,
            style: TextStyle(
              fontSize: titleScale,
              fontWeight: FontWeight.w500,
              height: lineHeight,
            ),
            maxLines: 2,
            textAlign: TextAlign.left,
          ),
          SizedBox(height: isTablet ? 6 : 4),
          Text(
            widget.eventItem.time,
            style: TextStyle(
              fontSize: timeScale,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
              height: timeLineHeight,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}

/// イベント詳細ビュー：iPad対応のため幅・高さ・フォントサイズを調整
class EventDetailView extends StatefulWidget {
  final EventItem event;
  final VoidCallback onClose;

  const EventDetailView({Key? key, required this.event, required this.onClose})
    : super(key: key);

  @override
  _EventDetailViewState createState() => _EventDetailViewState();
}

class _EventDetailViewState extends State<EventDetailView>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _cardOffset, _opacity, _headerScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _cardOffset = Tween(
      begin: 1000.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _opacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.5, curve: Curves.easeIn),
      ),
    );
    _headerScale = Tween(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    _controller.reverse().then((_) => widget.onClose());
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final bool isTablet = screenW >= 600;

    final cardW = screenW * (isTablet ? 0.6 : 0.7);
    final cardH = screenH * (isTablet ? 0.6 : 0.6);
    final avatarRadius = isTablet ? 70.0 : 50.0;
    final headerImgHeight = isTablet ? 280.0 : 200.0;
    final titleSize = isTablet ? 28.0 : 24.0;
    final infoFont = isTablet ? 30.0 : 14.0;
    final descFont = isTablet ? 25.0 : 14.0;

    return AnimatedBuilder(
      animation: _controller,
      builder:
          (context, _) => Stack(
            fit: StackFit.expand,
            children: [
              // overlay
              Positioned.fill(
                child: Opacity(
                  opacity: _opacity.value * 0.6,
                  child: GestureDetector(
                    onTap: _close,
                    child: Container(color: Colors.black),
                  ),
                ),
              ),

              // detail card
              Transform.translate(
                offset: Offset(0, _cardOffset.value + screenH * 0.02),
                child: Center(
                  child: Container(
                    width: cardW,
                    height: cardH,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: _buildCardContent(
                      isTablet, // ← now this matches
                      headerImgHeight,
                      titleSize,
                      infoFont,
                      descFont,
                      avatarRadius,
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildCardContent(
    bool isTablet, // ← add this
    double headerH,
    double titleSize,
    double infoFont,
    double descFont,
    double avatarR,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            // header image + title
            Container(
              height: headerH,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(widget.event.eventImage),
                  fit: BoxFit.cover,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Center(
                  child: Transform.scale(
                    scale: _headerScale.value,
                    child: Text(
                      widget.event.performanceName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // stage & time
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _infoChip(
                    widget.event.stage,
                    widget.event.stage == "Main Stage"
                        ? const Color.fromARGB(120, 191, 29, 25)
                        : const Color.fromARGB(76, 11, 55, 117),
                    infoFont,
                  ),
                  _infoChip(widget.event.time, Colors.white, infoFont),
                ],
              ),
            ),

            // description
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.6,
                      height: MediaQuery.of(context).size.height * 0.27,
                      decoration: ShapeDecoration(
                        color: const Color.fromARGB(13, 0, 0, 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: SingleChildScrollView(
                            child: Text(
                              widget.event.description,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: Colors.black87,
                              ),
                            ),
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

        // close button
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: _close,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 22),
            ),
          ),
        ),

        // floating icon
        // new code – the avatar is fixed at the top-center
        Positioned(
          top:
              isTablet
                  ? -70.0
                  : -40.0, // give it a little breathing room from the top edge
          left: 0,
          right: 0,
          child: Center(
            child: CircleAvatar(
              radius: avatarR,
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.network(
                  widget.event.iconImage,
                  fit: BoxFit.contain,
                  width: avatarR * 1.4,
                  height: avatarR * 1.4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoChip(String text, Color bg, double fontSize) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.25,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
