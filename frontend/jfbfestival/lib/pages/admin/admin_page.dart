import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jfbfestival/pages/admin/components/image_dropdown.dart';
import 'package:jfbfestival/pages/admin/components/string_dropdown.dart';
import 'package:jfbfestival/pages/admin/components/time_picker.dart';
import '../../config/supabase_config.dart';

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
  final TextEditingController _durationController = TextEditingController();
  final List<DropdownMenuEntry<String>> dayPicker = [
    DropdownMenuEntry(value: "", label: ""),
    DropdownMenuEntry(value: "1", label: "1"),
    DropdownMenuEntry(value: "2", label: "2"),
  ];
  String? _selectedStage;
  int? _selectedDay;
  String? _selectedPerformanceIcon;
  String? _selectedPerformanceImage;
  TimeOfDay? _selectedStartTime;

  // Function to call your C# MapPost endpoint
  Future<void> _submitPerformance() async {
    if (!_formKey.currentState!.validate()) return;

    final url = Uri.parse('${dotenv.env['API_URL_CHROME']!}/api/schedule/add');

    final session = supabase.auth.currentSession;
    final jwt = session?.accessToken;

    print(
      "${_selectedStartTime?.hour}:${_selectedStartTime?.minute.toString().padLeft(2, "0")}",
    );
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
              "${_selectedStartTime?.hour}:${_selectedStartTime?.minute.toString().padLeft(2, "0")}",
          'StageName': _selectedStage,
          'Duration': _durationController.text,
          'Description': _descriptionController.text,
          'EventImage': _selectedPerformanceImage,
          "IconImage": _selectedPerformanceIcon,
          "Day": _selectedDay,
        }),
      );

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

                      TimePicker(
                        label: "Start Time",
                        errorMessage: "Please select a start time!",
                        onChanged: (TimeOfDay newTime) {
                          setState(() {
                            _selectedStartTime = newTime;
                          });
                        },
                      ),

                      const SizedBox(height: 20),

                      StringDropdown(
                        label: 'Day',
                        options: ["1", "2"],
                        errorMessage:
                            'Please select a day for this performance',
                        onSelected: (String? newValue) {
                          setState(() {
                            if (newValue != null) {
                              _selectedDay = int.tryParse(newValue);
                            }
                          });
                        },
                      ),

                      const SizedBox(height: 20),

                      StringDropdown(
                        label: 'Stage',
                        options: ["Main Stage", "Downtown Stage"],
                        initialSelection: _selectedStage,
                        errorMessage:
                            'Please select a stage for this performance', // The text that shows in red
                        onSelected: (String? newValue) {
                          setState(() {
                            _selectedStage = newValue;
                          });
                        },
                      ),

                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(
                          labelText: 'Duration (minutes)',
                        ),
                        // 1. This automatically opens the number pad on mobile devices!
                        keyboardType: TextInputType.number,

                        validator: (v) {
                          // 2. Safely check if it's empty
                          if (v == null || v.isEmpty) {
                            return 'Enter a duration';
                          }

                          // 3. Try to parse it into an integer
                          if (int.tryParse(v) == null) {
                            return 'Please enter a valid duration';
                          }

                          // 4. If it passes both checks, it's valid!
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Performance Description',
                        ),
                      ),

                      const SizedBox(height: 25),

                      ImageDropdown(
                        label: "Peformance Icon: ",
                        folderPath: "performanceIcons",
                        errorMessage: "Please select a performance icon!",
                        onChanged: (String? newUrl) {
                          setState(() {
                            _selectedPerformanceIcon = newUrl;
                          });
                        },
                      ),

                      const SizedBox(height: 25),

                      ImageDropdown(
                        label: "Peformance Images: ",
                        folderPath: "performanceImages",
                        errorMessage: "Please select a performance image!",
                        onChanged: (String? newUrl) {
                          setState(() {
                            _selectedPerformanceImage = newUrl;
                          });
                        },
                      ),

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
