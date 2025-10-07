import 'package:flutter/material.dart';
import 'package:grocery_app/common_widgets/imput_widget.dart';
import 'package:grocery_app/services/api_config.dart';
import 'package:grocery_app/styles/colors.dart';
import '../../models/cummunity_model.dart';
import '../../helpers/snackbar_helper.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CommunityDetailScreen extends StatelessWidget {
  final Community community;
  const CommunityDetailScreen({super.key, required this.community});

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



  // Paste this updated method into your CommunityDetailScreen class

Future<void> _showNotificationForm(BuildContext context) async {
  final formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        // Added shape for rounded corners to match the form fields
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        
        // 1. Title is wrapped in a Center widget
        title: Center(
          child: Text('Stay Updated', style: TextStyle(color: Colors.white)),
        ),
        backgroundColor: AppColors.primaryColor,

        // 2. Content is wrapped in a SizedBox to control the width
        content: SizedBox(
          width: double.maxFinite, // Makes the dialog use the available width
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomInput(
                    height: 60,
                    borderRadius: BorderRadius.circular(25),
                    hintText: "Name",
                    controller: _nameController,
                    keyboardType: TextInputType.name, // Changed to name
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  CustomInput(
                    height: 60,
                    borderRadius: BorderRadius.circular(25),
                    hintText: "Email",
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail, // Using your existing validator
                  ),
                  SizedBox(height: 16),
                  CustomInput(
                    hintText: "Phone number",
                    controller: _phoneController,
                    keyboardType: TextInputType.number,
                    validator: _validatePhone, // Using your existing validator
                  ),
                  SizedBox(height: 16),
                  CustomInput(
                    hintText: "Message",
                    controller: _messageController,
                    keyboardType: TextInputType.text,
                    validator: (v) {
                      if (v!.isEmpty) return 'Enter a message';
                      return null;
                    },
                  )
                ],
              ),
            ),
          ),
        ),
        actions: [
          // 3. Button is wrapped to control its width and padding
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity, // Makes the button stretch
              child: ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    try {
                      final response = await http.post(
                        Uri.parse(
                          '${ApiConfig.baseUrl}/api/core/communities/${community.name}/subscribe/',
                        ),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({
                          'name': _nameController.text,
                          'email': _emailController.text,
                          'phone': _phoneController.text,
                          'message': _messageController.text,
                        }),
                      );
                      if (response.statusCode == 200 ||
                          response.statusCode == 201) {
                        Navigator.pop(context); // Close the form
                        SnackBarHelper.showSuccess(
                          context,
                          'Thank you! We\'ll keep you updated.',
                        );
                      } else {
                        throw Exception('Failed to submit form');
                      }
                    } catch (e) {
                      Navigator.pop(context); // Close the form
                      SnackBarHelper.showError(
                          context, 'Failed to submit. Please try again later.');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.bottonBackgroundColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)
                  )
                ),
                child: Text('Submit'),
              ),
            ),
          ),
        ],
        // Reduces default padding around the actions
        actionsPadding: EdgeInsets.zero,
      );
    },
  );
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( centerTitle: false,title: Text(community.name)),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
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
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    community.description,
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Benefits:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color:Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._buildBenefitsList(community.benefits),
                  if (community.comingSoon)
                      GestureDetector(
                        onTap: () => _showNotificationForm(context),
                        child: Center(
                          child: Container(
                            margin: EdgeInsets.only(top: 10),
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.bottonBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: Text("Notify" , style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),),
                          ),
                        ),
                      )


                    // Padding(

                    //   padding: const EdgeInsets.only(top: 24.0),
                    //   child: Center(
                    //     child: InkWell(
                    //       customBorder:ShapeBorder.lerp(
                    //         RoundedRectangleBorder(
                    //           borderRadius: BorderRadius.circular(30),
                    //         ),
                    //         RoundedRectangleBorder(
                    //           borderRadius: BorderRadius.circular(30),
                    //         ),
                    //         0,
                    //       ),
                    //       child: Chip(

                    //         label: Text(
                    //           'Notify',
                    //           style: TextStyle(
                    //             color: Colors.white,
                    //             fontWeight: FontWeight.bold,
                    //           ),
                    //         ),
                            
                    //         backgroundColor: AppColors.bottonBackgroundColor,
                    //         padding: EdgeInsets.symmetric(
                    //           horizontal: 16,
                    //           vertical: 8,
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                ],
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
                Text('', style: TextStyle(fontSize: 16, color: Colors.green)),
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
