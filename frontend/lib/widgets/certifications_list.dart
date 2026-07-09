import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/models/certification.dart';
import 'package:frontend/widgets/shared/app_card.dart';

class CertificationsList extends StatelessWidget {
  final List<Certification> certifications;

  const CertificationsList({super.key, required this.certifications});

  @override
  Widget build(BuildContext context) {
    if (certifications.isEmpty) {
      return const AppCard(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Chưa đạt chứng chỉ nào.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          for (final cert in certifications)
            ListTile(
              leading: Icon(
                cert.expiryDate != null && cert.expiryDate!.isBefore(DateTime.now())
                    ? Icons.warning_amber_rounded
                    : Icons.verified_outlined,
                color: cert.expiryDate != null && cert.expiryDate!.isBefore(DateTime.now())
                    ? AppTheme.error
                    : AppTheme.primary,
              ),
              title: Text(
                cert.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              subtitle: Text(
                cert.expiryDate != null
                    ? 'Expires: ${DateFormat('MMM yyyy').format(cert.expiryDate!)}'
                    : 'Obtained: ${DateFormat('MMM yyyy').format(cert.obtainedDate)}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}
