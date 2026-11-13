import 'package:flutter/material.dart';

class AutumnTheme {
  // 가을 감성 컬러 팔레트
  static const Color primaryMaple = Color(0xFFA04218); // 깊은 단풍색
  static const Color secondaryAmber = Color(0xFFD67D27); // 황금빛 앰버
  static const Color backgroundCozy = Color(0xFFFAF7F2); // 아늑한 오트밀 크림
  static const Color surfaceWarm = Color(0xFFFFFFFF); // 웜 화이트
  static const Color textEspresso = Color(0xFF332014); // 에스프레소 다크 브라운
  static const Color textMuted = Color(0xFF7A6B63); // 부드러운 밤색 톤
  static const Color accentForest = Color(0xFF4A6B53); // 가을 숲의 올리브 그린 (완납)
  static const Color accentWine = Color(0xFF9E2A2B); // 버건디 와인 (미납/연체 경고)
  static const Color accentOchre = Color(0xFFCC8B3C); // 앤틱 골드 (선납/부분입금)

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'GowunDodum',
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primaryMaple,
        onPrimary: Colors.white,
        secondary: secondaryAmber,
        onSecondary: Colors.white,
        error: accentWine,
        onError: Colors.white,
        background: backgroundCozy,
        onBackground: textEspresso,
        surface: surfaceWarm,
        onSurface: textEspresso,
      ),
      scaffoldBackgroundColor: backgroundCozy,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundCozy,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textEspresso),
        titleTextStyle: TextStyle(
          color: textEspresso,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceWarm,
        elevation: 1.5,
        shadowColor: primaryMaple.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: secondaryAmber.withOpacity(0.15)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryMaple,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceWarm,
        indicatorColor: primaryMaple.withOpacity(0.15),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: primaryMaple,
            );
          }
          return const TextStyle(fontSize: 12, color: textMuted);
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: primaryMaple);
          }
          return const IconThemeData(color: textMuted);
        }),
      ),
    );
  }
}
