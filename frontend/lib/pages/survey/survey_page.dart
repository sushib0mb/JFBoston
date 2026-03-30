// lib/pages/survey/survey_page.dart

import 'package:flutter/material.dart';
import '../../config/supabase_config.dart';

class SurveyPage extends StatefulWidget {
  static const routeName = '/survey';
  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  // final _formKey = GlobalKey<FormState>();

  String? gender;
  String? from;
  String? heardFrom;
  String? lookingForward;
  String? age;
  String? downtownStage; // Added downtown stage variable
  String? cameWith;
  String? participated;

  // New sustainability questions with updated variable names
  final List<String> sustainabilityEfforts = [];
  String? trashSeparate;
  String? trashSeparateWhy;
  String? trashStation;

  // controllers for any-Other fields
  final genderOther = TextEditingController();
  final fromOther = TextEditingController();
  final heardOther = TextEditingController();
  final lookingOther = TextEditingController();
  final cameWithOther = TextEditingController();
  final effortsOther = TextEditingController();
  final reasonOther = TextEditingController();

  // ← free-form feedback controller
  final feedbackController = TextEditingController();

  Future<void> _submit() async {
    // no need to validate a FormField — we gate via buttonEnabled
    final response = {
      'gender': gender == 'Other' ? genderOther.text : gender,
      'from': from == 'Other' ? fromOther.text : from,
      'heard': heardFrom == 'Other' ? heardOther.text : heardFrom,
      'looking': lookingForward == 'Other' ? lookingOther.text : lookingForward,
      'age': age,
      'downtownStage': downtownStage, // Added downtown stage to response
      'cameWith': cameWith == 'Other' ? cameWithOther.text : cameWith,
      'participated': participated,

      // New sustainability responses with updated names
      'sustainabilityEfforts':
          sustainabilityEfforts.contains('Other')
              ? [
                ...sustainabilityEfforts.where((e) => e != 'Other'),
                effortsOther.text,
              ]
              : sustainabilityEfforts,
      'trashSeparate': trashSeparate,
      'trashSeparateWhy':
          trashSeparateWhy == 'Other' ? reasonOther.text : trashSeparateWhy,
      'trashStation': trashStation,

      'feedback': feedbackController.text, // ← optional
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      await supabase.from('survey').insert(response);
    } catch (e) {
      debugPrint('Supabase insert failed: $e');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for your feedback!')),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Widget _buildRadioGroup(
    String title,
    List<String> options,
    String? groupVal,
    void Function(String?) onChanged, [
    TextEditingController? otherCtrl,
    bool isRequired = true,
  ]) {
    // append a red asterisk on required titles
    final label = RichText(
      text: TextSpan(
        text: title,
        style: const TextStyle(fontSize: 16, color: Colors.black),
        children:
            isRequired
                ? const [
                  TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                ]
                : null,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label,
        ...options.map((opt) {
          return RadioListTile<String>(
            title: Text(opt),
            value: opt,
            groupValue: groupVal,
            onChanged: onChanged,
            // Position the radio button on the left side
            controlAffinity: ListTileControlAffinity.leading,
          );
        }),
        if (options.contains('Other') && groupVal == 'Other')
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: TextFormField(
              controller: otherCtrl,
              decoration: const InputDecoration(labelText: 'Other:'),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCheckboxGroup(
    String title,
    List<String> options,
    List<String> selectedValues,
    void Function(bool?, String) onChanged, [
    TextEditingController? otherCtrl,
    bool isRequired = true,
  ]) {
    final label = RichText(
      text: TextSpan(
        text: title,
        style: const TextStyle(fontSize: 16, color: Colors.black),
        children:
            isRequired
                ? const [
                  TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                ]
                : null,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label,
        ...options.map((opt) {
          return CheckboxListTile(
            title: Text(opt),
            value: selectedValues.contains(opt),
            onChanged: (bool? value) => onChanged(value, opt),
            // Position the checkbox on the left side
            controlAffinity: ListTileControlAffinity.leading,
          );
        }),
        if (options.contains('Other') && selectedValues.contains('Other'))
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: TextFormField(
              controller: otherCtrl,
              decoration: const InputDecoration(labelText: 'Other:'),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  void dispose() {
    genderOther.dispose();
    fromOther.dispose();
    heardOther.dispose();
    lookingOther.dispose();
    cameWithOther.dispose();
    effortsOther.dispose();
    reasonOther.dispose();
    feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // only enable submit when every required field is non-null
    final isFormValid =
        <String?>[
          gender,
          from,
          heardFrom,
          lookingForward,
          age,
          downtownStage,
          cameWith,
          participated,
          trashSeparate,
          trashStation,
        ].every((v) => v != null) &&
        (trashSeparate != 'No' || trashSeparateWhy != null);

    return Scaffold(
      appBar: AppBar(title: const Text('Festival Survey')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildRadioGroup(
              "What is your gender?",
              ["Male", "Female", "Prefer not to say", "Other"],
              gender,
              (val) => setState(() => gender = val),
              genderOther,
            ),

            _buildRadioGroup(
              "Where are you coming from?",
              ["Massachusetts", "Rhode Island", "New Hampshire", "Other"],
              from,
              (val) => setState(() => from = val),
              fromOther,
            ),

            _buildRadioGroup(
              "How did you hear about us?",
              ["Twitter", "Facebook", "Official Website", "Friend", "Other"],
              heardFrom,
              (val) => setState(() => heardFrom = val),
              heardOther,
            ),

            _buildRadioGroup(
              "What were you looking forward to most?",
              ["Stage", "Food", "Culture", "Activities", "Booth", "Other"],
              lookingForward,
              (val) => setState(() => lookingForward = val),
              lookingOther,
            ),

            _buildRadioGroup(
              "Age?",
              ["11-19", "20-29", "30-39", "40-49", "50-59", "60-69", "70-"],
              age,
              (val) => setState(() => age = val),
            ),

            _buildRadioGroup(
              "Did you visit the downtown stage?",
              [
                "Yes",
                "No, I wasn't interested",
                "No, but wanted to go",
                "I did not know about it",
              ],
              downtownStage,
              (val) => setState(() => downtownStage = val),
            ),

            _buildRadioGroup(
              "Did you come with",
              ["Family", "Friends", "On your own", "Other"],
              cameWith,
              (val) => setState(() => cameWith = val),
              cameWithOther,
            ),

            _buildRadioGroup(
              "Did you participate in the past?",
              ["First time!", "2nd or 3rd time", "4th time or more"],
              participated,
              (val) => setState(() => participated = val),
            ),

            // New sustainability questions with updated variable names
            _buildCheckboxGroup(
              "What sustainability efforts did you notice?",
              [
                "Sustainability booth (workshops and awareness events)",
                "Recycling Efforts",
                "SDGs Stamp Rally",
                "Sponsor/partner collaboration",
                "Fundraising to sell sustainability items",
                "RecycleMeter (real-time waste tracking display)",
                "None",
                "Other",
              ],
              sustainabilityEfforts,
              (checked, option) {
                setState(() {
                  if (checked == true) {
                    if (option == "None") {
                      sustainabilityEfforts.clear();
                      sustainabilityEfforts.add("None");
                    } else {
                      sustainabilityEfforts.remove("None");
                      sustainabilityEfforts.add(option);
                    }
                  } else {
                    sustainabilityEfforts.remove(option);
                  }
                });
              },
              effortsOther,
              false, // Making this optional to handle "None" response
            ),

            _buildRadioGroup(
              "Did you separate your trash correctly at our trash station?",
              ["Definitely", "Not sure", "No"],
              trashSeparate,
              (val) => setState(() => trashSeparate = val),
            ),

            if (trashSeparate == "No")
              _buildRadioGroup(
                "If not, what was the reason?",
                [
                  "I didn't know it was possible",
                  "I couldn't find a trash station",
                  "I didn't have time",
                  "I didn't think it mattered",
                  "Other",
                ],
                trashSeparateWhy,
                (val) => setState(() => trashSeparateWhy = val),
                reasonOther,
              ),

            _buildRadioGroup(
              "Were the trash stations easy to find?",
              ["Yes", "No"],
              trashStation,
              (val) => setState(() => trashStation = val),
            ),

            // ← feedback is **optional**, so no asterisk
            const Text(
              "Please give any feedback regarding the event or the app:",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Your comments...',
              ),
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isFormValid ? _submit : null,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
