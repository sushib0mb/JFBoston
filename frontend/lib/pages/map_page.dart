// =============================================================================
// map_page.dart
//
// Displays an interactive festival map with filter options and zone navigation.
// =============================================================================

import 'package:flutter/material.dart';
import '../main.dart'; // Ensure this points to your MainScreen location

enum MapSection { downtown, bostonCommon }

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  MapPageState createState() => MapPageState();
}

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
    setState(() {
      _isMiniWindowVisible = !_isMiniWindowVisible;
      if (_isMiniWindowVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

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

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isFilterActive = _selectedFilter != 'All';
    final String targetMapImage = mapImages[_selectedFilter] ?? mapImages['All']!;

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

    return Scaffold(
      body: Stack(
        children: [
          Container(color: const Color(0xFFECE0CF)),

          // Map Container
          Center(
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
            ),
          ),

          // Backdrop and Sliding Menu
          if (_isMiniWindowVisible)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleMiniWindow,
                child: Container(color: Colors.black.withOpacity(0.4)),
              ),
            ),

          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_isMiniWindowVisible,
              child: Align(
                alignment: Alignment.topCenter,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
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
                        children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _toggleMiniWindow,
                            ),
                          ),
                          _buildFilterButton('All', screenSize, menuWidth,
                              filterBtnVertPad, filterBtnVertMar, filterLabelSize),
                          _buildFilterButton('Food Vendors', screenSize, menuWidth,
                              filterBtnVertPad, filterBtnVertMar, filterLabelSize),
                          _buildFilterButton('Information Center', screenSize, menuWidth,
                              filterBtnVertPad, filterBtnVertMar, filterLabelSize),
                          _buildFilterButton('Toilets', screenSize, menuWidth,
                              filterBtnVertPad, filterBtnVertMar, filterLabelSize),
                          _buildFilterButton('Trash Station', screenSize, menuWidth,
                              filterBtnVertPad, filterBtnVertMar, filterLabelSize),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Filter Button Icon
          Positioned(
            top: filterIconTop,
            right: filterIconRight,
            child: GestureDetector(
              onTap: _toggleMiniWindow,
              child: Container(
                width: filterButtonSize,
                height: filterButtonSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isMiniWindowVisible || isFilterActive
                      ? Colors.grey.shade300
                      : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                padding: EdgeInsets.all(filterIconPad),
                child: Image.asset(
                  'assets/Filter.png',
                  fit: BoxFit.contain,
                  color: _isMiniWindowVisible || isFilterActive
                      ? Colors.black
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
              child: Image.asset(imagePath, fit: BoxFit.contain),
            ),
          ),
          if (selectedFilter == 'All' || selectedFilter == 'Food Vendors')
            Padding(
              padding: const EdgeInsets.only(bottom: 20, top: 10),
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

  Widget _buildLetterButton(String letter, Color color, double width,
      double height, double radius, double fontSize) {
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
                offset: const Offset(0, 3)),
          ],
        ),
        child: Center(
          child: Text(letter,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, Size screenSize, double widthFactor,
      double vertPad, double vertMar, double fontSize) {
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
                color: isSelected ? Colors.black : Colors.black87),
          ),
        ),
      ),
    );
  }
}