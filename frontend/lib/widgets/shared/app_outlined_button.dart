import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

class AppOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? color;
  final double? width;

  const AppOutlinedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.color,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppTheme.primary;
    final ButtonStyle style = OutlinedButton.styleFrom(
      foregroundColor: activeColor,
      side: BorderSide(
        color: Color.fromRGBO(
          activeColor.r.toInt(),
          activeColor.g.toInt(),
          activeColor.b.toInt(),
          0.5,
        ),
        width: 1.5,
      ),
      minimumSize: Size(width ?? double.infinity, 48),
    );

    final Widget childContent = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(activeColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          );

    return SizedBox(
      width: width,
      height: 48,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: childContent,
      ),
    );
  }
}
