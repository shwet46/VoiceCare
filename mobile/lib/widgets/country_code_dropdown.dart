import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class CountryCodeDropdown extends StatelessWidget {
  final TextEditingController controller;
  final String initialCountryCode;
  final void Function(String completeNumber) onChanged;
  final InputDecoration decoration;
  final TextStyle? style;

  const CountryCodeDropdown({
    super.key,
    required this.controller,
    required this.initialCountryCode,
    required this.onChanged,
    required this.decoration,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    // Theme values for Auth Page
    const Color primaryOrange = Color(0xFFDE9243);
    const Color darkOrange = Color(0xFFC4561D);
    const String customFont = 'GoogleSans';

    return IntlPhoneField(
      controller: controller,
      decoration: decoration.copyWith(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryOrange),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkOrange, width: 2),
        ),
        labelStyle: const TextStyle(color: darkOrange, fontFamily: customFont),
        hintStyle: const TextStyle(color: Colors.grey, fontFamily: customFont),
        fillColor: Colors.white,
        filled: true,
      ),
      initialCountryCode: initialCountryCode,
      onChanged: (phone) => onChanged(phone.completeNumber),
      style:
          style ?? const TextStyle(fontFamily: customFont, color: Colors.black),
      dropdownTextStyle: const TextStyle(
        fontFamily: customFont,
        color: primaryOrange,
      ),
      cursorColor: darkOrange,
    );
  }
}
