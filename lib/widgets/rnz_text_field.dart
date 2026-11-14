import 'package:flutter/material.dart';

class RnzTextField extends StatelessWidget {
  const RnzTextField({
    super.key,
    required this.label,
    this.controller,
    this.errorText,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
    this.suffixIcon,
    this.autofillHints,
    this.enabled = true,
    this.fieldKey,
  });

  final String label;
  final Key? fieldKey;
  final TextEditingController? controller;
  final String? errorText;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;
  final Iterable<String>? autofillHints;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      autofillHints: autofillHints,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        errorText: errorText,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
