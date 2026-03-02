import 'package:flutter/material.dart';

class StringDropdown extends StatelessWidget {
  final List<String> options;
  final String label;
  final String? initialSelection;
  final ValueChanged<String?> onSelected;
  final String errorMessage;

  const StringDropdown({
    super.key,
    required this.options,
    required this.label,
    required this.onSelected,
    required this.errorMessage, // Add a custom error message
    this.initialSelection,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap the entire thing in a FormField
    return FormField<String>(
      initialValue: initialSelection,
      validator: (value) {
        // Check if the selection is null or empty
        if (value == null || value.isEmpty) {
          return errorMessage;
        }
        return null;
      },
      builder: (FormFieldState<String> state) {
        return DropdownMenu<String>(
          initialSelection: state.value,
          label: Text(label),
          expandedInsets: EdgeInsets.zero,

          // This built-in property automatically turns the border red
          // and displays the text if state.errorText is not null!
          errorText: state.errorText,

          onSelected: (String? newValue) {
            // 1. Tell the FormField that the value has changed
            state.didChange(newValue);

            // 2. Pass the value back up to your main page
            onSelected(newValue);
          },
          dropdownMenuEntries:
              options.map((String value) {
                return DropdownMenuEntry<String>(value: value, label: value);
              }).toList(),
        );
      },
    );
  }
}
