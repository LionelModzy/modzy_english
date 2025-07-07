import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class VocabularyScreen extends StatelessWidget {
  const VocabularyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vocabulary'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Vocabulary Screen - Coming Soon!',
          style: TextStyle(
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
} 