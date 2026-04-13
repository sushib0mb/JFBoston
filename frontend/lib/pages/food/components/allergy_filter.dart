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
        
        // Adaptive Aspect Ratio: 
        // Narrower screens need more vertical space for text (lower ratio)
        final double adaptiveRatio = width > 400 ? 0.9 : 0.75;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(vertical: spacing),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: adaptiveRatio,
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
    // Dynamic sizing based on the cell width
    final double iconPadding = cellWidth * 0.15;
    final double fontSize = (cellWidth * 0.12).clamp(10.0, 16.0);

    return GestureDetector(
      onTap: () => onAllergenSelected(label, !isSelected),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded( // Use Expanded to let the container fill available height
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(iconPadding),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF4F4F5) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFF18181B) : const Color(0xFFE4E4E7),
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Image.asset(
                'assets/allergens/${label.toLowerCase().replaceAll(' ', '_')}.png',
                color: isSelected ? null : Colors.grey.withOpacity(0.4),
                colorBlendMode: isSelected ? null : BlendMode.modulate,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis, // Guard against very long labels
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFF18181B) : const Color(0xFFA1A1AA),
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}