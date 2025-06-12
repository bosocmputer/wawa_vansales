import 'package:flutter/material.dart';
import 'package:wawa_vansales/config/app_theme.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String) onSearch;
  final bool autofocus;
  final bool showSearchButton;
  final bool showClearButton;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final double? borderRadius;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onSearch,
    this.autofocus = false,
    this.showSearchButton = true,
    this.showClearButton = true,
    this.contentPadding,
    this.fillColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
        suffixIcon: showClearButton
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                onPressed: () {
                  controller.clear();
                  onSearch('');
                },
              )
            : null,
        filled: true,
        fillColor: fillColor ?? Colors.white,
        contentPadding: contentPadding ?? const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 8),
          borderSide: const BorderSide(color: Colors.grey, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 8),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 8),
          borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5), width: 1),
        ),
      ),
      onSubmitted: onSearch,
      textInputAction: TextInputAction.search,
      onChanged: showSearchButton ? null : onSearch,
    );
  }
}
