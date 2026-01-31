// lib/widgets/empty_state.dart
import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onAction;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: (iconColor ?? kPrimaryColor).withValues(alpha:0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 56, color: iconColor ?? kPrimaryColor),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: primaryTextStyle.copyWith(fontSize: 20, fontWeight: bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: greyTextStyle.copyWith(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(buttonRadius),
                  ),
                  elevation: 2,
                ),
                child: Text(actionText, style: whiteTextStyle.copyWith(fontWeight: bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}