import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final String? status;

  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 24,
    this.status,
  });

  String get initials {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    Widget avatar;

    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    if (hasImage) {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: AppTheme.surfaceVariant,
        backgroundImage: NetworkImage(imageUrl!),
      );
    } else {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor:
            const Color.fromRGBO(168, 213, 194, 0.5),
        child: Text(
          initials,
          style: TextStyle(
            fontSize: radius * 0.8,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryDark,
          ),
        ),
      );
    }

    if (status != null) {
      Color statusColor;
      switch (status!.toUpperCase()) {
        case 'ON_DUTY':
          statusColor = AppTheme.success;
          break;
        case 'OFF_DUTY':
          statusColor = const Color.fromRGBO(107, 114, 128, 0.5);
          break;
        case 'ON_LEAVE':
          statusColor = AppTheme.secondary;
          break;
        default:
          statusColor = Colors.transparent;
      }

      return Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.5,
              height: radius * 0.5,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      );
    }

    return avatar;
  }
}
