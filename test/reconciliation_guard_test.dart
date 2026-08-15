import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GIS reconciliation guard', () {
    test('pubspec pins url_launcher and does not bundle local env files', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();

      expect(
        pubspec,
        contains(
            RegExp(r'^\s+url_launcher:\s+\^6\.1\.14\s*$', multiLine: true)),
      );

      expect(
        pubspec,
        isNot(
            contains(RegExp(r'^\s+url_launcher:\s+any\s*$', multiLine: true))),
      );

      expect(
        pubspec,
        isNot(contains(RegExp(r'^\s+-\s+\.env\s*$', multiLine: true))),
      );
    });

    test('gitignore keeps local environment files out of version control', () {
      final gitignore = File('.gitignore').readAsStringSync();

      expect(gitignore, contains(RegExp(r'^\.env$', multiLine: true)));
      expect(gitignore, contains(RegExp(r'^\.env\.\*$', multiLine: true)));
      expect(
          gitignore, contains(RegExp(r'^!\.env\.example$', multiLine: true)));
    });
  });
}
