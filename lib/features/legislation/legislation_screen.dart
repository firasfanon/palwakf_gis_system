import 'package:flutter/material.dart';

class LegislationScreen extends StatelessWidget {
  const LegislationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'التشريعات — قريباً',
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}
