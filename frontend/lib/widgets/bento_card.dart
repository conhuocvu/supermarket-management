import 'package:flutter/material.dart';

class BentoCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? borderRadius;
  final BorderSide? border;

  const BentoCard({
    Key? key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.border,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardBorderRadius = BorderRadius.circular(borderRadius ?? 16.0);

    Widget container = Container(
      padding: padding ?? const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.cardColor,
        borderRadius: cardBorderRadius,
        border: Border.fromBorderSide(
          border ?? BorderSide(color: theme.dividerColor.withOpacity(0.08), width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: cardBorderRadius,
            splashColor: theme.colorScheme.primary.withOpacity(0.05),
            highlightColor: theme.colorScheme.primary.withOpacity(0.02),
            child: container,
          ),
        ),
      );
    }

    return margin != null
        ? Padding(
            padding: margin!,
            child: container,
          )
        : container;
  }
}
