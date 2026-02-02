import 'package:flutter/material.dart';
import 'package:jfbfestival/data/timetable_data.dart';

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

  String calculateEndTime(String time, int duration) {
    List<String> timeParts = time.split(":");
    int totalMinutes =
        int.parse(timeParts[0]) * 60 + int.parse(timeParts[1]) + duration;

    final endHour = (totalMinutes ~/ 60) % 24; // % 24 handles midnight wrapping
    final endMinute = totalMinutes % 60;

    return '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
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
            '${widget.eventItem.time} - ${calculateEndTime(widget.eventItem.time, widget.eventItem.duration)}',
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
            '${widget.eventItem.time} - ${calculateEndTime(widget.eventItem.time, widget.eventItem.duration)}',
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
