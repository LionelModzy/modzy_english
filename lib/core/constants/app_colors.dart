import 'package:flutter/material.dart';

class AppColors {
  // Primary Blue Colors - Main theme
  static const Color primary = Color(0xFF1E3A8A); // Deep blue
  static const Color primaryLight = Color(0xFF3B82F6); // Bright blue
  static const Color primaryDark = Color(0xFF1E40AF); // Darker blue
  
  // Secondary Blue Colors
  static const Color secondary = Color(0xFF60A5FA); // Light blue
  static const Color secondaryLight = Color(0xFF93C5FD); // Very light blue
  static const Color secondaryDark = Color(0xFF2563EB); // Medium blue
  
  // Accent Colors
  static const Color accent = Color(0xFF06B6D4); // Cyan blue
  static const Color accentLight = Color(0xFF67E8F9); // Light cyan
  static const Color accentDark = Color(0xFF0891B2); // Dark cyan
  
  // Background Colors
  static const Color background = Color(0xFFF8FAFC); // Very light blue-gray
  static const Color surface = Colors.white;
  static const Color cardBackground = Colors.white;
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B); // Dark blue-gray
  static const Color textSecondary = Color(0xFF64748B); // Medium blue-gray
  static const Color textLight = Color(0xFF94A3B8); // Light blue-gray
  static const Color textHint = Color(0xFFCBD5E1); // Very light blue-gray
  
  // Status Colors
  static const Color success = Color(0xFF10B981); // Green
  static const Color warning = Color(0xFFF59E0B); // Orange
  static const Color error = Color(0xFFEF4444); // Red
  static const Color info = Color(0xFF3B82F6); // Blue
  
  // Admin Colors
  static const Color adminPrimary = Color(0xFF7C3AED); // Purple
  static const Color adminSecondary = Color(0xFFA855F7); // Light purple
  static const Color adminBackground = Color(0xFFFAF5FF); // Very light purple
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient adminGradient = LinearGradient(
    colors: [adminPrimary, adminSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Border Colors
  static const Color border = Color(0xFFE2E8F0); // Light blue-gray
  static const Color borderLight = Color(0xFFF1F5F9); // Very light blue-gray
  static const Color borderDark = Color(0xFFCBD5E1); // Medium blue-gray
  
  // Input Colors
  static const Color inputBackground = Colors.white;
  static const Color inputBorder = Color(0xFFE2E8F0);
  static const Color inputFocusedBorder = primary;
  static const Color inputErrorBorder = error;
} 