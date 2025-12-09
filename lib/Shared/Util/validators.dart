String? validateRequired(String? value) {
  return (value == null || value.trim().isEmpty) ? 'This field is required' : null;
}


String? validateGst(String? value) {
  return (value != null && value.length != 15)
      ? 'Enter a valid 15-digit GST number'
      : null;
}

String? validateEmail(String? value) {
  return (value == null || !value.contains('@')) ? 'Enter a valid email' : null;
}

String? validatePassword(String? value) {
  return (value == null || value.length < 6) ? 'Password must be at least 6 characters' : null;
}


String? validateMobile(String? value) {
  if (value == null || value.isEmpty) {
    return 'Mobile number is required';
  }
  final mobileRegex = RegExp(r'^[0-9]{10}$');
  if (!mobileRegex.hasMatch(value)) {
    return 'Enter a valid 10-digit mobile number';
  }
  return null;
}
