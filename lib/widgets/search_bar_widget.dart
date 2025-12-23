import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final String hintText;
  final Function(String) onChanged;

  const SearchBarWidget({
    super.key,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(border: Border.all(width: 1 , color: theme.disabledColor ,) , borderRadius: BorderRadius.circular(12)),
      child: TextField(      
        onChanged: onChanged,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
        ),
      ),
    );
  }
}
