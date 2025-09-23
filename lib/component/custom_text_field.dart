import 'package:flutter/material.dart';

import 'Color.dart';

class CustomTextField extends StatelessWidget {
  final String title;
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final bool enabled;
  final int? maxLines;
  final TextStyle? titleStyle;
  final TextStyle? textStyle;
  final Color? fillColor;
  final Color? borderColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? contentPadding;
  final Widget? suffixIcon;
  final Widget? prefixIcon;

  const CustomTextField({
    Key? key,
    required this.title,
    this.hintText,
    this.controller,
    this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.enabled = true,
    this.maxLines = 1,
    this.titleStyle,
    this.textStyle,
    this.fillColor,
    this.borderColor,
    this.borderRadius,
    this.contentPadding,
    this.suffixIcon,
    this.prefixIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title above the field
        Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: Text(
            title,
            style: titleStyle ??
                const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
          ),
        ),

        TextFormField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          enabled: enabled,
          maxLines: maxLines,
          style: textStyle ??
              const TextStyle(
                fontSize: 16,
                color: AppColors.secondary,
              ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: AppColors.greyDB,
              fontSize: 16,
            ),
            filled: true,
            fillColor: fillColor ?? Colors.white,
            contentPadding: contentPadding ??
                const EdgeInsets.all(8),
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,

            // Border styling - no animations

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 12.0),
              borderSide: BorderSide(
                color: borderColor ?? AppColors.greyDB,
                width: 0.1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 12.0),
              borderSide: BorderSide(
                color: borderColor ?? AppColors.secondary,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 12.0),
              borderSide: BorderSide(
                color: AppColors.secondary,
                width: 0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 12.0),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 12.0),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
          ),
        )
      ],
    );
  }
}
