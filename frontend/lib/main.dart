// =============================================================================
// main.dart
//
// App entry point and root navigation shell for the JFBoston festival app.
//
// Features:
//   - App initialisation: Hive, dotenv, Supabase, notifications, orientation lock
//   - DevicePreview wrapper (enabled in debug mode only)
//   - MultiProvider setup: ThemeNotifier, ScheduleDataService, SponsorService,
//     DbImageService, LocationService
//   - MyApp: MaterialApp with light/dark theme (Fredoka font) and named routes
//   - MainScreen: IndexedStack tab shell with four pages —
//       0: HomePage, 1: FoodPage, 2: TimetablePage, 3: MapPage
//   - TopBar: centred logo (fixed 60 px, SafeArea-inset by parent)
//   - BottomBar: frosted-glass pill bar with four ImageButton tabs;
//     uses Expanded for even distribution — no screen-width math
//   - ImageButton: tap-state toggle between default and pressed asset images
//   - Fixed layout constants: all sizing defined as static const — no
//     MediaQuery math or isTablet checks
//
// Navigation notes:
//   - selectedMapLetter threads from MapPage zone buttons → FoodPage filter
//   - selectedEvent and selectedDay thread into TimetablePage on deep-link
//   - Switching away from tab 1 clears selectedMapLetter via pushReplacement
// =============================================================================


import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/food_booths.dart';
import 'services/db_image_service.dart';
import 'services/sponsor_service.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/rendering.dart';

import 'theme_notifier.dart';
import 'package:device_preview/device_preview.dart';

