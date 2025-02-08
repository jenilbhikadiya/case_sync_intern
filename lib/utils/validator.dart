String? validateAndTrimField(String? value, String fieldName) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required';
  }
  return null;
}

String? validatePhoneNumber(String? value) {
  if (value == null || !RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
    return 'Enter a valid 10-digit phone number';
  }
  return null;
}

String? validateEmail(String? value) {
  if (value == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
    return 'Enter a valid email address';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.length < 8) {
    return 'Password must be at least 8 characters';
  }
  return null;
}

String? validateTaskInstruction(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Task Instruction is required';
  }
  return null;
}

String? validateTrimmedField(String? value, String fieldName) {
  String trimmedValue = value?.trim() ?? '';
  if (trimmedValue.isEmpty) {
    return '$fieldName is required';
  }
  return null;
}

String? validateAndTrimPhoneNumber(String? value) {
  String trimmedValue = value?.trim() ?? '';
  if (trimmedValue.isEmpty || !RegExp(r'^[0-9]{10}$').hasMatch(trimmedValue)) {
    return 'Enter a valid 10-digit phone number';
  }
  return null;
}
