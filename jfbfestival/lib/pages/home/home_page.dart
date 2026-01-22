// Removed black arrow from map and added to timetable

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jfbfestival/pages/home/components/live_timetable.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/timetable_data.dart';
import 'package:jfbfestival/settings_page.dart';
import 'package:provider/provider.dart';

class CurrentAndUpcomingEvents {
  final List<EventItem> currentStage1Events;
  final List<EventItem> currentStage2Events;
  final List<EventItem> upcomingStage1Events;
  final List<EventItem> upcomingStage2Events;

  CurrentAndUpcomingEvents({
    required this.currentStage1Events,
    required this.currentStage2Events,
    required this.upcomingStage1Events,
    required this.upcomingStage2Events,
  });
}

class HomePage extends StatefulWidget {
  final DateTime? testTime;
  final EventItem? selectedEvent;

  const HomePage({Key? key, this.testTime, this.selectedEvent})
    : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

// TODO: Refactor this page, put this in a folder and make components. Link the database to the sponsor images, don't forget option for non image sponsors too

class _HomePageState extends State<HomePage> {
  // your original images
  final List<String> backgroundImages = [
    "assets/JFB-27.jpg",
    "assets/JFB-4.jpg",
    "assets/JFB-3.jpg",
    "assets/JFB-8.jpg",
    "assets/JFB-15.jpg",
    "assets/JFB-10.jpg",
    "assets/JFB-22.jpg",
    "assets/JFB-6.jpg",
  ];

  // build an “extended” list with dummy first/last
  List<String> get _extendedBackgroundImages => [
    backgroundImages.last,
    ...backgroundImages,
    backgroundImages.first,
  ];

  late final PageController _pageController;
  int _currentPage = 0; // real index [0..backgroundImages.length-1]
  Timer? _autoScrollTimer;
  Timer? _timetableUpdateTimer;

