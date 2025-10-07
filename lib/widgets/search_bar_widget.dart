import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:grocery_app/styles/colors.dart';

class SearchBarWidget extends StatelessWidget {
  final String searchIcon = "assets/icons/search_icon.svg";
  final String hintText;
  final Function(String) onChanged;

  const SearchBarWidget({super.key, required this.hintText, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,

      decoration: BoxDecoration(borderRadius: BorderRadius.circular(40)),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            
          ),
          prefixIcon: Icon(Icons.search),
          fillColor: Colors.white,

          
          hintText: hintText,
         
          isDense: true,
          hintStyle: TextStyle(
            fontSize: 12,
            color:AppColors.textPrimary,
          ),
        ),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF7C7C7C),
        ),
      ),
    );
  }
}
