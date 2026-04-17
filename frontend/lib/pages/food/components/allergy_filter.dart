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
        final bool isTablet = constraints.maxWidth > 600;
        final double spacing = isTablet ? 20 : 16;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: isTablet ? 1.1 : 0.95,
          ),
          itemCount: allergens.length,
          itemBuilder: (context, index) {
            final label = allergens[index];
            final isSelected = selectedAllergens.contains(label);
            return _buildTile(label, isSelected, isTablet);
          },
        );
      },
    );
  }

  Widget _buildTile(String label, bool isSelected, bool isTablet) {
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
                color: isSelected ? null : const Color(0xFFA1A1AA),
                colorBlendMode: isSelected ? null : BlendMode.srcIn,
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
