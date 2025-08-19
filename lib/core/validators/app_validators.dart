class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  // Phone validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final phoneRegex = RegExp(r'^[\+]?[0-9]{10,13}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }

    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }

    return null;
  }

  // Address validation
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }

    if (value.trim().length < 10) {
      return 'Address must be at least 10 characters';
    }

    return null;
  }

  // Notes validation
  static String? validateNotes(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Notes are required';
    }

    if (value.trim().length < 5) {
      return 'Notes must be at least 5 characters';
    }

    return null;
  }

  // Contactability result validation
  static String? validateContactabilityResult(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Result is required';
    }

    final validResults = [
      'contacted',
      'not_contacted',
      'visited',
      'not_available'
    ];
    if (!validResults.contains(value.toLowerCase())) {
      return 'Invalid result value';
    }

    return null;
  }

  // ID validation
  static String? validateId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'ID is required';
    }

    return null;
  }

  // Coordinate validation
  static String? validateLatitude(double? value) {
    if (value == null) {
      return 'Latitude is required';
    }

    if (value < -90 || value > 90) {
      return 'Latitude must be between -90 and 90';
    }

    return null;
  }

  static String? validateLongitude(double? value) {
    if (value == null) {
      return 'Longitude is required';
    }

    if (value < -180 || value > 180) {
      return 'Longitude must be between -180 and 180';
    }

    return null;
  }
}
