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
const int festivalStartDay = 12;
const String festivalLocation = "Boston Common";

/// Returns the current festival day (1-based), or 0 if not during the festival.
int getFestivalDay(DateTime now) {
  final start = DateTime(
    festivalStartYear,
    festivalStartMonth,
    festivalStartDay,
  );
  final end = start.add(Duration(days: festivalDays));
  if (now.isBefore(start)) {
    return -1;
  } else if (!now.isBefore(end)) {
    return 0;
  }
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
    _timetableUpdateTimer = Timer.periodic(Duration(minutes: 1), (timer) {
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
    _autoScrollTimer = Timer.periodic(Duration(seconds: 5), (_) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: Duration(milliseconds: 500),
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    // Adaptive dimensions
    final headerHeight = screenHeight * (isTablet ? 0.5 : 0.7);
    final verticalSpacing = screenHeight * (isTablet ? 0.03 : 0.02);
    final btnSize = isTablet ? 70.0 : 55.0;
    final iconSize = isTablet ? 36.0 : 30.0;
    final iconPadding = isTablet ? 14.0 : 8.0;

    final sponsorService = Provider.of<SponsorService>(context);

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
                                    height: headerHeight,
                                    alignment: Alignment.center,
                                  );
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
                        SizedBox(height: verticalSpacing * 2),
                        LiveTimetable(
                          screenWidth: screenWidth,
                          festivalDays: festivalDays,
                          festivalLocation: festivalLocation,
                          festivalStartDay: festivalStartDay,
                          festivalStartMonth: festivalStartMonth,
                          festivalStartYear: festivalStartYear,
                          dayNumber: getFestivalDay(DateTime.now()),
                        ),
                        SizedBox(height: verticalSpacing),

                        _buildSocialMediaIcons(screenWidth),
                        _buildSponsorsSection(screenWidth, sponsorService),
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
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsPage(),
                          ),
                        );
                      },
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: btnSize,
                          height: btnSize,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(btnSize / 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: isTablet ? 12 : 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(iconPadding),
                            child: Icon(
                              Icons.settings,
                              size: iconSize,
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

  Widget _buildSponsorsSection(double screenWidth, SponsorService service) {
    Map<String, List<String>> groupedSponsors = {};

    // 2. Iterate through the service data to populate the map
    for (var sponsor in service.sponsors) {
      if (!groupedSponsors.containsKey(sponsor.category)) {
        groupedSponsors[sponsor.category] = [];
      }
      groupedSponsors[sponsor.category]!.add(sponsor.image);
    }

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
          ...groupedSponsors.entries.map((entry) {
            String categoryName = entry.key;
            List<String> images = entry.value;

            return _buildSponsorSection(categoryName, images);
          }),

          SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget _buildSponsorSection(String categoryName, List<String> images) {
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
            categoryName,
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w300),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 10),
          itemCount: images.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
                images.length == 3 ? 3 : (images.length > 1 ? 2 : 1),
            crossAxisSpacing: 4,
            mainAxisSpacing: 10,
            childAspectRatio:
                images.length == 3 ? 1.5 : (images.length > 1 ? 3 : 4),
          ),
          itemBuilder: (context, index) {
            return Center(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.15,
                width: MediaQuery.of(context).size.width * 0.3,
                child: Image.network(images[index], fit: BoxFit.contain),
              ),
            );
          },
        ),
      ],
    );
  }
}
