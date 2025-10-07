import 'package:flutter/material.dart';
import 'package:grocery_app/styles/colors.dart';

class CustomInput extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final BorderRadius? borderRadius;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final void Function(bool)? onValidationChanged;

  // NEW PARAMETERS
  final double? width;
  final double? height;
  final InputBorder? customBorder;
  final Color? fillColor;

  const CustomInput({
    super.key,
    required this.hintText,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.prefixIcon,
    this.borderRadius,
    this.validator,
    this.focusNode,
    this.onValidationChanged,
    this.width,
    this.height,
    this.customBorder,
    this.fillColor,
  });

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> {
  bool _isValid = false;
  String? _errorText;
  bool _obscure = true; // 👈 for password toggle

  void _validateInput(String? value) {
    if (widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(value);
        _isValid = _errorText == null && value != null && value.isNotEmpty;
      });
      widget.onValidationChanged?.call(_isValid);
    }
  }

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
    widget.controller.addListener(() {
      _validateInput(widget.controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 60,
      child: TextFormField(
        controller: widget.controller,
        obscureText: _obscure,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        focusNode: widget.focusNode,
        onChanged: _validateInput,
        style: const TextStyle(fontSize: 12, color: Colors.white),
        cursorRadius: const Radius.circular(20),
                cursorColor: Colors.white,

        decoration: InputDecoration(
          // 🟢 Fill like in image
          filled: true,
          fillColor: widget.fillColor ?? const Color(0xFF2F5D3F), // dark green
          
          // 🟢 Rounded pill border
          enabledBorder: OutlineInputBorder(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(30.0),
            borderSide: BorderSide(color: Colors.white, width: 1.2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(30.0),
            borderSide: BorderSide(color: AppColors.warning, width: 1.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(30.0),
            borderSide: BorderSide(color: AppColors.primaryColor, width: 2.0),
          ),

          // 🟢 Hint / Label
          hintText: widget.hintText ,
          hintStyle: const TextStyle(color: Colors.white70),

          // 🟢 Prefix / Suffix icons
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscure = !_obscure;
                    });
                  },
                )
              : widget.suffixIcon,
          // errorText: _errorText,
          errorMaxLines: 2,
          errorStyle: const TextStyle(color: Colors.red, fontSize: 10),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(() {
      _validateInput(widget.controller.text);
    });
    super.dispose();
  }
}
