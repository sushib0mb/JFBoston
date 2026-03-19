import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:jfbfestival/pages/admin/components/image_dropdown.dart';
// import 'package:jfbfestival/pages/admin/components/string_dropdown.dart';
// import 'package:jfbfestival/pages/admin/components/time_picker.dart';
import '../../config/supabase_config.dart';

// import 'package:jfbfestival/pages/admin/components/performance_table.dart';

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
        title: const Text('Admin Page'),
        backgroundColor: Colors.indigo,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.9,
            heightFactor: 0.8,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Main Column ---
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeaderPill('Main Stage'),
                        const SizedBox(height: 16),
                        _buildPerformanceBox(
                          title: 'The Strokes',
                          time: '7:00 PM',
                          onTap: () {
                            // Navigate to details page here
                          },
                        ),
                        _buildPerformanceBox(
                          title: 'Tame Impala',
                          time: '9:00 PM',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16), // Spacing between columns
                  // --- Downtown Column ---
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeaderPill('Downtown'),
                        const SizedBox(height: 16),
                        _buildPerformanceBox(
                          title: 'Arctic Monkeys',
                          time: '7:30 PM',
                          onTap: () {},
                        ),
                        _buildPerformanceBox(
                          title: 'Gorillaz',
                          time: '9:30 PM',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800], // Dark pill background for contrast
        borderRadius: BorderRadius.circular(9999), // Perfect pill shape
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  // Helper method to create the Clickable Performance Boxes
  Widget _buildPerformanceBox({
    required String title,
    required String time,
    required VoidCallback onTap,
  }) {
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
                  // Text Content wrapped in Expanded to prevent overflow on small screens
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
                          time,
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
