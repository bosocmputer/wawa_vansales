import 'package:flutter/material.dart';
import 'package:wawa_vansales/config/app_theme.dart';

class SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final VoidCallback? onClear;

  const SearchBox({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        hintText: hintText,
        hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7)),
        prefixIcon: Icon(prefixIcon, color: AppTheme.primaryColor),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                onPressed: () {
                  controller.clear();
                  if (onClear != null) {
                    onClear!();
                  }
                },
              )
            : null,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
        ),
      ),
      style: const TextStyle(fontSize: 16),
      cursorColor: AppTheme.primaryColor,
    );
  }
}
