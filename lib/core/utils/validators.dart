/// Reusable, pure form-validation functions shared across every auth and
/// profile form. Kept dependency-free so they're trivially unit-testable.
abstract final class Validators {
  static final _emailRegex = RegExp(r'^[\w\.\-+]+@([\w\-]+\.)+[\w\-]{2,}$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Include at least one uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Include at least one number';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  static String? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Full name is required';
    if (v.length < 2) return 'Enter your full name';
    return null;
  }

  static String? url(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null; // optional field in most forms
    final uri = Uri.tryParse(v);
    if (uri == null || !uri.isAbsolute) return 'Enter a valid URL';
    return null;
  }

  static String? requiredUrl(String? value, {String fieldName = 'URL'}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '$fieldName is required';
    return url(v);
  }

  static String? optionalPositiveInt(String? value, {String fieldName = 'Value'}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    final n = int.tryParse(v);
    if (n == null || n < 1) return '$fieldName must be a positive number';
    return null;
  }

  static String? optionalCoordinate(String? value, {required bool isLatitude}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    final n = double.tryParse(v);
    if (n == null) return 'Enter a valid number';
    if (isLatitude && (n < -90 || n > 90)) return 'Latitude must be between -90 and 90';
    if (!isLatitude && (n < -180 || n > 180)) return 'Longitude must be between -180 and 180';
    return null;
  }
}
