import 'package:flutter/material.dart';

import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/features/dashboard/domain/entities/dashboard_entities.dart';

class DashboardChatBubble extends StatelessWidget {
  const DashboardChatBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUser ? AppColors.primaryDark : AppColors.divider,
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.textPrimary,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}
