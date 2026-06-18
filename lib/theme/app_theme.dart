import 'package:flutter/material.dart';
import 'app_colors.dart';

class VetRouteTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      // Criamos o esquema de cores baseado nas suas cores principais
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        // 💡 Aqui definimos o nosso tom de Âmbar/Laranja para os Entregadores
        tertiary: Colors.amber.shade700,
        surface: AppColors.background,
      ),

      scaffoldBackgroundColor: AppColors.background,

      // Estilo global dos botões (Elevated)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Estilo global da AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
    );
  }
}
