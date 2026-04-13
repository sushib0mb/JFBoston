import 'package:flutter/material.dart';

class VeganFilterOption extends StatelessWidget {
  final bool isVegan;
  final ValueChanged<bool> onChanged;

  const VeganFilterOption({
    required this.isVegan,
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
          onTap: () => onChanged(!isVegan),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: boxSize,
                height: boxSize,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isVegan ? const Color(0xFFF0FDF4) : Colors.transparent, // Very subtle green tint
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isVegan ? const Color(0xFF16A34A) : const Color(0xFFE4E4E7),
                    width: isVegan ? 1.5 : 1.0,
                  ),
                ),
                child: Image.asset(
                  'assets/vegan.png',
                  color: isVegan ? null : const Color(0xFFA1A1AA),
                  colorBlendMode: isVegan ? null : BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isVegan ? 'Vegetarian' : 'All Diets',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 13,
                  fontWeight: isVegan ? FontWeight.w600 : FontWeight.w500,
                  color: isVegan ? const Color(0xFF16A34A) : const Color(0xFFA1A1AA),
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