import 'package:flutter/material.dart';
import 'home_page.dart';

class FitnessPreferencesPage extends StatefulWidget {
  const FitnessPreferencesPage({super.key});

  @override
  State<FitnessPreferencesPage> createState() => _FitnessPreferencesPageState();
}

class _FitnessPreferencesPageState extends State<FitnessPreferencesPage> {
  final Set<String> _selectedGoals = {};
  String? _selectedLevel;
  final Set<String> _selectedActivities = {};
  String? _otherActivity;
  String? _selectedFrequency;
  String? _selectedDuration;
  final Set<String> _selectedPreferences = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Goals and Preferences'),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Fitness Goals'),
            _buildCheckboxGroup([
              'Weight loss',
              'Muscle gain',
              'Endurance',
              'Health'
            ], _selectedGoals),
            const SizedBox(height: 24),

            _buildSectionTitle('Fitness Level'),
            _buildRadioGroup([
              'Beginner',
              'Intermediate',
              'Advance'
            ], _selectedLevel, (value) {
              setState(() {
                _selectedLevel = value;
              });
            }),
            const SizedBox(height: 24),

            _buildSectionTitle('Preferred Activities'),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildCheckboxGroup([
                    'Running',
                    'Swimming',
                    'Sports',
                    'Weight Lifting',
                    'Yoga',
                    'Others'
                  ], _selectedActivities),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            if (_selectedActivities.contains('Others'))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('If others, please specify'),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: _buildInputDecoration(),
                    onChanged: (value) {
                      setState(() {
                        _otherActivity = value;
                      });
                    },
                  ),
                ],
              ),
            const SizedBox(height: 24),

            _buildSectionTitle('Workout Frequency'),
            _buildRadioGroup([
              '1 to 3 times a week',
              '2 to 4 times a week',
              '3 to 5 times a week',
              'More than 5 times'
            ], _selectedFrequency, (value) {
              setState(() {
                _selectedFrequency = value;
              });
            }),
            const SizedBox(height: 24),

            _buildSectionTitle('Workout Duration'),
            _buildRadioGroup([
              '30min',
              '60min',
              '90min',
              'More than 120 min'
            ], _selectedDuration, (value) {
              setState(() {
                _selectedDuration = value;
              });
            }),
            const SizedBox(height: 24),

            _buildSectionTitle('Workout Preference'),
            _buildCheckboxGroup([
              'indoor',
              'outdoor',
              'home',
              'gym'
            ], _selectedPreferences),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Previous',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  onPressed: () {
                    // Basic validation
                    if (_selectedLevel == null ||
                        _selectedFrequency == null ||
                        _selectedDuration == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all required fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    // Navigate to HomePage
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const HomePage(),
                      ),
                      (route) => false, // This will remove all previous routes
                    );
                  },
                  child: const Text(
                    'Submit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '* mandatory field',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCheckboxGroup(List<String> items, Set<String> selectedItems) {
    return Column(
      children: items.map((item) => CheckboxListTile(
        title: Text(item),
        value: selectedItems.contains(item),
        onChanged: (bool? value) {
          setState(() {
            if (value == true) {
              selectedItems.add(item);
            } else {
              selectedItems.remove(item);
            }
          });
        },
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
        contentPadding: EdgeInsets.zero,
      )).toList(),
    );
  }

  Widget _buildRadioGroup(List<String> items, String? selectedItem, Function(String?) onChanged) {
    return Column(
      children: items.map((item) => RadioListTile<String>(
        title: Text(item),
        value: item,
        groupValue: selectedItem,
        onChanged: onChanged,
        dense: true,
        contentPadding: EdgeInsets.zero,
      )).toList(),
    );
  }

  InputDecoration _buildInputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
