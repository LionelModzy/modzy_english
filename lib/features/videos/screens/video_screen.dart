import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class VideoScreen extends StatelessWidget {
  const VideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Videos'),
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Video Screen - Coming Soon!',
          style: TextStyle(
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
} 