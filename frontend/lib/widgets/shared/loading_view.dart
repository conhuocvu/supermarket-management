import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

class LoadingView extends StatelessWidget {
  final String? message;
  final bool isFullScreen;

  const LoadingView({
    super.key,
    this.message,
    this.isFullScreen = true,
  });

  @override
  Widget build(BuildContext context) {
    final spinner = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (isFullScreen) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: spinner,
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: spinner,
      ),
    );
  }
}
