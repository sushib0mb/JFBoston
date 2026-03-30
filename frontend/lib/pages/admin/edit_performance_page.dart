import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../data/timetable_data.dart';
import 'components/image_dropdown.dart';
import 'components/string_dropdown.dart';
import 'components/time_picker.dart';
import '../../config/supabase_config.dart';

class EditPerformancePage extends StatefulWidget {
  final EventItem? existingData;
  const EditPerformancePage({super.key, this.existingData});

  @override
  EditPerformancePageState createState() => EditPerformancePageState();
}

class EditPerformancePageState extends State<EditPerformancePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers to capture text input
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _durationController;
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

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.existingData?.performanceName ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.existingData?.description ?? '',
    );
    _durationController = TextEditingController(
      text: widget.existingData?.duration.toString() ?? '',
    );
    _selectedStartTime = parseTimeOfDay(widget.existingData?.time);
    _selectedDay = widget.existingData?.day;
    _selectedStage = widget.existingData?.stage;
    _selectedPerformanceIcon = widget.existingData?.iconImage;
    _selectedPerformanceImage = widget.existingData?.eventImage;
  }

  TimeOfDay? parseTimeOfDay(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;

    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final int hour = int.parse(parts[0]);
        final int minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      // Handle parsing errors if the string is malformed
      debugPrint("Error parsing time: $e");
    }
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _submitPerformance() async {
    if (!_formKey.currentState!.validate()) return;

    final isEditing = widget.existingData != null;
    final baseUrl = dotenv.env['API_URL_CHROME']!;

    final url =
        isEditing
            ? Uri.parse(
              '$baseUrl/api/schedule/update/${widget.existingData?.id}',
            )
            : Uri.parse('$baseUrl/api/schedule/add');

    final session = supabase.auth.currentSession;
    final jwt = session?.accessToken;

    try {
      final Map<String, dynamic> requestBody = {
        'Name': _nameController.text,
        'StartTime':
            "${_selectedStartTime?.hour}:${_selectedStartTime?.minute.toString().padLeft(2, "0")}",
        'StageName': _selectedStage,
        'Duration': _durationController.text,
        'Description': _descriptionController.text,
        'EventImage': _selectedPerformanceImage,
        "IconImage": _selectedPerformanceIcon,
        "Day": _selectedDay,
      };

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      };

      http.Response response;

      if (isEditing) {
        response = await http.put(
          url,
          headers: headers,
          body: jsonEncode(requestBody),
        );
      } else {
        // Using POST for new additions
        response = await http.post(
          url,
          headers: headers,
          body: jsonEncode(requestBody),
        );
      }

      // 3. Handle the response
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Performance updated successfully!'
                  : 'Performance added successfully!',
            ),
          ),
        );
      } else {
        print("Error: ${response.statusCode} - ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${response.statusCode} - ${response.body}"),
          ),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Network error occurred")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingData != null;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),

      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.9,
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
                      const SizedBox(height: 7.5),

                      Text(
                        isEditing ? "Edit Performance" : "Add New Performance",
                        style: TextStyle(fontSize: 30),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 15),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Performance Name',
                        ),
                        validator: (v) => v!.isEmpty ? 'Enter a name' : null,
                      ),

                      const SizedBox(height: 15),

                      TimePicker(
                        initialTime: _selectedStartTime,
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
                        initialSelection: _selectedDay.toString(),
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
                        options: [
                          "Main Stage 1",
                          "Downtown Stage 1",
                          "Downtown Stage 2",
                        ],
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
                        initialValue: _selectedPerformanceIcon,
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
                        initialValue: _selectedPerformanceImage,
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
                        child: Text(
                          isEditing ? 'Edit Schedule' : 'Add to Schedule',
                        ),
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