  @override
  void initState() {
    super.initState();
    // start on page 1, which is actually backgroundImages[0]
    _pageController = PageController(initialPage: 1);
    _startAutoScroll();
    _timetableUpdateTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(Duration(seconds: 5), (_) {
      if (_pageController.hasClients) {
        final int current = _pageController.page!.round();
        final int next = current + 1;
        _pageController.animateToPage(
          next,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _handlePageChanged(int page) {
    final int realCount = backgroundImages.length;
    if (page == 0) {
      // wrapped to duplicate last → jump to real last
      _pageController.jumpToPage(realCount);
      setState(() => _currentPage = realCount - 1);
    } else if (page == realCount + 1) {
      // wrapped to duplicate first → jump to real first
      _pageController.jumpToPage(1);
      setState(() => _currentPage = 0);
    } else {
      // normal case
      setState(() => _currentPage = page - 1);
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _timetableUpdateTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    // Adaptive dimensions
    final headerHeight = screenHeight * (isTablet ? 0.5 : 0.6);
    final verticalSpacing = screenHeight * (isTablet ? 0.03 : 0.02);
    final settingsBtnSize = isTablet ? 70.0 : 55.0;
    final settingsIconSize = isTablet ? 36.0 : 30.0;
    final settingsIconPadding = isTablet ? 14.0 : 10.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: const Color(0xFFFFF5F5),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color.fromRGBO(10, 56, 117, 0.15),
                  const Color.fromRGBO(191, 28, 36, 0.15),
                ],
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  // Scrollable content
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        // Carousel header
                        SizedBox(
                          width: double.infinity,
                          height: headerHeight,
                          child: Stack(
                            children: [
                              PageView.builder(
                                controller: _pageController,
                                itemCount: _extendedBackgroundImages.length,
                                onPageChanged: _handlePageChanged,
                                itemBuilder: (context, index) {
                                  final imagePath =
                                      _extendedBackgroundImages[index];
                                  final isLady =
                                      imagePath == "assets/JFB-27.jpg";
                                  Widget image = Image.asset(
                                    imagePath,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: headerHeight,
                                    alignment:
                                        isLady
                                            ? Alignment.topCenter
                                            : Alignment.center,
                                  );
                                  if (isLady) {
                                    image = Transform.scale(
                                      scale: isTablet ? 1.2 : 1.1,
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: image,
                                      ),
                                    );
                                  }
                                  return image;
                                },
                              ),
                              Positioned(
                                bottom: isTablet ? 20 : 10,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    backgroundImages.length,
                                    (idx) => AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      margin: EdgeInsets.symmetric(
                                        horizontal: isTablet ? 6 : 4,
                                      ),
                                      width:
                                          _currentPage == idx
                                              ? (isTablet ? 12 : 10)
                                              : (isTablet ? 8 : 6),
                                      height:
                                          _currentPage == idx
                                              ? (isTablet ? 12 : 10)
                                              : (isTablet ? 8 : 6),
                                      decoration: BoxDecoration(
                                        color:
                                            _currentPage == idx
                                                ? Colors.white
                                                : Colors.white70,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Spacing + Sections
                        SizedBox(height: verticalSpacing),
                        // LiveTimetable(
                        //   testTime: widget.testTime,
                        //   screenWidth: screenWidth,
                        // ),
                        _buildLiveTimetable(screenWidth),
                        _buildSocialMediaIcons(screenWidth),
                        _buildSponsorsSection(screenWidth),
                        SizedBox(height: verticalSpacing * 6),
                      ],
                    ),
                  ),

                  // Settings button
                  Positioned(
                    top:
                        MediaQuery.of(context).padding.top +
                        screenHeight * (isTablet ? 0.02 : 0.015),
                    right: screenWidth * (isTablet ? 0.07 : 0.05),
                    child: GestureDetector(
                      onTap:
                          () => Navigator.pushNamed(
                            context,
                            SettingsPage.routeName,
                          ),
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: settingsBtnSize,
                          height: settingsBtnSize,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(
                              settingsBtnSize / 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: isTablet ? 12 : 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(settingsIconPadding),
                            child: Icon(
                              Icons.settings,
                              size: settingsIconSize,
                              color: Colors.black,
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
        );
      },
    );
  }

  // Helper class to organize events

  Widget _buildLiveTimetable(double screenWidth) {
    // Use test time if provided, otherwise use current Boston time (UTC-4)
    final bool isTablet = screenWidth >= 600;
    final double sidePadding = isTablet ? 32.0 : 16.0;
    final double sectionSpacing = isTablet ? 24.0 : 16.0;
    final double statusFontSize = isTablet ? 18.0 : 16.0;

    final now = widget.testTime ?? DateTime.now(); // Local time

    // final now = widget.testTime ?? DateTime.utc(2025, 4, 27, 16, 55);

    // Festival dates setup
    final festivalStart = DateTime(2026, 1, 22, 11); // April 26 at 11:00 AM
    final festivalEnd = DateTime(2026, 1, 23, 23, 59); // April 27 at 11:59 PM

    // Check if we're outside festival dates
    if (now.isBefore(festivalStart) || now.isAfter(festivalEnd)) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2),
            ],
          ),
          child: const Center(
            child: Text(
              "Live Timetable is only available on Apr 26 – 27",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // Determine which day's schedule to use (day 1 or day 2)
    final bool isDay1 = now.day == 22; // First day is April 26

    // Make sure schedule data exists before proceeding
    final List<ScheduleItem> scheduleList;
    final scheduleService = Provider.of<ScheduleDataService>(context);
    try {
      scheduleList =
          isDay1
              ? scheduleService.day1ScheduleData
              : scheduleService.day2ScheduleData;

      // Safety check - if schedule data is empty, show a message
      if (scheduleList.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "No schedule data available for ${isDay1 ? 'Day 1' : 'Day 2'}.",
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        );
      }
    } catch (e) {
      // Handle case where data is not available
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          "Error loading schedule data: $e",
          style: TextStyle(fontSize: 16, color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Find all current and upcoming events for both stages
    final currentAndUpcomingEvents = _getCurrentAndUpcomingEvents(
      scheduleList,
      now,
      isDay1,
    );
    return Padding(
      padding: EdgeInsets.all(sidePadding),
      child: Column(
        children: [
          if (currentAndUpcomingEvents.currentStage1Events.isNotEmpty ||
              currentAndUpcomingEvents.currentStage2Events.isNotEmpty) ...[
            _buildEventSection(
              "🎤 Now Happening",
              currentAndUpcomingEvents.currentStage1Events,
              currentAndUpcomingEvents.currentStage2Events,
              screenWidth,
              isCurrent: true,
              isTablet: isTablet,
            ),
            SizedBox(height: sectionSpacing),
          ],
          if (currentAndUpcomingEvents.upcomingStage1Events.isNotEmpty ||
              currentAndUpcomingEvents.upcomingStage2Events.isNotEmpty) ...[
            _buildEventSection(
              "⏭️ Up Next",
              currentAndUpcomingEvents.upcomingStage1Events,
              currentAndUpcomingEvents.upcomingStage2Events,
              screenWidth,
              isCurrent: false,
              isTablet: isTablet,
            ),
            SizedBox(height: sectionSpacing),
          ],
          if (currentAndUpcomingEvents.currentStage1Events.isEmpty &&
              currentAndUpcomingEvents.currentStage2Events.isEmpty &&
              currentAndUpcomingEvents.upcomingStage1Events.isEmpty &&
              currentAndUpcomingEvents.upcomingStage2Events.isEmpty)
            Text(
              "No current or upcoming events at this time.",
              style: TextStyle(fontSize: statusFontSize),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  CurrentAndUpcomingEvents _getCurrentAndUpcomingEvents(
    List<ScheduleItem> scheduleList,
    DateTime now,
    bool isDay1,
  ) {
    // Initialize empty lists for all categories
    List<EventItem> currentStage1Events = [];
    List<EventItem> currentStage2Events = [];
    List<EventItem> upcomingStage1Events = [];
    List<EventItem> upcomingStage2Events = [];

    // Current year and month
    final year = now.year;
    final month = now.month;
    final day = isDay1 ? 22 : 23; // April 27 or 28, 2025

    // Process all events to find current and upcoming
    for (final item in scheduleList) {
      // Safety check - skip if stage events are null
      if (item.stage1Events == null && item.stage2Events == null) continue;

      // Process Stage 1 events
      if (item.stage1Events != null) {
        for (final event in item.stage1Events!) {
          // Skip if time format is invalid
          if (!event.time.contains('-')) continue;

          try {
            // Parse the event time range (e.g., "11:00-11:15")
            final timeParts = event.time.split('-');
            final eventStartStr = timeParts[0].trim();
            final eventEndStr = timeParts[1].trim();

            // Convert to full DateTime objects
            final eventStartParts = eventStartStr.split(':');
            final eventEndParts = eventEndStr.split(':');

            if (eventStartParts.length != 2 || eventEndParts.length != 2)
              continue;

            final eventStartHour = int.parse(eventStartParts[0]);
            final eventStartMinute = int.parse(eventStartParts[1]);
            final eventEndHour = int.parse(eventEndParts[0]);
            final eventEndMinute = int.parse(eventEndParts[1]);

            final eventStart = DateTime(
              year,
              month,
              day,
              eventStartHour,
              eventStartMinute,
            );
            final eventEnd = DateTime(
              year,
              month,
              day,
              eventEndHour,
              eventEndMinute,
            );

            print("event start $eventStart");

            // Current event: now is between event start and end times
            if (now.isAfter(eventStart) && now.isBefore(eventEnd)) {
              currentStage1Events.add(event);
            }
            // Upcoming event: event starts after now
            else if (eventStart.isAfter(now)) {
              // Only add if we don't have upcoming events yet or if this starts at the same time
              if (upcomingStage1Events.isEmpty ||
                  eventStart.isAtSameMomentAs(
                    _parseEventStartTime(
                      upcomingStage1Events.first.time,
                      year,
                      month,
                      day,
                    ),
                  )) {
                upcomingStage1Events.add(event);
              }
            }
          } catch (e) {
            continue;
          }
        }
      }

      // Process Stage 2 events
      if (item.stage2Events != null) {
        for (final event in item.stage2Events!) {
          // Skip if time format is invalid
          if (!event.time.contains('-')) continue;

          try {
            // Parse the event time range (e.g., "11:00-11:15")
            final timeParts = event.time.split('-');
            final eventStartStr = timeParts[0].trim();
            final eventEndStr = timeParts[1].trim();

            // Convert to full DateTime objects
            final eventStartParts = eventStartStr.split(':');
            final eventEndParts = eventEndStr.split(':');

            if (eventStartParts.length != 2 || eventEndParts.length != 2)
              continue;

            final eventStartHour = int.parse(eventStartParts[0]);
            final eventStartMinute = int.parse(eventStartParts[1]);
            final eventEndHour = int.parse(eventEndParts[0]);
            final eventEndMinute = int.parse(eventEndParts[1]);

            final eventStart = DateTime(
              year,
              month,
              day,
              eventStartHour,
              eventStartMinute,
            );
            final eventEnd = DateTime(
              year,
              month,
              day,
              eventEndHour,
              eventEndMinute,
            );

            // Current event: now is between event start and end times
            if (now.isAfter(eventStart) && now.isBefore(eventEnd)) {
              currentStage2Events.add(event);
            }
            // Upcoming event: event starts after now
            else if (eventStart.isAfter(now)) {
              // Only add if we don't have upcoming events yet or if this starts at the same time
              if (upcomingStage2Events.isEmpty ||
                  eventStart.isAtSameMomentAs(
                    _parseEventStartTime(
                      upcomingStage2Events.first.time,
                      year,
                      month,
                      day,
                    ),
                  )) {
                upcomingStage2Events.add(event);
              }
            }
          } catch (e) {
            continue;
          }
        }
      }
    }

    // Sort upcoming events by start time if we have multiple events
    if (upcomingStage1Events.length > 1) {
      upcomingStage1Events.sort((a, b) {
        final aTime = _parseEventStartTime(a.time, year, month, day);
        final bTime = _parseEventStartTime(b.time, year, month, day);
        return aTime.compareTo(bTime);
      });
    }

    if (upcomingStage2Events.length > 1) {
      upcomingStage2Events.sort((a, b) {
        final aTime = _parseEventStartTime(a.time, year, month, day);
        final bTime = _parseEventStartTime(b.time, year, month, day);
        return aTime.compareTo(bTime);
      });
    }

    // If we have multiple upcoming events with different start times, only keep the earliest ones
    if (upcomingStage1Events.isNotEmpty && upcomingStage2Events.isNotEmpty) {
      final stage1StartTime = _parseEventStartTime(
        upcomingStage1Events.first.time,
        year,
        month,
        day,
      );
      final stage2StartTime = _parseEventStartTime(
        upcomingStage2Events.first.time,
        year,
        month,
        day,
      );

      if (stage1StartTime.isBefore(stage2StartTime)) {
        // Keep only stage1 events that start at the earliest time
        upcomingStage2Events.clear();
      } else if (stage2StartTime.isBefore(stage1StartTime)) {
        // Keep only stage2 events that start at the earliest time
        upcomingStage1Events.clear();
      }
    }

    return CurrentAndUpcomingEvents(
      currentStage1Events: currentStage1Events,
      currentStage2Events: currentStage2Events,
      upcomingStage1Events: upcomingStage1Events,
      upcomingStage2Events: upcomingStage2Events,
    );
  }

  // Helper method to parse event start time from time range string with full date
  DateTime _parseEventStartTime(
    String timeRange,
    int year,
    int month,
    int day,
  ) {
    try {
      final timePart = timeRange.split('-')[0].trim();
      final parts = timePart.split(':');
      if (parts.length != 2) {
        // Return a default time far in the future if parsing fails
        return DateTime(9999);
      }
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      // Return a default time far in the future if parsing fails
      print('Error parsing event start time: $e');
      return DateTime(9999);
    }
  }

  // 2) EVENT SECTION
  Widget _buildEventSection(
    String title,
    List<EventItem> stage1Events,
    List<EventItem> stage2Events,
    double screenWidth, {
    required bool isCurrent,
    required bool isTablet,
  }) {
    final double titleFontSize = isTablet ? 24.0 : 20.0;
    final double spacing = isTablet ? 12.0 : 8.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.pinkAccent,
            ),
          ),
        ),
        SizedBox(height: spacing),
        ...stage1Events.map(
          (e) => _buildEventCard(e, isCurrent, screenWidth, isTablet),
        ),
        ...stage2Events.map(
          (e) => _buildEventCard(e, isCurrent, screenWidth, isTablet),
        ),
      ],
    );
  }

  // 3) EVENT CARD
  Widget _buildEventCard(
    EventItem event,
    bool isCurrent,
    double screenWidth,
    bool isTablet,
  ) {
    final double verticalPadding = isTablet ? 12.0 : 8.0;
    final EdgeInsets cardPadding = EdgeInsets.all(isTablet ? 24 : 16);
    final double borderRadius = isTablet ? 12.0 : 10.0;
    final double stageFontSize =
        screenWidth * (isTablet ? 0.055 : 0.045) + (isTablet ? 3 : 2);
    final double titleFontSize = screenWidth * (isTablet ? 0.055 : 0.045);
    final double iconDiameter = screenWidth * (isTablet ? 0.15 : 0.12);
    final double iconOffset = isTablet ? -20.0 : -18.0;
    final double iconPaddingLeft = isTablet ? 5.0 : 3.0;

    return GestureDetector(
      onTap: () {
        // TODO: Someone pasted llM shit here without putting the navigation logic
        // … your existing navigation logic …
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: cardPadding,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: isTablet ? 8 : 5,
                    spreadRadius: isTablet ? 3 : 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stage label
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      event.stage,
                      style: TextStyle(
                        color: Colors.pinkAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: stageFontSize,
                      ),
                    ),
                  ),
                  SizedBox(height: isTablet ? 8 : 5),
                  // Title
                  Text(
                    event.performanceName,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Time
                  Text(event.time, style: TextStyle(color: Colors.grey)),
                  // “Going on now” badge
                  if (isCurrent)
                    Padding(
                      padding: EdgeInsets.only(top: isTablet ? 8.0 : 5.0),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 6 : 4,
                          horizontal: isTablet ? 12 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "Going on now!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 14 : 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Floating icon
            if (event.iconImage.isNotEmpty)
              Positioned(
                top: iconOffset,
                left: iconPaddingLeft,
                child: Container(
                  padding: EdgeInsets.all(isTablet ? 8 : 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: isTablet ? 6 : 5,
                        spreadRadius: isTablet ? 3 : 2,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    event.iconImage,
                    height: iconDiameter,
                    width: iconDiameter,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialMediaIcons(double screenWidth) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildIcon(
            "assets/instagram.png",
            "https://www.instagram.com/japanfestivalboston?utm_source=ig_web_button_share_sheet&igsh=ZDNlZDc0MzIxNw==",
          ),
          _buildIcon(
            "assets/facebook.png",
            "https://www.facebook.com/JapanFestivalBoston",
          ),
          _buildIcon(
            "assets/website.png",
            "https://www.japanfestivalboston.org",
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(String imagePath, String url) {
    return GestureDetector(
      onTap: () async {
        final Uri uri = Uri.parse(url);
        if (await canLaunch(uri.toString())) {
          await launch(uri.toString());
        } else {
          throw 'Could not launch $url';
        }
      },
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2),
          ],
        ),
        child: Image.asset(imagePath, height: 30),
      ),
    );
  }

  Widget _buildSponsorsSection(double screenWidth) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2),
        ],
      ),
      child: Column(
        spacing: screenWidth * 0.02,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildSponsorCategory("Sustainability", "assets/sponsors/Takeda.jpg"),
          _buildSponsorCategory("Airline", "assets/sponsors/jal.jpg"),
          SizedBox(height: 7),
          _buildSponsorCategory(
            "Transportation",
            "assets/sponsors/yamatotransport.jpg",
          ),
          SizedBox(height: 3),
          _buildCorporateSponsors(),
          _buildIndividualSponsors(),
          _buildAuctionDonors(),
          _buildJfbOrganizers(),
          _buildSupportingSponsors(),
          SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget _buildSponsorCategory(String title, String imagePath) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 3, horizontal: 26),
          margin: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(40),
          ),
          child: Text(
            title,
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w300),
          ),
        ),
        Image.asset(imagePath, height: 65),
      ],
    );
  }

  Widget _buildCorporateSponsors() {
    List<String> corporateLogos = [
      "assets/sponsors/meetboston.jpg",
      "assets/sponsors/sanipak.png",
      "assets/sponsors/chopvalue.png",
      "assets/sponsors/mitsubishi.jpg",
      "assets/sponsors/SDT.jpg",
      "assets/sponsors/senko.png",
      "assets/sponsors/yamamoto.jpg",
      "assets/sponsors/openwater.png",
      "assets/sponsors/idamerica.png",
      "assets/sponsors/downtown.png",
      "assets/sponsors/redsox.png",
    ];

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 26),
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(40),
          ),
          child: Text(
            "Corporate",
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w300),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 10),
          itemCount: corporateLogos.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 4,
            mainAxisSpacing: 10,
            childAspectRatio: 3,
          ),
          itemBuilder: (context, index) {
            return Center(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.15,
                width: MediaQuery.of(context).size.width * 0.3,
                child: Image.asset(corporateLogos[index], fit: BoxFit.contain),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildIndividualSponsors() {
    return Padding(
      padding: EdgeInsets.only(top: 10, bottom: 10),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 26),
            margin: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(40),
            ),
            child: Text(
              "Individual",
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w300),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                "   NK JPN\nFoundation",
                style: TextStyle(fontSize: 19, height: 1.25),
              ),
              Text(
                "William\nHawes",
                style: TextStyle(fontSize: 19, height: 1.25),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJfbOrganizers() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 26),
          margin: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(40),
          ),
          child: Text(
            "JFB Organizers",
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w300),
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 20,
          runSpacing: 10,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.11,
              width: MediaQuery.of(context).size.width * 0.25,
              child: Image.asset(
                "assets/sponsors/showa.jpg",
                fit: BoxFit.contain,
              ),
            ),
            Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.08,
                  width: MediaQuery.of(context).size.width * 0.2,
                  child: Image.asset(
                    "assets/sponsors/bosJapan.png",
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 4),
                Column(
                  children: [
                    Text(
                      "Boston Japan",
                      style: TextStyle(fontSize: 12, height: 1),
                    ),
                    Text(
                      "Community Hub",
                      style: TextStyle(fontSize: 12, height: 1.1),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.11,
              width: MediaQuery.of(context).size.width * 0.25,
              child: Image.asset(
                "assets/sponsors/JAGB.jpg",
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSupportingSponsors() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 26),
          margin: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(40),
          ),
          child: Text(
            "Individual",
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w300),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.12,
              width: MediaQuery.of(context).size.width * 0.35,
              child: Image.asset(
                "assets/sponsors/consultatejapan.jpg",
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.12,
              width: MediaQuery.of(context).size.width * 0.35,
              child: Image.asset(
                "assets/sponsors/JSoc.jpg",
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAuctionDonors() {
    List<String> corporateLogos = [
      "assets/sponsors/sapporostream.png",
      "assets/sponsors/ogawashou.png",
      "assets/sponsors/imperial.png",
    ];

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 26),
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(40),
          ),
          child: Text(
            "Our Silent Auction Donors",
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w300),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 10),
          itemCount: corporateLogos.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 4,
            mainAxisSpacing: 10,
            childAspectRatio: 2,
          ),
          itemBuilder: (context, index) {
            return Center(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.15,
                width: MediaQuery.of(context).size.width * 0.3,
                child: Image.asset(corporateLogos[index], fit: BoxFit.contain),
              ),
            );
          },
        ),
      ],
    );
  }
}
