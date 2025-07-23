import 'package:flutter/material.dart';
import 'business_documents_page.dart';

class BusinessContactInformationPage extends StatefulWidget {
  const BusinessContactInformationPage({super.key});

  @override
  State<BusinessContactInformationPage> createState() => _BusinessContactInformationPageState();
}

class _BusinessContactInformationPageState extends State<BusinessContactInformationPage> {
  final _formKey = GlobalKey<FormState>();
  final _businessAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _zipController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _corporateUrlController = TextEditingController();

  // Track whether the form has been submitted
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
    
    if (_businessAddressController.text.trim().isEmpty) {
      emptyFields.add('Business Address');
    }
    if (_countryController.text.trim().isEmpty) {
      emptyFields.add('Country');
    }
    if (_zipController.text.trim().isEmpty) {
      emptyFields.add('Zip/Postcode');
    }
    if (_contactNumberController.text.trim().isEmpty) {
      emptyFields.add('Contact Number');
    }
    
    return emptyFields;
  }

  @override
  void dispose() {
    _businessAddressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _zipController.dispose();
    _contactNumberController.dispose();
    _corporateUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Information'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _businessAddressController,
                decoration: InputDecoration(
                  labelText: 'Business Address*',
                  border: const OutlineInputBorder(),
                  errorStyle: const TextStyle(color: Colors.red),
                  helperText: 'Required',
                  suffixIcon: _submitted && _businessAddressController.text.isEmpty
                      ? const Icon(Icons.error, color: Colors.red)
                      : null,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your business address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Country*',
                  border: const OutlineInputBorder(),
                  errorStyle: const TextStyle(color: Colors.red),
                  helperText: 'Required',
                  suffixIcon: _submitted && _countryController.text.isEmpty
                      ? const Icon(Icons.error, color: Colors.red)
                      : null,
                ),
                items: ['Singapore', 'Malaysia', 'Indonesia', 'Thailand', 'Vietnam', 'Philippines']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _countryController.text = newValue ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a country';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _zipController,
                decoration: InputDecoration(
                  labelText: 'Zip/Postcode*',
                  border: const OutlineInputBorder(),
                  errorStyle: const TextStyle(color: Colors.red),
                  helperText: 'Required',
                  suffixIcon: _submitted && _zipController.text.isEmpty
                      ? const Icon(Icons.error, color: Colors.red)
                      : null,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your zip/postcode';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactNumberController,
                decoration: InputDecoration(
                  labelText: 'Contact Number*',
                  border: const OutlineInputBorder(),
                  errorStyle: const TextStyle(color: Colors.red),
                  helperText: 'Required',
                  suffixIcon: _submitted && _contactNumberController.text.isEmpty
                      ? const Icon(Icons.error, color: Colors.red)
                      : null,
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your contact number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _corporateUrlController,
                decoration: const InputDecoration(
                  labelText: 'Corporate URL:',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Previous',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    onPressed: () {
                      setState(() {
                        _submitted = true;
                      });

                      if (_formKey.currentState!.validate()) {
                        // All fields are valid
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const BusinessDocumentsPage()),
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
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
