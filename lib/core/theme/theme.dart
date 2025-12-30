
import 'package:flutter/material.dart';
ThemeData lightTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A3D62)),
  textTheme: Typography.englishLike2018.apply(fontFamily: 'NotoKufiArabic'),
  appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0A3D62), foregroundColor: Colors.white, centerTitle: false),
);
ThemeData darkTheme() => ThemeData.dark(useMaterial3: true).copyWith(
  textTheme: Typography.englishLike2018.apply(fontFamily: 'NotoKufiArabic'),
  appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0A3D62), foregroundColor: Colors.white),
);
