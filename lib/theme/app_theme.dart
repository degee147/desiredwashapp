import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get theme => ThemeData(
        fontFamily: 'serif',
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.light(
          primary: AppColors.coral,
          secondary: AppColors.peach,
          surface: AppColors.cardBg,
        ),
        useMaterial3: true,
      );
}
