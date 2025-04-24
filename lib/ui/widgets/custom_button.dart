import 'package:flutter/material.dart';
import 'package:wawa_vansales/config/app_theme.dart';

enum ButtonType { primary, secondary, outline, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType buttonType;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? icon;
  final bool iconAfterText;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? customColor;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.buttonType = ButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.padding,
    this.width,
    this.height,
    this.borderRadius,
    this.icon,
    this.iconAfterText = false,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBorderRadius = borderRadius ?? BorderRadius.circular(12);

    // กำหนดสีและสไตล์ตาม buttonType
    Color backgroundColor;
    Color textColor;
    Color? borderColor;

    switch (buttonType) {
      case ButtonType.primary:
        backgroundColor = customColor ?? AppTheme.primaryColor;
        textColor = Colors.white;
        borderColor = null;
        break;
      case ButtonType.secondary:
        backgroundColor = customColor ?? AppTheme.accentColor;
        textColor = AppTheme.textPrimary;
        borderColor = null;
        break;
      case ButtonType.outline:
        backgroundColor = Colors.transparent;
        textColor = customColor ?? AppTheme.primaryColor;
        borderColor = customColor ?? AppTheme.primaryColor;
        break;
      case ButtonType.text:
        backgroundColor = Colors.transparent;
        textColor = customColor ?? AppTheme.primaryColor;
        borderColor = null;
        break;
    }

    // สร้าง child แสดงข้อความหรือ loading
    Widget buttonChild;

    if (isLoading) {
      buttonChild = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(buttonType == ButtonType.primary ? Colors.white : AppTheme.primaryColor)),
      );
    } else if (icon != null) {
      const spacing = SizedBox(width: 8);

      if (iconAfterText) {
        buttonChild = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text(text, style: TextStyle(color: textColor, fontSize: fontSize, fontWeight: fontWeight)), spacing, icon!],
        );
      } else {
        buttonChild = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [icon!, spacing, Text(text, style: TextStyle(color: textColor, fontSize: fontSize, fontWeight: fontWeight))],
        );
      }
    } else {
      buttonChild = Text(text, style: TextStyle(color: textColor, fontSize: fontSize, fontWeight: fontWeight));
    }

    // กำหนด style ของปุ่ม
    final buttonStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return buttonType == ButtonType.primary ? Colors.grey.shade300 : Colors.transparent;
        }
        return backgroundColor;
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.grey.shade500;
        }
        return textColor;
      }),
      overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.pressed)) {
          return textColor.withOpacity(0.1);
        }
        return null;
      }),
      padding: WidgetStateProperty.all<EdgeInsetsGeometry>(padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(borderRadius: defaultBorderRadius, side: borderColor != null ? BorderSide(color: borderColor, width: 1.5) : BorderSide.none),
      ),
    );

    // สร้างปุ่มตามประเภท
    if (buttonType == ButtonType.text) {
      return SizedBox(
        width: isFullWidth ? double.infinity : width,
        height: height,
        child: TextButton(onPressed: isLoading ? null : onPressed, style: buttonStyle, child: buttonChild),
      );
    } else {
      return SizedBox(
        width: isFullWidth ? double.infinity : width,
        height: height,
        child: ElevatedButton(onPressed: isLoading ? null : onPressed, style: buttonStyle, child: buttonChild),
      );
    }
  }
}
