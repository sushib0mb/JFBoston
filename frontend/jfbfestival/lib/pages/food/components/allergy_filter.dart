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
    final size       = MediaQuery.of(context).size;
    final screenW    = size.width;
    final isTablet   = screenW >= 600;
    // 3 columns on phone, 4 on tablet
    final crossCount = isTablet ? 4 : 3;
    // tighter on phone, more breathing on tablet
    final gridSpacing      = isTablet ? 12.0 : 8.0;
    final iconContainer    = isTablet ? 60.0 : 40.0;
    final iconImageSize    = isTablet ? 50.0 : 44.0;
    final labelFontSize    = isTablet ? 25.0 : 14.0;
    final labelVerticalGap = isTablet ? 8.0  : 6.0;

    const allergens = [
      "Egg",
      "Wheat",
      "Peanut",
      "Milk",
      "Soy",
      "Tree Nut",
      "Fish",
      "Shellfish",
      "Sesame",
    ];

    return GridView.builder(
      // shrinkWrap so it takes only as much height as it needs
      shrinkWrap: true,
      // allow the grid itself to scroll if it exceeds its parent’s viewport
      physics: const NeverScrollableScrollPhysics(), 
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        crossAxisSpacing: gridSpacing,
        mainAxisSpacing: gridSpacing,
        // roughly square tiles
        childAspectRatio: 1.0,
      ),
      itemCount: allergens.length,
      itemBuilder: (ctx, i) {
        final a = allergens[i];
        final sel = selectedAllergens.contains(a);

        return GestureDetector(
          onTap: () => onAllergenSelected(a, !sel),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: iconContainer,
                height: iconContainer,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isTablet ? 28 : 24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 10,
                    ),
                  ],
                  border: Border.all(
                    color: sel ? Colors.red : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/allergens/${a.toLowerCase().replaceAll(' ', '_')}.png',
                    width: iconImageSize,
                    height: iconImageSize,
                    color: sel ? null : Colors.grey.withOpacity(0.5),
                    colorBlendMode: BlendMode.modulate,
                  ),
                ),
              ),

              SizedBox(height: labelVerticalGap),

              Text(
                a,
                style: TextStyle(
                  fontSize: labelFontSize,
                  color: sel ? Colors.black : Colors.grey[400],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
