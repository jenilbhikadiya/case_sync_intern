// lib/utils/validators.dart

/// Validates and trims input. Returns an error message if invalid; otherwise, returns null.
String? validateAndTrimField(String? value, String fieldName) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required';
  }
  return null;
}

/// Validates a phone number. Returns null if valid, otherwise an error message.
String? validatePhoneNumber(String? value) {
  if (value == null || !RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
    return 'Enter a valid 10-digit phone number';
  }
  return null;
}

/// Validates an email address. Returns null if valid, otherwise an error message.
String? validateEmail(String? value) {
  if (value == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
    return 'Enter a valid email address';
  }
  return null;
}

/// Validates a password. Returns null if valid, otherwise an error message.
String? validatePassword(String? value) {
  if (value == null || value.length < 8) {
    return 'Password must be at least 8 characters';
  }
  return null;
}

/// Validates the task instruction. Trims leading/trailing spaces before checking.
/// Returns an error message if invalid; otherwise, returns null.
String? validateTaskInstruction(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Task Instruction is required';
  }
  return null;
}

/// Helper function to trim input while ensuring proper validation.
String? validateTrimmedField(String? value, String fieldName) {
  String trimmedValue = value?.trim() ?? '';
  if (trimmedValue.isEmpty) {
    return '$fieldName is required';
  }
  return null;
}

/// Validates a contact number (phone number). Returns null if valid, otherwise an error message.
String? validateAndTrimPhoneNumber(String? value) {
  String trimmedValue = value?.trim() ?? '';
  if (trimmedValue.isEmpty || !RegExp(r'^[0-9]{10}$').hasMatch(trimmedValue)) {
    return 'Enter a valid 10-digit phone number';
  }
  return null;
}
