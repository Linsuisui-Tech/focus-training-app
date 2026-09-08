import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 深空光轨 / 神经脉冲 主题系统
///
/// 设计意图：
/// - 深色背景降低视觉疲劳，营造沉浸专注氛围
/// - 青色/琥珀脉冲光效模拟神经电信号，强化"专注力训练"心智模型
/// - 紫色作为辅助色，用于层级区分与视觉焦点
class AppTheme {
  AppTheme._();

  // 核心色板
  static const Color spaceBlack = Color(0xFF0B0D17);
  static const Color deepNavy = Color(0xFF15192B);
  static const Color panelNavy = Color(0xFF1E2338);
  static const Color neonCyan = Color(0xFF00E0FF);
  static const Color neonCyanDim = Color(0xFF00E0FF);
  static const Color amberPulse = Color(0xFFFFB800);
  static const Color violetNeural = Color(0xFF7B61FF);
  static const Color starWhite = Color(0xFFF0F2FF);
  static const Color nebulaGray = Color(0xFF8B92B4);
  static const Color successGreen = Color(0xFF00E5A8);
  static const Color alertRed = Color(0xFFFF4757);

  // 渐变预设
  static const LinearGradient neuralGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonCyan, violetNeural],
  );

  static const LinearGradient deepSpaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [spaceBlack, deepNavy],
  );

  static const RadialGradient pulseGlow = RadialGradient(
    center: Alignment.center,
    radius: 0.8,
    colors: [Color(0x2200E0FF), Colors.transparent],
  );

  // 阴影与光晕
  static List<BoxShadow> get cyanGlow => [
    BoxShadow(
      color: neonCyan.withValues(alpha: 0.3),
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // 字体：Orbitron 风格科技感 + Noto Sans SC 中文兜底
  static TextTheme get _textTheme {
    final base = GoogleFonts.orbitronTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(color: starWhite, fontWeight: FontWeight.w700),
      displayMedium: base.displayMedium?.copyWith(color: starWhite, fontWeight: FontWeight.w700),
      displaySmall: base.displaySmall?.copyWith(color: starWhite, fontWeight: FontWeight.w600),
      headlineLarge: base.headlineLarge?.copyWith(color: starWhite, fontWeight: FontWeight.w600),
      headlineMedium: base.headlineMedium?.copyWith(color: starWhite, fontWeight: FontWeight.w600),
      headlineSmall: base.headlineSmall?.copyWith(color: starWhite, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.notoSansSc(color: starWhite, fontSize: 20, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.notoSansSc(color: starWhite, fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: GoogleFonts.notoSansSc(color: starWhite, fontSize: 14, fontWeight: FontWeight.w500),
      bodyLarge: GoogleFonts.notoSansSc(color: starWhite, fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: GoogleFonts.notoSansSc(color: starWhite, fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: GoogleFonts.notoSansSc(color: nebulaGray, fontSize: 12, fontWeight: FontWeight.w400),
      labelLarge: GoogleFonts.notoSansSc(color: starWhite, fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: GoogleFonts.notoSansSc(color: starWhite, fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: GoogleFonts.notoSansSc(color: nebulaGray, fontSize: 11, fontWeight: FontWeight.w500),
    );
  }

  // 亮色/暗色主题统一为暗色
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: spaceBlack,
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        onPrimary: spaceBlack,
        secondary: violetNeural,
        onSecondary: starWhite,
        surface: panelNavy,
        onSurface: starWhite,
        surfaceContainerHighest: deepNavy,
        error: alertRed,
        onError: starWhite,
      ),
      textTheme: _textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: spaceBlack.withValues(alpha: 0.8),
        elevation: 0,
        titleTextStyle: GoogleFonts.orbitron(
          color: starWhite,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: neonCyan),
      ),
      cardTheme: CardThemeData(
        color: panelNavy,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonCyan,
          foregroundColor: spaceBlack,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.notoSansSc(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: neonCyan,
          side: const BorderSide(color: neonCyan, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.notoSansSc(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: neonCyan,
          textStyle: GoogleFonts.notoSansSc(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: deepNavy,
        selectedItemColor: neonCyan,
        unselectedItemColor: nebulaGray,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: DividerThemeData(
        color: starWhite.withValues(alpha: 0.1),
        thickness: 1,
      ),
    );
  }

  static ThemeData get theme => darkTheme;
}

/// 主题扩展方法，方便在 Widget 中快速取色
extension ThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
}
