import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/icon_service.dart';

class PerformanceIconDropdown extends StatefulWidget {
  const PerformanceIconDropdown({Key? key}) : super(key: key);

  @override
  _PerformanceIconDropdownState createState() =>
      _PerformanceIconDropdownState();
}

class _PerformanceIconDropdownState extends State<PerformanceIconDropdown> {
  // Local state to track what the admin currently has selected
  String? _selectedIconUrl;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    // Consumer listens to IconService and rebuilds ONLY this widget when notifyListeners() is called
    return Consumer<IconService>(
      builder: (context, iconService, child) {
        // Loading State
        if (iconService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Error State
        if (iconService.errorMessage != null) {
          return Text('Error loading icons: ${iconService.errorMessage}');
        }

        // Empty State
        if (iconService.iconUrls.isEmpty) {
          return const Text('No icons found in storage.');
        }

        // If the list refreshed and the previously selected URL is gone, reset it
        if (_selectedIconUrl != null &&
            !iconService.iconUrls.contains(_selectedIconUrl)) {
          _selectedIconUrl = null;
        }

        // Build the Dropdown
        return DropdownButton<String>(
          value: _selectedIconUrl,
          hint: const Text('Select a performance icon'),
          isExpanded: true,
          menuMaxHeight: screenHeight * 0.4,
          items:
              iconService.iconUrls.map((String url) {
                final fileName = url.split('/').last.split('?').first;

                return DropdownMenuItem<String>(
                  value: url,
                  child: Row(
                    children: [
                      CachedNetworkImage(
                        imageUrl: url,
                        width: 30,
                        height: 30,
                        fit: BoxFit.contain,
                        placeholder:
                            (context, url) => const SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        errorWidget:
                            (context, url, error) =>
                                const Icon(Icons.broken_image, size: 30),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          Uri.decodeFull(fileName),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          onChanged: (String? newValue) {
            // Update the local state so the dropdown shows the new selection
            setState(() {
              _selectedIconUrl = newValue;
            });
          },
        );
      },
    );
  }
}
