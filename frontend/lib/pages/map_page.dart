import 'package:flutter/material.dart';
import 'package:jfbfestival/main.dart';

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
  String _currentMapImage = 'assets/MapNew.png'; // Initial map image

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
      begin: const Offset(0, -1), // Start off-screen at the top
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
      if (_selectedFilter == filter) {
        _selectedFilter = 'All';
      } else {
        _selectedFilter = filter;
      }
      _isMiniWindowVisible = false;
      _animationController.reverse();
      _currentMapImage =
          mapImages[_selectedFilter] ??
          mapImages['All']!; // Update current map image
    });
  }

  void _onLetterTap(String letter) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                MainScreen(initialIndex: 1, selectedMapLetter: letter),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = 0.0;
          const end = 1.0;
          const curve = Curves.easeInOut;

          var fadeTween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var opacityAnimation = animation.drive(fadeTween);

          return FadeTransition(opacity: opacityAnimation, child: child);
        },
        transitionDuration:
            _animationDuration, // Use the existing animation duration
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isFilterActive = _selectedFilter != 'All';
    final String targetMapImage =
        mapImages[_selectedFilter] ?? mapImages['All']!;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromRGBO(10, 56, 117, 0.15),
                  Color.fromRGBO(191, 28, 36, 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Center the map container in the middle of the screen
          Center(
            child: AnimatedCrossFade(
              firstChild: _buildMapContainer(
                screenSize,
                _currentMapImage,
                _selectedFilter,
              ),
              secondChild: _buildMapContainer(
                screenSize,
                targetMapImage,
                _selectedFilter,
              ),
              crossFadeState:
                  _currentMapImage == targetMapImage
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
              duration: _animationDuration,
              layoutBuilder: (
                topChild,
                topChildKey,
                bottomChild,
                bottomChildKey,
              ) {
                return Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Positioned(key: bottomChildKey, child: bottomChild),
                    Positioned(key: topChildKey, child: topChild),
                  ],
                );
              },
            ),
          ),

          // Mini window overlay
          Stack(
            children: [
              // Full-screen semi-transparent background
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
              // Sliding filter menu
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  ignoring: !_isMiniWindowVisible,
                  child: Align(
                    alignment:
                        Alignment.topCenter, // Or another alignment if desired
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: AnimatedContainer(
                        // Added AnimatedContainer for potential future animations
                        duration: _animationDuration,
                        width: screenSize.width * 0.75,
                        height: screenSize.height * 0.65,
                        margin: EdgeInsets.only(
                          top:
                              MediaQuery.of(context).padding.top +
                              MediaQuery.of(context).size.height * 0.1,
                        ), // Adjust top margin as needed
                        padding: const EdgeInsets.all(24),
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
                              _buildFilterButton('All', screenSize),
                              _buildFilterButton('Food Vendors', screenSize),
                              _buildFilterButton(
                                'Information Center',
                                screenSize,
                              ),
                              _buildFilterButton('Toilets', screenSize),
                              _buildFilterButton('Trash Station', screenSize),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Filter icon button
          Positioned(
            top:
                MediaQuery.of(context).padding.top +
                MediaQuery.of(context).size.height * 0.015,
            right: MediaQuery.of(context).size.width * 0.05,
            child: GestureDetector(
              onTap: _toggleMiniWindow,
              child: AnimatedContainer(
                duration: _animationDuration,
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                  color:
                      _isMiniWindowVisible || isFilterActive
                          ? Colors.grey.shade300
                          : Colors.white,
                ),
                padding: const EdgeInsets.all(10),
                child: ClipOval(
                  child: Image.asset(
                    'assets/Filter.png',
                    fit: BoxFit.contain,
                    color:
                        _isMiniWindowVisible || isFilterActive
                            ? Colors.black
                            : null,
                  ),
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
  ) {
    return Container(
      width: screenSize.width * 0.85,
      height: screenSize.height * 0.65,
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
          // Image takes most of the space
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

          // Add letter buttons below the image but inside the container
          if (selectedFilter != 'Information Center' &&
              selectedFilter != 'Toilets' &&
              selectedFilter != 'Trash Station')
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLetterButton('A', Colors.red),
                  _buildLetterButton('B', Colors.blue),
                  _buildLetterButton('C', Colors.green),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLetterButton(String letter, Color color) {
    return GestureDetector(
      onTap: () => _onLetterTap(letter),
      child: Container(
        width: 80,
        height: 35,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, Size screenSize) {
    bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => _selectFilter(label),
      child: Container(
        width: screenSize.width * 0.75,
        padding: const EdgeInsets.symmetric(vertical: 20),
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade400 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
