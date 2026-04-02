import 'package:flutter/material.dart';
import '../../../utils/time_utils.dart';

// Helper method to create the Clickable Performance Boxes
class PerformanceBox extends StatelessWidget {
  const PerformanceBox({
    super.key,
    required this.title,
    required this.startTime,
    required this.duration,
    required this.onTap,
    required this.isChecked,
    required this.onCheckboxChanged,
  });

  final String title;
  final String startTime;
  final int duration;
  final VoidCallback onTap;
  final bool isChecked;
  final ValueChanged<bool?> onCheckboxChanged;

  @override
  Widget build(BuildContext context) {
    String endTime = findEndTime(startTime, duration);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Checkbox added on the left
                  Checkbox(
                    value: isChecked,
                    onChanged: onCheckboxChanged,
                    activeColor:
                        Colors.blue, // Feel free to customize the color
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$startTime - $endTime",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Click Indicator Arrow
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
