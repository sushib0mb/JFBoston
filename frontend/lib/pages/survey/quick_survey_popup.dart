import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/supabase_config.dart';

class QuickSurveyPopup extends StatefulWidget {
  const QuickSurveyPopup({super.key});

  static const _kShownKey = 'quickSurveyShown';

  static Future<void> show(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kShownKey) ?? false) return;

    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const QuickSurveyPopup(),
    );
  }

  @override
  State<QuickSurveyPopup> createState() => _QuickSurveyPopupState();
}

class _QuickSurveyPopupState extends State<QuickSurveyPopup> {
  String? age;
  String? gender;
  String? amount;
  bool _submitting = false;

  final List<String> ageOptions = ['Under 18', '18-24', '25-34', '35-44', '45-54', '55+'];
  final List<String> genderOptions = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];
  final List<String> amountOptions = ['1st time', '2-3 times', '4-5 times', '6+ times'];

  bool get _canSubmit => age != null && gender != null && amount != null;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    try {
      await supabase.from('answers').insert({
        'age': age,
        'gender': gender,
        'amount': amount,
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(QuickSurveyPopup._kShownKey, true);
    } catch (e) {
      debugPrint('Quick survey error: $e');
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Widget _question(String label, List<String> options, String? selected, void Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSelected = selected == opt;
            return GestureDetector(
              onTap: () => onChanged(opt),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0B3775) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0B3775) : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Survey',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Help us improve JFBoston!',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            _question('What is your age?', ageOptions, age, (v) => setState(() => age = v)),
            const SizedBox(height: 16),
            _question('What is your gender?', genderOptions, gender, (v) => setState(() => gender = v)),
            const SizedBox(height: 16),
            _question('How many times have you attended JFB?', amountOptions, amount, (v) => setState(() => amount = v)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit && !_submitting ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B3775),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
