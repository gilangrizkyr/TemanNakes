import 'package:flutter/material.dart';

/// Standardized input field for medical calculators.
/// Supports: auto-focus, real-time validation, default values, suffix units.
class CalcInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? unit;
  final String? defaultValue;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final Widget? prefixIcon;
  final VoidCallback? onChanged;

  const CalcInputField({
    super.key,
    required this.controller,
    required this.label,
    this.unit,
    this.defaultValue,
    this.validator,
    this.keyboardType = TextInputType.number,
    this.focusNode,
    this.nextFocusNode,
    this.prefixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction:
          nextFocusNode != null ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (nextFocusNode != null) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        }
      },
      onChanged: (_) => onChanged?.call(),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: defaultValue != null ? 'Default: $defaultValue' : null,
        suffixText: unit,
        prefixIcon: prefixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        errorStyle: const TextStyle(fontSize: 11),
      ),
    );
  }
}
