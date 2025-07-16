import 'package:flutter/material.dart';
import 'business_contact_information_page.dart';

class BusinessProfilePage extends StatefulWidget {
  const BusinessProfilePage({super.key});

  @override
  State<BusinessProfilePage> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _entityNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Set<String> _selectedCategories = {};
  bool _submitted = false;

  void _showValidationDialog(List<String> emptyFields) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Required Fields Empty'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please fill in the following mandatory fields:'),
                const SizedBox(height: 8),
                ...emptyFields.map((field) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Text('• $field', style: const TextStyle(color: Colors.red)),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  List<String> _validateMandatoryFields() {
    List<String> emptyFields = [];
    
    if (_businessNameController.text.trim().isEmpty) {
      emptyFields.add('Business Name');
    }
    if (_entityNumberController.text.trim().isEmpty) {
      emptyFields.add('Unique Entity Number');
    }
    
    return emptyFields;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Basic Business Info.'),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Business Name*'),
              TextFormField(
                controller: _businessNameController,
                decoration: _buildInputDecoration(
                  isRequired: true,
                  showError: _submitted && _businessNameController.text.trim().isEmpty,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter business name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildLabel('Unique Entity Number*'),
              TextFormField(
                controller: _entityNumberController,
                decoration: _buildInputDecoration(
                  isRequired: true,
                  showError: _submitted && _entityNumberController.text.trim().isEmpty,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter unique entity number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildLabel('Business Category/Type'),
              Column(
                children: [
                  Row(
                    children: [
                      _buildCheckbox('gym'),
                      const SizedBox(width: 16),
                      _buildCheckbox('CrossFit'),
                    ],
                  ),
                  Row(
                    children: [
                      _buildCheckbox('dance studio'),
                      const SizedBox(width: 16),
                      _buildCheckbox('Physiotherapy'),
                    ],
                  ),
                  Row(
                    children: [
                      _buildCheckbox('martial art'),
                      const SizedBox(width: 16),
                      _buildCheckbox('others'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildLabel('Business Description'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: _buildInputDecoration(),
              ),
              const SizedBox(height: 24),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () {
                    setState(() {
                      _submitted = true;
                    });

                    if (_formKey.currentState!.validate()) {
                      // All mandatory fields are filled, navigate to next page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BusinessContactInformationPage(),
                        ),
                      );
                    } else {
                      // Show dialog with missing fields
                      final emptyFields = _validateMandatoryFields();
                      _showValidationDialog(emptyFields);
                    }
                  },
                  child: const Text(
                    'Next Page',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '* mandatory field',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCheckbox(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: _selectedCategories.contains(label),
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _selectedCategories.add(label);
              } else {
                _selectedCategories.remove(label);
              }
            });
          },
        ),
        Text(label),
      ],
    );
  }

  InputDecoration _buildInputDecoration({bool isRequired = false, bool showError = false}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      errorStyle: const TextStyle(color: Colors.red),
      helperText: isRequired ? 'Required' : null,
      suffixIcon: showError ? const Icon(Icons.error, color: Colors.red) : null,
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _entityNumberController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
