
import 'dart:convert';
import 'package:flutter/services.dart';
class Loc {
  static Map<String, String> _map = {};
  static Future<void> loadAr() async {
    final s = await rootBundle.loadString('lib/core/localization/app_ar.json');
    final m = json.decode(s) as Map<String, dynamic>;
    _map = m.map((k, v) => MapEntry(k, v.toString()));
  }
  static String t(String k) => _map[k] ?? k;
}
