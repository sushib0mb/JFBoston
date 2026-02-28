import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jfbfestival/pages/timetable/components/image_dropdown.dart';
import '../config/supabase_config.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  AdminPageState createState() => AdminPageState();
}

class AdminPageState extends State<AdminPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers to capture text input
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _stageController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final List<DropdownMenuEntry<String>> dayPicker = [
    DropdownMenuEntry(value: "", label: ""),
    DropdownMenuEntry(value: "1", label: "1"),
    DropdownMenuEntry(value: "2", label: "2"),
  ];
  TimeOfDay? picked = null;
  var selectedValue = "";

  // TODO: Fetch performance intially to load when updating performance
  Future<void> _fetchPerformance() async {}

  // Function to call your C# MapPost endpoint
  Future<void> _submitPerformance() async {
    if (!_formKey.currentState!.validate()) return;

    final url = Uri.parse('${dotenv.env['API_URL_CHROME']!}/api/schedule/add');

    final session = supabase.auth.currentSession;
    final jwt = session?.accessToken;

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },

        body: jsonEncode({
          'Name': _nameController.text,
          'StartTime':
              "${picked?.hour}:${picked?.minute.toString().padLeft(2, "0")}",
          'StageName': _stageController.text,
          'Duration': _durationController.text,
          'Description': _descriptionController.text,
          'EventImage': "te",
          "IconImage": "te",
          "Day": selectedValue,
        }),
      );

      print(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Performance added successfully!')),
        );
      } else {
        // DEBUG

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Performance'),
        backgroundColor: Colors.indigo,
      ),
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.9,
            heightFactor: 0.8,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  // Prevents overflow on small screens
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Performance Name',
                        ),
                        validator: (v) => v!.isEmpty ? 'Enter a name' : null,
                      ),
                      const SizedBox(height: 15),
                      FormField<TimeOfDay>(
                        initialValue: picked,
                        validator: (value) {
                          // Custom validation logic
                          if (value == null) {
                            return 'Please select a start time';
                          }
                          return null;
                        },
                        builder: (FormFieldState<TimeOfDay> state) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                // Use the class-level variable directly
                                title: Text(
                                  "Start Time: ${picked?.format(context) ?? 'Not set'}",
                                ),
                                trailing: const Icon(Icons.access_time),
                                onTap: () async {
                                  final result = await showTimePicker(
                                    context: context,
                                    initialTime: picked ?? TimeOfDay.now(),
                                  );

                                  if (result != null) {
                                    setState(() {
                                      // Update the single source of truth
                                      picked = result;
                                    });
                                    // Sync the FormField's state
                                    state.didChange(result);
                                  }
                                },
                              ),
                              if (state.hasError)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Text(
                                    state.errorText!,
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      TextFormField(
                        controller: _stageController,
                        decoration: const InputDecoration(
                          labelText: 'Stage Name',
                        ),
                        validator: (v) => v!.isEmpty ? 'Enter a stage' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(
                          labelText: 'Duration',
                        ),
                        validator:
                            (v) => v!.isEmpty ? 'Enter a duration' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Performance Description',
                        ),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        child: Row(
                          children: [
                            Text("Day: "),
                            FormField<String>(
                              initialValue: selectedValue,
                              validator: (value) {
                                // Check if the selection is empty or invalid
                                if (selectedValue == "" ||
                                    selectedValue.isEmpty) {
                                  return 'Please select a day';
                                }
                                return null;
                              },
                              builder: (FormFieldState<String> state) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    DropdownMenu<String>(
                                      initialSelection: selectedValue,
                                      dropdownMenuEntries: dayPicker,
                                      onSelected: (value) {
                                        // Update the local state
                                        selectedValue = value!;
                                        // Tell the FormField that the value has changed
                                        state.didChange(value);
                                      },
                                    ),
                                    // Display the error text if validation fails
                                    if (state.hasError)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8,
                                          left: 12,
                                        ),
                                        child: Text(
                                          state.errorText!,
                                          style: TextStyle(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.error,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      PerformanceIconDropdown(),

                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _submitPerformance,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Add to Schedule'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
