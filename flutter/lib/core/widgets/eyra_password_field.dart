import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'eyra_text_field.dart';

/// Password entry field with a visibility toggle and a minimum 48dp
/// touch target on the toggle icon.
class EyraPasswordField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? errorText;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;
  final FormFieldValidator<String>? validator;

  const EyraPasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.errorText,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.autofillHints,
    this.validator,
  });

  @override
  State<EyraPasswordField> createState() => _EyraPasswordFieldState();
}

class _EyraPasswordFieldState extends State<EyraPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return EyraTextField(
      label: widget.label,
      controller: widget.controller,
      errorText: widget.errorText,
      obscureText: _obscure,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      autofillHints: widget.autofillHints,
      validator: widget.validator,
      suffixIcon: Semantics(
        button: true,
        label: _obscure ? 'Show password' : 'Hide password',
        child: IconButton(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: Icon(
            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppColors.textSecondary,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
