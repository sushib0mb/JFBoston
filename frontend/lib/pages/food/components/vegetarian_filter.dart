import 'package:flutter/material.dart';

class VegetarianFilterOption extends StatelessWidget {
  final bool isVegetarian;
  final ValueChanged<bool> onChanged;

  const VegetarianFilterOption({
    required this.isVegetarian,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
        final double boxSize = isTablet ? 80 : 60;

        return GestureDetector(
          onTap: () => onChanged(!isVegetarian),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: boxSize,
                height: boxSize,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isVegetarian
                          ? const Color(0xFFF0FDF4)
                          : Colors.transparent, // Very subtle green tint
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isVegetarian
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFE4E4E7),
                    width: isVegetarian ? 1.5 : 1.0,
                  ),
                ),
                child: Image.asset(
                  'assets/vegetarian.png',
                  color: isVegetarian ? null : const Color(0xFFA1A1AA),
                  colorBlendMode: isVegetarian ? null : BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isVegetarian ? 'Vegetarian' : 'All Diets',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 13,
                  fontWeight: isVegetarian ? FontWeight.w600 : FontWeight.w500,
                  color:
                      isVegetarian
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFA1A1AA),
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
