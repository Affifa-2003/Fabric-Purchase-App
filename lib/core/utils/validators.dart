import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Validators {
  // Validate mobile number (10 digits, starting with 6-9)
  static bool validateMobileNumber(String mobile) {
    // Remove any non-digit characters
    String digitsOnly = mobile.replaceAll(RegExp(r'[^\d]'), '');

    // Check if it's exactly 10 digits and starts with 6-9
    if (digitsOnly.length != 10) {
      return false;
    }

    // Check if first digit is between 6 and 9
    int firstDigit = int.parse(digitsOnly[0]);
    return firstDigit >= 6 && firstDigit <= 9;
  }

  // Validate email format
  static bool validateEmail(String email) {
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Validate GST number format
  static bool validateGSTNo(String gstNo) {
    // GST format: 2 digits + 1 letter + PAN format (10 chars) + 1 letter + 1 digit + Z
    // Example: 27AAPFU0939F1ZV
    final RegExp gstRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[0-9]{1}[A-Z]{1}$');
    return gstRegex.hasMatch(gstNo);
  }

  // Check if mobile number already exists in a list
  static bool mobileNumberExists(
    String mobile,
    List<Map<String, dynamic>> items, {
    String? excludeItemName,
    String fieldName = 'mobileNumber',
  }) {
    return items.any((item) {
      // Skip the item with the provided name (for editing)
      if (excludeItemName != null && item['name'] == excludeItemName) {
        return false;
      }
      return item[fieldName] == mobile;
    });
  }

  // Check for duplicate mobile numbers in a list
  static bool checkDuplicateMobile(int currentIndex, String mobile, List<String> mobileNumbers) {
    if (mobile.trim().isEmpty) return false;

    for (int i = 0; i < mobileNumbers.length; i++) {
      if (i != currentIndex && mobileNumbers[i] == mobile) {
        return true;
      }
    }
    return false;
  }

  // Check if email already exists
  static bool emailExists(
    String email,
    List<Map<String, dynamic>> items, {
    String? excludeItemName,
    String fieldName = 'email',
  }) {
    return items.any((item) {
      // Skip the item with the provided name (for editing)
      if (excludeItemName != null && item['name'] == excludeItemName) {
        return false;
      }
      return item[fieldName] == email;
    });
  }

  // Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  // Validate party code
  static String? validatePartyCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter party code';
    }
    return null;
  }

  // Validate party name
  static String? validatePartyName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter party name';
    }
    return null;
  }

  // Validate agent name
  static String? validateAgentName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Agent name is required';
    }
    return null;
  }

  // Validate agent code
  static String? validateAgentCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Agent code is required';
    }
    return null;
  }

  // Validate transport name
  static String? validateTransportName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Transport company name is required';
    }
    return null;
  }

  // Validate status
  static String? validateStatus(String? value) {
    if (value == null) {
      return 'Please select status';
    }
    return null;
  }

  // Validate agent type
  static String? validateAgentType(String? value) {
    if (value == null) {
      return 'Agent type is required';
    }
    return null;
  }

  // Validate grade
  static String? validateGrade(String? value) {
    if (value == null) {
      return 'Grade is required';
    }
    return null;
  }

  // Validate financial year
  static String? validateFinancialYear(String? value) {
    if (value == null) {
      return 'Financial Year is required';
    }
    return null;
  }

  // Validate start date
  static String? validateStartDate(DateTime? value) {
    if (value == null) {
      return 'Start Date is required';
    }
    return null;
  }

  // Validate seasons selection
  static String? validateSeasons(List<String> selectedSeasons) {
    if (selectedSeasons.isEmpty) {
      return 'At least one season is required';
    }
    return null;
  }
}

// Custom input formatters
class NoLeadingOrMultipleSpacesFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    // Remove leading spaces
    text = text.trimLeft();

    // Replace multiple spaces with a single space
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class FirstDigitMobileNumberFormatter extends TextInputFormatter {
  final VoidCallback onValidFirstDigit;
  final VoidCallback onInvalidFirstDigit;

  FirstDigitMobileNumberFormatter({
    required this.onValidFirstDigit,
    required this.onInvalidFirstDigit,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    // If empty, allow
    if (text.isEmpty) {
      return newValue;
    }

    // Check first digit
    if (text.length == 1) {
      int firstDigit = int.tryParse(text) ?? 0;

      // If first digit is valid (6-9), just allow it
      if (firstDigit >= 6 && firstDigit <= 9) {
        // Don't move focus automatically, just validate
        return newValue;
      } else {
        // If first digit is invalid, prevent further input
        onInvalidFirstDigit();
        return oldValue; // Return old value to prevent invalid input
      }
    }

    // Limit to 10 digits
    if (text.length > 10) {
      return TextEditingValue(
        text: text.substring(0, 10),
        selection: const TextSelection.collapsed(offset: 10),
      );
    }

    return newValue;
  }
}