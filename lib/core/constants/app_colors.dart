// lib/core/constants/app_colors.dart
// Lumina - Core Color Tokens

import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color bgPrimary     = Color(0xFF1A1A2E);   // Main scaffold
  static const Color bgSurface     = Color(0xFF16213E);   // Cards, sheets
  static const Color bgElevated    = Color(0xFF0F3460);   // Elevated cards

  // Accent
  static const Color accentAmber   = Color(0xFFF5A623);   // CTAs, highlights, attendance
  static const Color accentPurple  = Color(0xFF6C63FF);   // Collaboration surfaces
  static const Color accentTeal    = Color(0xFF00B4D8);   // Second Brain, info

  // Stress states (Heatmap)
  static const Color stressLow     = Color(0xFF4CAF50);   // Green
  static const Color stressMed     = Color(0xFFFF9800);   // Amber
  static const Color stressHigh    = Color(0xFFF44336);   // Red

  // Text
  static const Color textPrimary   = Color(0xFFEAEAEA);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textDisabled  = Color(0xFF616161);

  // Kanban column colors
  static const Color kanbanDoing   = Color(0xFF6C63FF);
  static const Color kanbanWant    = Color(0xFFF5A623);
  static const Color kanbanDone    = Color(0xFF4CAF50);
}
