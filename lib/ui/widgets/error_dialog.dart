import 'package:flutter/material.dart';
import 'package:wawa_vansales/config/app_theme.dart';

class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;

  const ErrorDialog({
    Key? key,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.onButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: onButtonPressed ?? () => Navigator.of(context).pop(),
          child: Text(
            buttonLabel ?? 'ตกลง',
            style: const TextStyle(color: AppTheme.primaryColor),
          ),
        ),
      ],
    );
  }
}
