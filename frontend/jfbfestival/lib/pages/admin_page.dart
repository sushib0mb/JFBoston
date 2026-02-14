import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  final TextEditingController _stageController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

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

        // body: jsonEncode({
        //   'performance_name': _nameController.text,
        //   'start_time': _selectedDate.toIso8601String(),
        //   'stage_name': _stageController.text,
        // }),
        body: jsonEncode({
          'Name': "new performance!",
          'StartTime': "23:00:00",
          'StageName': "de",
          'Duration': 90,
          'Description': "Hi",
          'EventImage': "te",
          "IconImage": "te",
          "Day": "2",
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Performance added successfully!')),
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
                      TextFormField(
                        controller: _stageController,
                        decoration: const InputDecoration(
                          labelText: 'Stage Name',
                        ),
                        validator: (v) => v!.isEmpty ? 'Enter a stage' : null,
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        title: Text(
                          "Start Time: ${_selectedDate.toLocal()}".split(
                            '.',
                          )[0],
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null)
                            setState(() => _selectedDate = picked);
                        },
                      ),
                      const SizedBox(height: 30),
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
