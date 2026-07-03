import 'package:flutter/material.dart';

class PageContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final double horizontalPadding;

  const PageContainer({
    super.key,
    required this.child,
    this.maxWidth = 800,
    this.horizontalPadding = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: child,
        ),
      ),
    );
  }
}
