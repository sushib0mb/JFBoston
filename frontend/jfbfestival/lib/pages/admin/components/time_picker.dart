import 'package:flutter/material.dart';

class TimePicker extends StatefulWidget {
  final String label;
  final String errorMessage;
  final ValueChanged<TimeOfDay> onChanged;

  const TimePicker({
    super.key,
    required this.label,
    required this.errorMessage,
    required this.onChanged,
  });

  @override
  _TimePickerState createState() => _TimePickerState();
}

class _TimePickerState extends State<TimePicker> {
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<TimeOfDay>(
      initialValue: _selectedTime,
      validator: (value) {
        if (value == null) {
          return widget.errorMessage;
        }
        return null;
      },
      builder: (FormFieldState<TimeOfDay> state) {
        // Wrapping it in an InkWell makes the entire outline box clickable
        return InkWell(
          onTap: () async {
            final result = await showTimePicker(
              context: context,
              initialTime: _selectedTime ?? TimeOfDay.now(),
            );

            if (result != null) {
              setState(() {
                _selectedTime = result;
              });
              // Sync the FormField's state
              state.didChange(result);
              // Pass the value back to the parent form
              widget.onChanged(result);
            }
          },
          child: InputDecorator(
            // isEmpty tells the label when to float to the top of the box
            isEmpty: _selectedTime == null,
            decoration: InputDecoration(
              labelText: widget.label,
              errorText:
                  state
                      .errorText, // Automatically turns the box red if invalid!
              border: const OutlineInputBorder(),
              // Padding matches standard TextFields
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedTime?.format(context) ?? '',
                  style: TextStyle(
                    // Make it look like hint text if nothing is selected
                    color:
                        _selectedTime == null
                            ? Theme.of(context).hintColor
                            : Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 16,
                  ),
                ),
                const Icon(Icons.access_time),
              ],
            ),
          ),
        );
      },
    );
  }
}
