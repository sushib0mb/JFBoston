// =============================================================================
// map_page.dart
//
// Displays an interactive festival map with filter options and zone navigation.
//
// Features:
//   - Animated filter menu (slides in from top) to switch between map overlays
//     (All, Food Vendors, Information Center, Toilets, Trash Station)
//   - AnimatedCrossFade for smooth map image transitions
//   - Zone buttons (A, B, C) that navigate to the corresponding vendor list
//     on the Schedule/List page via MainScreen
//   - Responsive sizing: adapts layout dimensions to phone vs. tablet screens
//
// Usage:
//   Instantiate as a tab inside MainScreen. Zone letter taps push a new
//   MainScreen route with initialIndex: 1 and the selectedMapLetter set.
// =============================================================================

import 'package:flutter/material.dart';

enum MapSection { downtown, bostonCommon }

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  MapPageState createState() => MapPageState();
}

<<<<<<< HEAD
class MapPageState extends State<MapPage> with SingleTickerProviderStateMixin {
  bool _isMiniWindowVisible = false;
  String _selectedFilter = 'All';
  final Duration _animationDuration = const Duration(milliseconds: 300);
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  String _currentMapImage = 'assets/MapNew.png';

  final Map<String, String> mapImages = {
    'All': 'assets/MapNew.png',
    'Food Vendors': 'assets/MapNew4.png',
    'Information Center': 'assets/MapNew3.png',
    'Toilets': 'assets/MapNew1.png',
    'Trash Station': 'assets/MapNew2.png',
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMiniWindow() {
=======
class MapPageState extends State<MapPage> {
  MapSection _selectedMap = MapSection.bostonCommon;

  void _toggleMap() {
>>>>>>> 79ec797026e91f15f0a8fddf7bc9a24dab5dd902
    setState(() {
      if (_selectedMap == MapSection.bostonCommon) {
        _selectedMap = MapSection.downtown;
      } else {
        _selectedMap = MapSection.bostonCommon;
      }
    });
  }

<<<<<<< HEAD
  void _selectFilter(String filter) {
    setState(() {
      _selectedFilter = (_selectedFilter == filter) ? 'All' : filter;
      _isMiniWindowVisible = false;
      _animationController.reverse();
      _currentMapImage = mapImages[_selectedFilter] ?? mapImages['All']!;
    });
  }

  void _onLetterTap(String letter) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MainScreen(initialIndex: 1, selectedMapLetter: letter),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fadeTween = Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut));
          return FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          );
        },
        transitionDuration: _animationDuration,
      ),
    );
  }

=======
>>>>>>> 79ec797026e91f15f0a8fddf7bc9a24dab5dd902
  @override
  Widget build(BuildContext context) {
    final String currentMapImage =
        _selectedMap == MapSection.bostonCommon
            ? 'assets/MapNew.png'
            : 'assets/MapNew2.png';

    final String toggleButtonLabel =
        _selectedMap == MapSection.bostonCommon
            ? 'View Downtown'
            : 'View Boston Common';

    // ── Responsive sizing ────────────────────────────────────────────────────
    final bool isTablet = screenSize.width >= 600;
    final double filterButtonSize = isTablet ? 65.0 : 55.0;
    final double filterIconPad = isTablet ? 14.0 : 10.0;
    final double menuWidth = isTablet ? 0.6 : 0.75;
    final double menuHeight = isTablet ? 0.55 : 0.65;
    final double menuPadding = isTablet ? 32.0 : 24.0;
    final double menuTopMargin = isTablet ? 0.12 : 0.10;
    final double filterBtnVertPad = isTablet ? 24.0 : 20.0;
    final double filterBtnVertMar = isTablet ? 14.0 : 12.0;
    final double filterLabelSize = isTablet ? 24.0 : 22.0;
    final double mapContainerWidth = isTablet ? 0.80 : 0.85;
    final double mapContainerHeight = isTablet ? 0.60 : 0.65;
    final double letterBtnWidth = isTablet ? 100.0 : 80.0;
    final double letterBtnHeight = isTablet ? 42.0 : 35.0;
    final double letterBtnRadius = isTablet ? 12.0 : 10.0;
    final double letterFontSize = isTablet ? 20.0 : 18.0;
    final double filterIconTop = MediaQuery.of(context).padding.top +
        screenSize.height * (isTablet ? 0.012 : 0.015);
    final double filterIconRight = screenSize.width * (isTablet ? 0.04 : 0.05);
    // ────────────────────────────────────────────────────────────────────────

    return Scaffold(
      body: Stack(
        children: [
          Container(color: const Color(0xFFECE0CF)),

          // Centred map with animated cross-fade between filter states
          Center(
<<<<<<< HEAD
            child: AnimatedCrossFade(
              firstChild: _buildMapContainer(
                screenSize,
                _currentMapImage,
                _selectedFilter,
                mapContainerWidth,
                mapContainerHeight,
                letterBtnWidth,
                letterBtnHeight,
                letterBtnRadius,
                letterFontSize,
              ),
              secondChild: _buildMapContainer(
                screenSize,
                targetMapImage,
                _selectedFilter,
                mapContainerWidth,
                mapContainerHeight,
                letterBtnWidth,
                letterBtnHeight,
                letterBtnRadius,
                letterFontSize,
              ),
              crossFadeState: _currentMapImage == targetMapImage
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: _animationDuration,
              layoutBuilder:
                  (topChild, topChildKey, bottomChild, bottomChildKey) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(key: bottomChildKey, child: bottomChild),
                    Positioned(key: topChildKey, child: topChild),
                  ],
                );
              },
            ),
          ),

          // Semi-transparent backdrop + sliding filter menu
          Stack(
            children: [
              if (_isMiniWindowVisible)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _toggleMiniWindow,
                    child: AnimatedContainer(
                      duration: _animationDuration,
                      color: Colors.black.withOpacity(0.4),
                    ),
                  ),
                ),
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !_isMiniWindowVisible,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: AnimatedContainer(
                        duration: _animationDuration,
                        width: screenSize.width * menuWidth,
                        height: screenSize.height * menuHeight,
                        margin: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top +
                              screenSize.height * menuTopMargin,
                        ),
                        padding: EdgeInsets.all(menuPadding),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 12,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.topRight,
                                child: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: _toggleMiniWindow,
                                ),
                              ),
                              _buildFilterButton(
                                  'All', screenSize, menuWidth,
                                  filterBtnVertPad, filterBtnVertMar,
                                  filterLabelSize),
                              _buildFilterButton(
                                  'Food Vendors', screenSize, menuWidth,
                                  filterBtnVertPad, filterBtnVertMar,
                                  filterLabelSize),
                              _buildFilterButton(
                                  'Information Center', screenSize, menuWidth,
                                  filterBtnVertPad, filterBtnVertMar,
                                  filterLabelSize),
                              _buildFilterButton(
                                  'Toilets', screenSize, menuWidth,
                                  filterBtnVertPad, filterBtnVertMar,
                                  filterLabelSize),
                              _buildFilterButton(
                                  'Trash Station', screenSize, menuWidth,
                                  filterBtnVertPad, filterBtnVertMar,
                                  filterLabelSize),
                            ],
