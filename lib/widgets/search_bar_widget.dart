import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SearchBarWidget extends StatelessWidget {
  final String searchIcon = "assets/icons/search_icon.svg";
  final String hintText;
  final Function(String) onChanged;

  SearchBarWidget({required this.hintText, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search),
          
          hintText: hintText,
          border: InputBorder.none,
          isDense: true,
          hintStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7C7C7C),
          ),
        ),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF7C7C7C),
        ),
      ),
    );
  }
}
