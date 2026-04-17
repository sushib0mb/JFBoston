/// ────────────────────────────────────────────────────────────────────────────
/// DYNAMIC ALLERGY FILTER GRID - SHADCN EDITION
/// ────────────────────────────────────────────────────────────────────────────
/// Features:
/// - LayoutBuilder for real-time constraint sensing.
/// - Adaptive childAspectRatio to prevent text overflow on narrow screens.
/// - Dynamic icon scaling based on available width.
/// ────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class AllergyFilterGrid extends StatelessWidget {
  final Set<String> selectedAllergens;
  final void Function(String, bool) onAllergenSelected;

  const AllergyFilterGrid({
    required this.selectedAllergens,
    required this.onAllergenSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const allergens = [
      "Egg", "Wheat", "Peanut", "Milk", "Soy", 
      "Tree Nut", "Fish", "Shellfish", "Sesame",
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate dynamic counts based on width
        final double width = constraints.maxWidth;
        final int crossCount = width > 600 ? 4 : 3;
        
        // Dynamically calculate spacing: 4% of width
        final double spacing = width * 0.04;
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(vertical: spacing),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: 0.85,
          ),
          itemCount: allergens.length,
          itemBuilder: (ctx, i) {
            final a = allergens[i];
            final isSelected = selectedAllergens.contains(a);

            return _buildDynamicTile(context, a, isSelected, width / crossCount);
          },
        );
      },
    );
  }

  Widget _buildDynamicTile(BuildContext context, String label, bool isSelected, double cellWidth) {
    final bool isTablet = cellWidth > 150;
    final double boxSize = isTablet ? 70 : 54;
    final double iconSize = isTablet ? 32 : 24;
    final double fontSize = isTablet ? 14.0 : 11.0;

    return GestureDetector(
      onTap: () => onAllergenSelected(label, !isSelected),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: boxSize,
            height: boxSize,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF4F4F5) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF18181B) : const Color(0xFFE4E4E7),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Center(
              child: Image.asset(
                'assets/allergens/${label.toLowerCase().replaceAll(' ', '_')}.png',
                width: iconSize,
                height: iconSize,
                color: isSelected ? null : Colors.grey.withValues(alpha: 0.4),
                colorBlendMode: isSelected ? null : BlendMode.modulate,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? const Color(0xFF18181B) : const Color(0xFFA1A1AA),
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}