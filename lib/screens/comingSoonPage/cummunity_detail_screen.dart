import 'package:flutter/material.dart';
import 'package:grocery_app/styles/colors.dart';
import '../../models/cummunity_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CommunityDetailScreen extends StatelessWidget {
  final Community community;
  const CommunityDetailScreen({required this.community});

  // Email validation regex pattern
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
  );

  // Phone validation regex pattern (supports Indian phone numbers)
  static final RegExp _phoneRegex = RegExp(
    r'^[6-9]\d{9}$', // Indian mobile numbers starting with 6-9 and having 10 digits
  );

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!_emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    // Remove any spaces or special characters
    String cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');
    if (!_phoneRegex.hasMatch(cleanPhone)) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  Future<void> _showNotificationForm(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String email = '';
    String phone = '';
    String message = '';

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Stay Updated'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      if (value.length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                    onSaved: (value) => name = value!,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                      hintText: 'example@email.com',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    validator: _validateEmail,
                    onSaved: (value) => email = value!,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                      hintText: '9876543210',
                    ),
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    validator: _validatePhone,
                    onSaved: (value) => phone = value!,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.message),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your message';
                      }
                      if (value.length < 10) {
                        return 'Message must be at least 10 characters';
                      }
                      return null;
                    },
                    onSaved: (value) => message = value!,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();

                  try {
                    final response = await http.post(
                      Uri.parse(
                        'http://13.203.212.133:8000/api/core/communities/${community.name}/subscribe/',
                      ),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'name': name,
                        'email': email,
                        'phone': phone,
                        'message': message,
                      }),
                    );

                    if (response.statusCode == 200 ||
                        response.statusCode == 201) {
                      Navigator.pop(context); // Close the form
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Thank you! We\'ll keep you updated.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      throw Exception('Failed to submit form');
                    }
                  } catch (e) {
                    Navigator.pop(context); // Close the form
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to submit. Please try again later.',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text('Submit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(community.name)),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Image.network(
                          community.image,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      community.name,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColorDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      community.description,
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Benefits:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._buildBenefitsList(community.benefits),
                    if (community.comingSoon)
                      Padding(
                        padding: const EdgeInsets.only(top: 24.0),
                        child: Center(
                          child: InkWell(
                            onTap: () => _showNotificationForm(context),
                            child: Chip(
                              label: Text(
                                'Notify',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: AppColors.primaryColor,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBenefitsList(String benefits) {
    // Try to split by line or comma for bullet points
    final items =
        benefits
            .split(RegExp(r'\n|,|•'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
    if (items.length <= 1) {
      return [
        Text(benefits, style: TextStyle(fontSize: 15, color: Colors.black87)),
      ];
    }
    return items
        .map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(fontSize: 16, color: Colors.green)),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }
}
