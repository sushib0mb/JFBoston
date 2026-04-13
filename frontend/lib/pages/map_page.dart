import 'package:flutter/material.dart';

enum MapSection { downtown, bostonCommon }

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  MapPageState createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  MapSection _selectedMap = MapSection.bostonCommon;

  void _toggleMap() {
    setState(() {
      if (_selectedMap == MapSection.bostonCommon) {
        _selectedMap = MapSection.downtown;
      } else {
        _selectedMap = MapSection.bostonCommon;
      }
    });
  }

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

    return Scaffold(
      body: Stack(
        children: [
          Container(color: const Color(0xFFECE0CF)),

          // Center the map container in the middle of the screen
          Center(
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

          // Top Right Toggle Button
          Positioned(
            top:
                MediaQuery.of(context).padding.top +
                MediaQuery.of(context).size.height * 0.015,
            right: MediaQuery.of(context).size.width * 0.05,
            child: GestureDetector(
              onTap: _toggleMap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
