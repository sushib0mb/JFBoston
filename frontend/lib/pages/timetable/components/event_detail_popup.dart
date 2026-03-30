import 'package:flutter/material.dart';
import 'package:jfbfestival/data/timetable_data.dart';

class EventDetailPopup extends StatefulWidget {
  final EventItem event;
  final VoidCallback onClose;

  const EventDetailPopup({
    super.key,
    required this.event,
    required this.onClose,
  });

  @override
  State<EventDetailPopup> createState() => _EventDetailPopupState();
}

class _EventDetailPopupState extends State<EventDetailPopup>
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
    String calculateEndTime(String time, int duration) {
      List<String> timeParts = time.split(":");
      int totalMinutes =
          int.parse(timeParts[0]) * 60 + int.parse(timeParts[1]) + duration;

      final endHour =
          (totalMinutes ~/ 60) % 24; // % 24 handles midnight wrapping
      final endMinute = totalMinutes % 60;

      return '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
    }

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
                  _infoChip(
                    '${widget.event.time} - ${calculateEndTime(widget.event.time, widget.event.duration)}',
                    Colors.white,
                    infoFont,
                  ),
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
