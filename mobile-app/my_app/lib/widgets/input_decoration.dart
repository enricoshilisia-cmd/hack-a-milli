import 'package:flutter/material.dart';

InputDecoration buildInputDecoration(BuildContext context, String labelText, Icon prefixIcon, {bool isRequired = false}) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  return InputDecoration(
    labelText: isRequired ? '$labelText (Required)' : labelText,
    labelStyle: TextStyle(
      fontSize: 14,
      color: isDarkMode ? Colors.white70 : Colors.grey.shade900,
    ),
    border: OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
    ),
    filled: true,
    fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
    prefixIcon: Icon(
      prefixIcon.icon,
      color: isDarkMode ? Colors.white70 : Colors.grey.shade900,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
}