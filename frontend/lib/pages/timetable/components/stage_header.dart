import 'package:flutter/material.dart';
import 'package:jfbfestival/services/location_service.dart';
import 'package:provider/provider.dart';

class StageHeader extends StatelessWidget {
  final List<String> stageNames;
  final List<String> stageLabels;
  final String selectedStage;
  final bool isTablet;
  final ValueChanged<String> onStageSelected;

  const StageHeader({
    super.key,
    required this.stageNames,
    required this.stageLabels,
    required this.selectedStage,
    required this.isTablet,
    required this.onStageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: List.generate(stageNames.length, (i) {
          final isSelected = selectedStage == stageNames[i];
          final loc = context.watch<LocationService>();
          final dist = loc.formatDistance(stageNames[i]);

          return Expanded(
            child: GestureDetector(
              // Trigger the callback to update the parent's state
              onTap: () => onStageSelected(stageNames[i]),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? const Color(0xFFBF1D23)
                          : const Color(0xFFD4706E),
                  borderRadius: BorderRadius.circular(36),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      stageLabels[i],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 13 : 10.5,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (dist.isNotEmpty)
                      Text(
                        dist,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: isTablet ? 11 : 9,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
