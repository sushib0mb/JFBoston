import 'package:flutter/material.dart';

class TopActionButtons extends StatelessWidget {
  final bool isSearching;
  final VoidCallback onSearchPressed;
  final VoidCallback onFilterPressed;
  // We pass the focus node so the parent can still manage it if needed
  final FocusNode? searchFocusNode;

  const TopActionButtons({
    super.key,
    required this.isSearching,
    required this.onSearchPressed,
    required this.onFilterPressed,
    this.searchFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    // You can keep your responsive logic right inside the build method
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return Positioned(
      top:
          MediaQuery.of(context).padding.top +
          MediaQuery.of(context).size.height * 0.015,
      right: MediaQuery.of(context).size.width * 0.05,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child:
                isSearching
                    ? const SizedBox.shrink()
                    : _CustomIconButton(
                      icon: Icons.search,
                      isTablet: isTablet,
                      onPressed: onSearchPressed,
                    ),
          ),
          const SizedBox(width: 10),
          _CustomIconButton(
            iconAsset: 'assets/Filter.png',
            isTablet: isTablet,
            onPressed: onFilterPressed,
          ),
        ],
      ),
    );
  }
}

// Internal helper widget (private to this file)
class _CustomIconButton extends StatelessWidget {
  final IconData? icon;
  final String? iconAsset;
  final VoidCallback onPressed;
  final bool isTablet;

  const _CustomIconButton({
    this.icon,
    this.iconAsset,
    required this.onPressed,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final double btnSize = isTablet ? 70.0 : 55.0;
    final double padding = isTablet ? 14.0 : 10.0;
    final double iconSize = isTablet ? 36.0 : 30.0;
    final double elevation = isTablet ? 12.0 : 10.0;

    return GestureDetector(
      onTap: onPressed,
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
                color: Colors.black.withOpacity(0.15),
                blurRadius: elevation,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child:
                iconAsset != null
                    ? Image.asset(iconAsset!, fit: BoxFit.contain)
                    : Icon(icon, size: iconSize),
          ),
        ),
      ),
    );
  }
}
