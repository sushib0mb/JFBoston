import 'package:flutter/material.dart';

class StageSelectorPill extends StatelessWidget {
  final String selectedValue;
  final Map<String, String> options;
  final ValueChanged<String> onSelected;

  const StageSelectorPill({
    super.key,
    required this.selectedValue,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(9999),
      ),
      child: PopupMenuButton<String>(
        initialValue: selectedValue,
        // Pushes the dropdown menu items down
        offset: const Offset(0, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.grey[900],
        // Triggers the callback passed from the parent
        onSelected: onSelected,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17.5, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                // Display the mapped label, or fallback to the raw value
                options[selectedValue] ?? selectedValue,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white),
            ],
          ),
        ),
        // Dynamically build the menu items based on the provided map
        itemBuilder: (BuildContext context) {
          return options.entries.map((entry) {
            return PopupMenuItem<String>(
              value: entry.key,
              child: Text(
                entry.value,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList();
        },
      ),
    );
  }
}