=======
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: MediaQuery.of(context).size.width * 0.25,
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          24,
                        ), // Rounded edges
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      // ClipRRect ensures the image doesn't bleed over the rounded corners
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: InteractiveViewer(
                          minScale: 1.0,
                          maxScale: 4.0, // Allows users to zoom in 4x
                          constrained: true,
                          child: Image.asset(
                            currentMapImage,
                            fit: BoxFit.contain,
>>>>>>> 79ec797026e91f15f0a8fddf7bc9a24dab5dd902
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

<<<<<<< HEAD
          // Filter icon button (top-right)
=======
          // Top Right Toggle Button
>>>>>>> 79ec797026e91f15f0a8fddf7bc9a24dab5dd902
          Positioned(
            top: filterIconTop,
            right: filterIconRight,
            child: GestureDetector(
<<<<<<< HEAD
              onTap: _toggleMiniWindow,
              child: AnimatedContainer(
                duration: _animationDuration,
                width: filterButtonSize,
                height: filterButtonSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isMiniWindowVisible || isFilterActive
                      ? Colors.grey.shade300
                      : Colors.white,
=======
              onTap: _toggleMap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
>>>>>>> 79ec797026e91f15f0a8fddf7bc9a24dab5dd902
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
<<<<<<< HEAD
                padding: EdgeInsets.all(filterIconPad),
                child: ClipOval(
                  child: Image.asset(
                    'assets/Filter.png',
                    fit: BoxFit.contain,
                    color: _isMiniWindowVisible || isFilterActive
                        ? Colors.black
                        : null,
                  ),
=======
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.map, color: Colors.black87, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      toggleButtonLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
>>>>>>> 79ec797026e91f15f0a8fddf7bc9a24dab5dd902
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
<<<<<<< HEAD

  // ---------------------------------------------------------------------------
  // Map container: white card holding the map image + optional zone buttons
  // ---------------------------------------------------------------------------
  Widget _buildMapContainer(
    Size screenSize,
    String imagePath,
    String selectedFilter,
    double widthFactor,
    double heightFactor,
    double letterBtnWidth,
    double letterBtnHeight,
    double letterBtnRadius,
    double letterFontSize,
  ) {
    return Container(
      width: screenSize.width * widthFactor,
      height: screenSize.height * heightFactor,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            ),
          ),

          // Zone buttons — hidden for utility-only filter categories
          if (selectedFilter != 'Information Center' &&
              selectedFilter != 'Toilets' &&
              selectedFilter != 'Trash Station')
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLetterButton('A', Colors.red, letterBtnWidth,
                      letterBtnHeight, letterBtnRadius, letterFontSize),
                  _buildLetterButton('B', Colors.blue, letterBtnWidth,
                      letterBtnHeight, letterBtnRadius, letterFontSize),
                  _buildLetterButton('C', Colors.green, letterBtnWidth,
                      letterBtnHeight, letterBtnRadius, letterFontSize),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Coloured zone button (A / B / C) that navigates to the vendor list
  // ---------------------------------------------------------------------------
  Widget _buildLetterButton(
    String letter,
    Color color,
    double width,
    double height,
    double radius,
    double fontSize,
  ) {
    return GestureDetector(
      onTap: () => _onLetterTap(letter),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Filter option button inside the sliding menu
  // ---------------------------------------------------------------------------
  Widget _buildFilterButton(
    String label,
    Size screenSize,
    double widthFactor,
    double vertPad,
    double vertMar,
    double fontSize,
  ) {
    final bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => _selectFilter(label),
      child: Container(
        width: screenSize.width * widthFactor,
        padding: EdgeInsets.symmetric(vertical: vertPad),
        margin: EdgeInsets.symmetric(vertical: vertMar),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade400 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
=======
}
>>>>>>> 79ec797026e91f15f0a8fddf7bc9a24dab5dd902
