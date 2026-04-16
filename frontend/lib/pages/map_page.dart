import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';

class MapPage extends StatefulWidget {
  final SupabaseClient _supabase;

  const MapPage(this._supabase, {super.key});

  @override
  MapPageState createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  late final PageController _pageController;
  int _currentPage = 0;

  final String _mainStageFile = 'mapImages/MainMap.png';
  final String _downtownFile = 'mapImages/DowntownMap.png';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleMap() {
    final next = _currentPage == 0 ? 1 : 0;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
    setState(() => _currentPage = next);
  }

  String _getSupabaseImageUrl(String fileName) {
    return widget._supabase.storage.from('images').getPublicUrl(fileName);
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    final bool isTablet = screenSize.width >= 600;
    final double mapContainerHeight = isTablet ? 0.60 : 0.65;

    final double buttonTop =
        MediaQuery.of(context).padding.top +
        screenSize.height * (isTablet ? 0.012 : 0.02);
    final double buttonRight = screenSize.width * (isTablet ? 0.04 : 0.05);

    return Scaffold(
      body: Stack(
        children: [
          Container(color: const Color(0xFFECE0CF)),

          // Map PageView for smooth slide
          Center(
            child: SizedBox(
              height: screenSize.height * mapContainerHeight,
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildMapContainer(screenSize, _mainStageFile, mapContainerHeight),
                  _buildMapContainer(screenSize, _downtownFile, mapContainerHeight),
                ],
              ),
            ),
          ),

          // Toggle button
          Positioned(
            top: buttonTop,
            right: buttonRight,
            child: ElevatedButton.icon(
              onPressed: _toggleMap,
              icon: const Icon(Icons.swap_horiz, color: Colors.black87),
              label: Text(
                _currentPage == 0 ? 'Downtown' : 'Main Stage',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapContainer(Size screenSize, String fileName, double heightFactor) {
    return Container(
      height: screenSize.height * heightFactor,
      margin: const EdgeInsets.symmetric(horizontal: 25),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            _getSupabaseImageUrl(fileName),
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Text(
                "Map Coming Soon!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
