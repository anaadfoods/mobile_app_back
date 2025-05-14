import 'package:flutter/material.dart';

class InquiryFormScreen extends StatefulWidget {
  @override
  _InquiryFormScreenState createState() => _InquiryFormScreenState();
}

class _InquiryFormScreenState extends State<InquiryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Inquiry Form"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(nameController, "Name", "John", false, (value) {
                if (value == null || value.isEmpty) {
                  return "Name is required";
                }
                if (!RegExp(r"^[a-zA-Z ]+\$").hasMatch(value)) {
                  return "Name should contain only alphabets";
                }
                return null;
              }),
              SizedBox(height: 20),
              _buildTextField(
                phoneController,
                "Phone Number*",
                "Enter your phone number",
                false,
                (value) {
                  if (value == null || value.isEmpty) {
                    return "Phone number is required";
                  }
                  if (!RegExp(r"^\d{10}\$").hasMatch(value)) {
                    return "Enter a valid 10-digit phone number";
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _buildTextField(
                emailController,
                "Email Address*",
                "example@email.com",
                false,
                (value) {
                  if (value == null || value.isEmpty) {
                    return "Email address is required";
                  }
                  if (!RegExp(
                    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\$",
                  ).hasMatch(value)) {
                    return "Enter a valid email address";
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _buildTextField(
                locationController,
                "State & Country*",
                "Short answer",
                false,
                (value) {
                  if (value == null || value.isEmpty) {
                    return "State & Country is required";
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _buildTextField(
                messageController,
                "Your Message*",
                "Enter your message here...",
                true,
                (value) {
                  if (value == null || value.isEmpty) {
                    return "Message is required";
                  }
                  return null;
                },
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Inquiry Submitted Successfully!"),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8BC34A),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  "Submit your inquiry",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String placeholder,
    bool multiline,
    FormFieldValidator<String> validator,
  ) {
    return TextFormField(
      controller: controller,
      maxLines: multiline ? 4 : 1,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: placeholder,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF8BC34A), width: 2),
        ),
      ),
    );
  }
}
