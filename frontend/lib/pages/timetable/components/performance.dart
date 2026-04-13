import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../data/timetable_data.dart';
import '../../../services/location_service.dart';
import '../../../services/notification_service.dart';
import '../../../utils/time_utils.dart';

class Performance extends StatefulWidget {
  final EventItem eventItem;
  final Function(EventItem) onTap;

  const Performance({super.key, required this.eventItem, required this.onTap});

  @override
  State<Performance> createState() => _PerformanceState();
}

class _PerformanceState extends State<Performance>
    with SingleTickerProviderStateMixin {
  bool isPressed = false;
  int? _reminderMinutes;

  String get _prefsKey => 'reminder_${widget.eventItem.id}';

  @override
  void initState() {
    super.initState();
    _loadReminderState();
  }

  Future<void> _loadReminderState() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getInt(_prefsKey);
    if (mounted) {
      setState(() => _reminderMinutes = val);
      // Restart GPS on app relaunch if this event has a saved reminder
      if (val != null) context.read<LocationService>().start();
    }
  }

  Future<void> _scheduleReminder(int minutes) async {
    // Start GPS tracking the first time a reminder is set
    context.read<LocationService>().start();
    await notificationService.schedule(
      id: widget.eventItem.id,
      title: '${widget.eventItem.performanceName} is starting soon!',
      body:
          '$minutes min until ${widget.eventItem.time} · ${widget.eventItem.stage}',
      when: widget.eventItem.startDateTime,
      leadTime: Duration(minutes: minutes),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, minutes);
    if (mounted) {
      setState(() => _reminderMinutes = minutes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reminder set: $minutes min before ${widget.eventItem.performanceName}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _cancelReminder() async {
    await notificationService.cancel(widget.eventItem.id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    if (mounted) setState(() => _reminderMinutes = null);

    // Stop GPS if no other reminders remain
    final hasOthers = prefs.getKeys().any((k) => k.startsWith('reminder_'));
    if (!hasOthers && mounted) context.read<LocationService>().stop();
  }

  void _showReminderPicker(BuildContext context) {
    int selected = _reminderMinutes ?? 10;
    final scrollCtrl = FixedExtentScrollController(initialItem: selected - 1);

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setSheet) => Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Set Reminder',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.eventItem.performanceName}  ·  ${widget.eventItem.stage}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      // Quick chips
                      Wrap(
                        spacing: 8,
                        children:
                            [5, 10, 15, 20].map((min) {
                              final isChipSelected = selected == min;
                              return GestureDetector(
                                onTap: () {
                                  setSheet(() => selected = min);
                                  scrollCtrl.animateToItem(
                                    min - 1,
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOut,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isChipSelected
                                            ? const Color(0xFFBF1D23)
                                            : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color:
                                          isChipSelected
                                              ? const Color(0xFFBF1D23)
                                              : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Text(
                                    '$min min',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isChipSelected
                                              ? Colors.white
                                              : Colors.black87,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 12),
                      // Scroll wheel
                      SizedBox(
                        height: 150,
                        child: CupertinoPicker(
                          scrollController: scrollCtrl,
                          itemExtent: 40,
                          selectionOverlay:
                              CupertinoPickerDefaultSelectionOverlay(
                                background: const Color(
                                  0xFF0B3775,
                                ).withValues(alpha: 0.08),
                              ),
                          onSelectedItemChanged: (i) {
                            setSheet(() => selected = i + 1);
                          },
                          children: List.generate(
                            60,
                            (i) => Center(
                              child: Text(
                                '${i + 1} ${i + 1 == 1 ? "minute" : "minutes"}',
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Set button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _scheduleReminder(selected);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFBF1D23),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Remind me $selected min before',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      if (_reminderMinutes != null) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _cancelReminder();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Remove reminder'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ),
          ),
    ).then((_) => scrollCtrl.dispose());
  }

  Widget _buildReminderButton() {
    final hasReminder = _reminderMinutes != null;
    return GestureDetector(
      onTap: () => _showReminderPicker(context),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color:
              hasReminder
                  ? const Color(0xFFBF1D23)
                  : Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          hasReminder ? Icons.notifications_active : Icons.notifications_none,
          size: 24,
          color: hasReminder ? Colors.white : Colors.grey[700],
        ),
      ),
    );
  }

  Widget _labelBox(
    String text,
    double fontSize,
    FontWeight fontWeight, {
    Color textColor = Colors.black,
    int maxLines = 2,
    TextAlign textAlign = TextAlign.center,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: textColor,
          height: 1.1,
        ),
        maxLines: maxLines,
        textAlign: textAlign,
      ),
    );
  }

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
    final horizontalPadding = isTablet ? 8.0 : 6.0;
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
        child: SizedBox(
          width: double.infinity,
          height: eventHeight,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isPressed ? 0.05 : 0.1),
                        blurRadius: isPressed ? 1 : 3,
                        offset: Offset(0, isPressed ? 0 : 1),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildBackground(),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: verticalPadding,
                            horizontal: horizontalPadding,
                          ),
                          child: _buildInnerContent(
                            isTablet,
                            responsiveScale,
                            eventHeight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.eventItem.performanceName.isNotEmpty)
                Positioned(top: 5, right: 4, child: _buildReminderButton()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base cream color
        Container(color: const Color(0xFFECE0CF)),
        // Frosted glass blur
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(color: Colors.white.withValues(alpha: 0.35)),
        ),
        // Red tint across the top
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFBF1D23).withValues(alpha: 0.15),
                Colors.transparent,
              ],
              stops: const [0.0, 0.85],
            ),
          ),
        ),
      ],
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
          _labelBox(
            widget.eventItem.performanceName.length > 27
                ? "${widget.eventItem.performanceName.substring(0, 27)}..."
                : widget.eventItem.performanceName,
            scale * 12,
            FontWeight.w700,
            textColor: Colors.black,
          ),
          SizedBox(height: isTablet ? 12 : 8),
          _labelBox(
            '${widget.eventItem.time} - ${findEndTime(widget.eventItem.time, widget.eventItem.duration)}',
            scale * 10,
            FontWeight.w700,
            textColor: Colors.black,
            maxLines: 1,
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 2),
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
          _labelBox(
            widget.eventItem.performanceName.length > maxTitle
                ? "${widget.eventItem.performanceName.substring(0, maxTitle)}..."
                : widget.eventItem.performanceName,
            titleScale,
            FontWeight.w700,
            textColor: Colors.black,
            textAlign: TextAlign.left,
          ),
          SizedBox(height: isTablet ? 6 : 4),
          _labelBox(
            '${widget.eventItem.time} - ${findEndTime(widget.eventItem.time, widget.eventItem.duration)}',
            timeScale,
            FontWeight.w700,
            textColor: Colors.black,
            maxLines: 1,
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }
}
