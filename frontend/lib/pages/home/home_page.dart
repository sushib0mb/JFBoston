// Removed black arrow from map and added to timetable

import 'dart:async';
import 'package:flutter/material.dart';
import 'components/live_timetable.dart';
import '../../services/sponsor_service.dart';
import '../../services/db_image_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/timetable_data.dart';
import '../settings_page.dart';

// Centralized festival date logic - single source of truth
const int festivalDays = 2;
const int festivalStartYear = 2026;
const int festivalStartMonth = 4;
// ── Incoming: updated start day ───────────────────────────────────────────────
const int festivalStartDay = 12;
const String festivalLocation = "Boston Common";

/// Returns the current festival day (1-based), or 0 if not during the festival.
int getFestivalDay(DateTime now) {
  final start = DateTime(
    festivalStartYear,
    festivalStartMonth,
    festivalStartDay,
  );
  final end = start.add(const Duration(days: festivalDays));
  if (now.isBefore(start))
    return -1;
  else if (!now.isBefore(end))
    return 0;
  return now.difference(start).inDays + 1;
}

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
  final EventItem? selectedEvent;

  const HomePage({super.key, this.selectedEvent});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final List<String> backgroundImages = [
    "assets/HomeImage1.jpg",
    "assets/HomeImage2.jpg",
    "assets/HomeImage3.jpg",
    "assets/HomeImage4.jpg",
    "assets/HomeImage5.jpg",
    "assets/HomeImage6.jpg",
  ];

  static const int _virtualPageCount = 100000;

  // ── Fixed layout constants — no screen-size math ──────────────────────────
  static const double _headerHeight = 580.0;
  static const double _sectionSpacing = 16.0;
  static const double _settingsBtnSize = 52.0;
  static const double _settingsIconSize = 28.0;
  static const double _settingsIconPadding = 10.0;
  static const double _settingsRightPad = 16.0;
  static const double _settingsTopPad = 8.0;
  static const double _dotSelected = 10.0;
  static const double _dotUnselected = 6.0;
  static const double _dotHorizontalMargin = 4.0;
  static const double _dotsBottomPad = 12.0;
  static const double _sponsorSectionSpacing = 8.0;
  // ──────────────────────────────────────────────────────────────────────────

  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;
  Timer? _timetableUpdateTimer;

  int get _initialVirtualPage =>
      (_virtualPageCount ~/ 2) -
      (_virtualPageCount ~/ 2) % backgroundImages.length;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialVirtualPage);
    _startAutoScroll();
    _timetableUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DbImageService>(
        context,
        listen: false,
      ).fetchFolder('homeImages');
    });
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _handlePageChanged(int page) {
    setState(() => _currentPage = page % backgroundImages.length);
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _timetableUpdateTimer?.cancel();
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── No screenWidth / screenHeight / isTablet variables ────────────────
    final sponsorService = Provider.of<SponsorService>(context);

    return Container(
      color: const Color(0xFFECE0CF),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // ── Scrollable content ───────────────────────────────────────
            SingleChildScrollView(
              child: Column(
                children: [
                  // ── Carousel header ───────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: _headerHeight,
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: _virtualPageCount,
                          onPageChanged: _handlePageChanged,
                          itemBuilder: (context, index) {
                            final imagePath =
                                backgroundImages[index %
                                    backgroundImages.length];
                            return Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: _headerHeight,
                              alignment: Alignment.center,
                            );
                          },
                        ),
                        // ── Dot indicators ────────────────────────────
                        Positioned(
                          bottom: _dotsBottomPad,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              backgroundImages.length,
                              (idx) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: _dotHorizontalMargin,
                                ),
                                width:
                                    _currentPage == idx
                                        ? _dotSelected
                                        : _dotUnselected,
                                height:
                                    _currentPage == idx
                                        ? _dotSelected
                                        : _dotUnselected,
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

                  const SizedBox(height: _sectionSpacing),
                  LiveTimetable(
                    festivalDays: festivalDays,
                    festivalLocation: festivalLocation,
                    festivalStartDay: festivalStartDay,
                    festivalStartMonth: festivalStartMonth,
                    festivalStartYear: festivalStartYear,
                    dayNumber: getFestivalDay(DateTime.now()),
                  ),
                  _buildSocialMediaIcons(),
                  _buildSponsorsSection(sponsorService),
                  const SizedBox(height: _sectionSpacing * 6),
                ],
              ),
            ),

            // ── Settings button — SafeArea handles status bar inset ───────
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: _settingsTopPad,
                    right: _settingsRightPad,
                  ),
                  child: GestureDetector(
                    onTap:
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsPage(),
                          ),
                        ),
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: _settingsBtnSize,
                        height: _settingsBtnSize,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(
                            _settingsBtnSize / 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(_settingsIconPadding),
                          child: Icon(
                            Icons.settings,
                            size: _settingsIconSize,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialMediaIcons() {
    return Container(
      margin: const EdgeInsets.all(25),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
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
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
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

  Widget _buildSponsorsSection(SponsorService service) {
    final Map<String, List<String>> groupedSponsors = {};
    for (var sponsor in service.sponsors) {
      groupedSponsors
          .putIfAbsent(sponsor.category, () => [])
          .add(sponsor.image);
    }

    return Container(
      margin: const EdgeInsets.all(25),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2),
        ],
      ),
      child: Column(
        spacing: _sponsorSectionSpacing,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ...groupedSponsors.entries.map(
            (entry) => _buildSponsorType(entry.key, entry.value),
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget _buildSponsorType(String categoryName, List<String> images) {
    final screenSize = MediaQuery.of(context).size;

    final double dynamicMaxHeight = screenSize.height * 0.12;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 26),
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(40),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              categoryName,
              maxLines: 1,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w300),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const double spacing = 16.0;
              final double itemWidth =
                  (constraints.maxWidth - spacing) / 2 - 0.1;

              return Wrap(
                spacing: spacing,
                runSpacing: 20.0,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children:
                    images.map((img) {
                      return Container(
                        width: itemWidth,
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth:
                                itemWidth, // Allow it to fill its column width
                            maxHeight:
                                dynamicMaxHeight, // Cap the height responsively
                          ),
                          child: Image.network(img, fit: BoxFit.contain),
                        ),
                      );
                    }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}
