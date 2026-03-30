import 'package:flutter/material.dart';

class VeganFilterOption extends StatefulWidget {
  final bool isVegan;
  final ValueChanged<bool> onChanged;

  const VeganFilterOption({
    required this.isVegan,
    required this.onChanged,
    super.key,
  });

  @override
  State<VeganFilterOption> createState() => _VeganFilterOptionState();
}

class _VeganFilterOptionState extends State<VeganFilterOption> {
  @override
  Widget build(BuildContext context) {
    final isVegan    = widget.isVegan;
    final screenW    = MediaQuery.of(context).size.width;
    final isTablet   = screenW >= 600;

    // Tablet vs phone sizing
    final double containerSize = isTablet ? 60 : 40;
    final double imageSize     = isTablet ? 64 : 44;
    final double borderRadius  = containerSize / 2;
    final double gap           = isTablet ? 12 : 8;
    final double fontSize      = isTablet ? 25 : 16;

    return GestureDetector(
      onTap: () => widget.onChanged(!isVegan),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: containerSize,
            height: containerSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
              border: Border.all(
                color: isVegan ? Colors.green : Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(
              child: Image.asset(
                'assets/vegan.png',
                width: imageSize,
                height: imageSize,
                color: isVegan ? null : Colors.grey.withOpacity(0.5),
                colorBlendMode: BlendMode.modulate,
              ),
            ),
          ),

          SizedBox(height: gap),

          Text(
            isVegan ? 'Vegetarian' : 'Not Vegetarian',
            style: TextStyle(
              fontSize: fontSize,
              color: isVegan ? Colors.black : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}