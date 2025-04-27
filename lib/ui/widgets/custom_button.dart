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
  final bool isCompact;

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
    this.isCompact = false,
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
      final spacing = SizedBox(width: isCompact ? 4 : 8);

      if (iconAfterText) {
        buttonChild = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                text,
                style: TextStyle(color: textColor, fontSize: isCompact ? fontSize - 1 : fontSize, fontWeight: fontWeight),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            spacing,
            icon!,
          ],
        );
      } else {
        buttonChild = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon!,
            spacing,
            Flexible(
              child: Text(
                text,
                style: TextStyle(color: textColor, fontSize: isCompact ? fontSize - 1 : fontSize, fontWeight: fontWeight),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      }
    } else {
      buttonChild = Text(
        text,
        style: TextStyle(color: textColor, fontSize: isCompact ? fontSize - 1 : fontSize, fontWeight: fontWeight),
        overflow: TextOverflow.ellipsis,
      );
    }

    // กำหนด style ของปุ่ม
    final EdgeInsetsGeometry defaultPadding = isCompact ? const EdgeInsets.symmetric(horizontal: 10, vertical: 10) : const EdgeInsets.symmetric(horizontal: 16, vertical: 14);

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
      padding: WidgetStateProperty.all<EdgeInsetsGeometry>(padding ?? defaultPadding),
      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(borderRadius: defaultBorderRadius, side: borderColor != null ? BorderSide(color: borderColor, width: 1.5) : BorderSide.none),
      ),
      minimumSize: isCompact ? WidgetStateProperty.all<Size>(const Size(0, 36)) : null,
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
