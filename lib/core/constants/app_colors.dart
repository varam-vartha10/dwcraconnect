import 'package:flutter/material.dart';

class AppColors {
  // Brand Identity (Empowerment & Fintech)
  static const Color primaryPurple = Color(0xFF6A1B9A);
  static const Color secondaryPink = Color(0xFFD81B60);
  
  // Aliases for SHG identity
  static const Color shgTeal = Color(0xFF0D7A73); 
  static const Color lotusPink = Color(0xFFD81B60); 
  static const Color fieldGreen = Color(0xFF438A47); 
  static const Color indigo = Color(0xFF3F51B5);
  static const Color harvestGold = Color(0xFFF1A82C);
  
  // Backward compatibility aliases
  static const Color trustBlue = indigo;
  static const Color successGreen = fieldGreen;

  // Backgrounds
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color tealSurface = Color(0xFFE0F2F1);

  // Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFEEEEEE);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPurple, secondaryPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
