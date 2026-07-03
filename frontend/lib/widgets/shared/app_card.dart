import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final BoxBorder? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    Widget current = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: border ?? Border.all(color: AppTheme.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(10, 0, 0, 0),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      current = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: current,
      );
    }

    return current;
  }
}
