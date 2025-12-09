// input_formatters.dart
import 'package:flutter/services.dart';

class NoLeadingOrMultipleSpacesFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If the user is trying to enter a space at the beginning, prevent it
    if (newValue.text.startsWith(' ')) {
      return oldValue;
    }

    // If the user is trying to enter multiple consecutive spaces, prevent it
    if (newValue.text.contains('  ')) {
      return oldValue;
    }

    // Otherwise, allow the change
    return newValue;
  }
}