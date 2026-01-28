// Removed black arrow from map and added to timetable

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jfbfestival/pages/home/components/live_timetable.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/timetable_data.dart';
import 'package:jfbfestival/settings_page.dart';
import 'package:provider/provider.dart';

// Centralized festival date logic - single source of truth
const int festivalDays = 2;
const int festivalStartYear = 2026;
const int festivalStartMonth = 1;
const int festivalStartDay = 30;
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

  const HomePage({Key? key, this.selectedEvent}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

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
                        LiveTimetable(
                          screenWidth: screenWidth,
                          festivalDays: festivalDays,
                          festivalLocation: festivalLocation,
                          festivalStartDay: festivalStartDay,
                          festivalStartMonth: festivalStartMonth,
                          festivalStartYear: festivalStartYear,
                          dayNumber: getFestivalDay(DateTime.now()),
                        ),
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
