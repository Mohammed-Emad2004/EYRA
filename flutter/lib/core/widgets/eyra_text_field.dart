import 'package:flutter/material.dart';

/// Standard labeled text field used across auth forms.
///
/// Wraps [TextFormField] with consistent semantics, a visible label,
/// and an optional error message shown beneath the field.
class EyraTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final String? errorText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;
  final bool obscureText;
  final Iterable<String>? autofillHints;
  final FormFieldValidator<String>? validator;

  const EyraTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.suffixIcon,
    this.obscureText = false,
    this.autofillHints,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: label,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onChanged: onChanged,
        obscureText: obscureText,
        autofillHints: autofillHints,
        validator: validator,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