import 'pages/settings_page.dart';
import 'pages/survey/quick_survey_popup.dart';
import 'pages/food/food_page.dart';
import 'pages/home/home_page.dart';
import 'pages/map_page.dart';
import 'pages/timetable/timetable_page.dart';
import 'data/timetable_data.dart';
import 'models/feedback_entry.dart';
import 'models/survey_entry.dart';
import 'config/supabase_config.dart';
import 'services/notification_service.dart';
import 'services/location_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPaintSizeEnabled = false;
  debugPaintBaselinesEnabled = false;
  debugPaintLayerBordersEnabled = false;
  debugRepaintRainbowEnabled = false;

  await dotenv.load();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Hive.initFlutter();
  Hive.registerAdapter(FeedbackEntryAdapter());
  Hive.registerAdapter(SurveyEntryAdapter());
  await Hive.openBox<FeedbackEntry>('feedback');
  await Hive.openBox<SurveyEntry>('survey');

  await notificationService.init();

  developer.log('Supabase client initialized: $supabase', name: 'SupabaseInit');
  initFoodBoothsService(supabase);

  runApp(
    DevicePreview(
      enabled: kDebugMode,
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeNotifier()),
          ChangeNotifierProvider(create: (_) => ScheduleDataService(supabase)),
          ChangeNotifierProvider(create: (_) => SponsorService(supabase)),
          ChangeNotifierProvider(create: (_) => DbImageService(supabase)),
          ChangeNotifierProvider(create: (_) => LocationService()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, theme, _) => MaterialApp(
        useInheritedMediaQuery: true,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        debugShowCheckedModeBanner: false,
        title: 'JFB Festival',
        theme: ThemeData(
          brightness: Brightness.light,
          fontFamily: 'Fredoka',
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'Fredoka',
        ),
        themeMode: theme.mode,
        home: const MainScreen(),
        routes: {
          SettingsPage.routeName: (_) => const SettingsPage(),
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final int initialIndex;
  final EventItem? selectedEvent;
  final String? selectedMapLetter;
  final int? selectedDay;

  const MainScreen({
    super.key,
    this.initialIndex = 0,
    this.selectedEvent,
    this.selectedMapLetter,
    this.selectedDay,
  });

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  late int _dayForTimetable;
  static const _kAllergyDisclaimerKey = 'allergyDisclaimerShown';

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _dayForTimetable = widget.selectedDay ?? 1;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.initialIndex == 0) {
        await _maybeShowAllergyDisclaimer();
      }
    });
  }

  Future<void> _maybeShowAllergyDisclaimer() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool(_kAllergyDisclaimerKey) ?? false;
    if (shown) return;
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isChecked = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Allergy Disclaimer'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'All allergen information displayed in this app is provided directly '
                      'by the vendors and is presented exactly as received. '
                      'This listing typically covers only the 9 major allergens '
                      '(Milk, Eggs, Fish, Shellfish, Tree Nuts, Peanuts, Wheat, Soy, and Sesame).\n\n'
                      'JFB and the app developers do not verify ingredients and cannot guarantee '
                      'that food is allergen-free. Always confirm details directly with the vendor '
                      'before consumption.\n\n'
                      'Note on Images: Photos are provided by vendors or are for illustrative '
                      'purposes only. Actual food items may vary in appearance.',
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: isChecked,
                            onChanged: (val) {
                              setState(() => isChecked = val ?? false);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'I confirm that I have read and understand this disclaimer.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isChecked
                      ? () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool(_kAllergyDisclaimerKey, true);
                          if (context.mounted) Navigator.of(context).pop();
                        }
                      : null,
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
      if (index != 1 && widget.selectedMapLetter != null) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => MainScreen(
              initialIndex: index,
              selectedEvent: widget.selectedEvent,
              selectedMapLetter: null,
              selectedDay: _dayForTimetable,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final fadeTween = Tween(begin: 0.0, end: 1.0)
                  .chain(CurveTween(curve: Curves.easeInOut));
              return FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(),
      FoodPage(selectedMapLetter: widget.selectedMapLetter),
      TimetablePage(
        selectedEvent: widget.selectedEvent,
        selectedDay: _dayForTimetable,
      ),
      MapPage(),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: pages),
          SafeArea(child: TopBar(selectedIndex: _currentIndex)),
          Align(
            alignment: Alignment.bottomCenter,
            child: BottomBar(
              selectedIndex: _currentIndex,
              onItemTapped: _onItemTapped,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── FIXED: TopBar ────────────────────────────────────────────────────────────
// Removed screenWidth/screenHeight calculations.
// Logo uses a fixed constant size; SafeArea in parent handles top inset.
class TopBar extends StatelessWidget {
  final int selectedIndex;
  const TopBar({super.key, required this.selectedIndex});

  // Fixed size — does not depend on screen dimensions
  static const double _logoSize = 60.0;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: _logoSize,
        height: _logoSize,
        child: ClipOval(
          child: Image.asset(
            'assets/JFBLogo.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

// ─── FIXED: BottomBar ─────────────────────────────────────────────────────────
// Removed all screenWidth-based calculations.
// Uses const EdgeInsets for padding and Expanded for icon distribution.
class BottomBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomBar({
    required this.selectedIndex,
    required this.onItemTapped,
    super.key,
  });

  // All sizes are fixed constants — no screen-size math
  static const double _barHeight = 88.0;
  static const double _horizontalPadding = 12.0;
  static const double _bottomMargin = 20.0;
  static const double _borderRadius = 100.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: Container(
        height: _barHeight,
        margin: const EdgeInsets.only(bottom: _bottomMargin),
        child: Stack(
          children: [
            // Blurred background
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_borderRadius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(_borderRadius),
                    ),
                  ),
                ),
              ),
            ),
            // Icons distributed evenly using Expanded — no manual spacing
            Row(
              children: [
                Expanded(
                  child: ImageButton(
                    index: 0,
                    defaultImage: "assets/bottomBar/Home.png",
                    pressedImage: "assets/bottomBar/Home(Frame).png",
                    selectedIndex: selectedIndex,
                    onSelect: onItemTapped,
                  ),
                ),
                Expanded(
                  child: ImageButton(
                    index: 1,
                    defaultImage: "assets/bottomBar/Food.png",
                    pressedImage: "assets/bottomBar/Food(Frame).png",
                    selectedIndex: selectedIndex,
                    onSelect: onItemTapped,
                  ),
                ),
                Expanded(
                  child: ImageButton(
                    index: 2,
                    defaultImage: "assets/bottomBar/Timetable.png",
                    pressedImage: "assets/bottomBar/Timetable(Frame).png",
                    selectedIndex: selectedIndex,
                    onSelect: onItemTapped,
                  ),
                ),
                Expanded(
                  child: ImageButton(
                    index: 3,
                    defaultImage: "assets/bottomBar/Map.png",
                    pressedImage: "assets/bottomBar/Map(Frame).png",
                    selectedIndex: selectedIndex,
                    onSelect: onItemTapped,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── FIXED: ImageButton ───────────────────────────────────────────────────────
// Replaced local final variables with static const — sizes never recalculated.
// Center widget ensures proper alignment inside Expanded parent.
class ImageButton extends StatefulWidget {
  final int index;
  final String defaultImage;
  final String pressedImage;
  final int selectedIndex;
  final Function(int) onSelect;

  const ImageButton({
    required this.index,
    required this.defaultImage,
    required this.pressedImage,
    required this.selectedIndex,
    required this.onSelect,
    super.key,
  });

  @override
  _ImageButtonState createState() => _ImageButtonState();
}

class _ImageButtonState extends State<ImageButton> {
  bool isPressed = false;

  // Fixed constants — no runtime screen-size math
  static const double _containerSize = 60.0;
  static const double _iconSize = 52.0;

  void _onTapDown(TapDownDetails details) =>
      setState(() => isPressed = true);

  void _onTapUp(TapUpDetails details) =>
      setState(() => isPressed = false);

  void _onTapCancel() =>
      setState(() => isPressed = false);

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selectedIndex == widget.index;
    final imageToShow = isPressed ? widget.pressedImage : widget.defaultImage;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () => widget.onSelect(widget.index),
      child: Center(
        child: Container(
          width: _containerSize,
          height: _containerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected && !isPressed
                ? Colors.white.withOpacity(0.7)
                : Colors.transparent,
          ),
          child: Center(
            child: ClipOval(
              child: Image.asset(
                imageToShow,
                width: _iconSize,
                height: _iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}