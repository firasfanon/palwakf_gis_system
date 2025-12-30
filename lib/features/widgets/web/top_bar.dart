// lib/presentation/widgets/top_bar.dart

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class TopBar extends StatefulWidget {
  final VoidCallback? onToggleTheme;

  const TopBar({super.key, this.onToggleTheme});

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  late Timer _timer;
  late DateTime _now;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _initIntl();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  Future<void> _initIntl() async {
    await initializeDateFormatting('ar', null);
    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _timeText {
    if (!_initialized) return '';
    final timeFormat = DateFormat.Hm('ar');
    return timeFormat.format(_now);
  }

  String get _dateText {
    if (!_initialized) return '';
    final dateFormat = DateFormat.yMMMMEEEEd('ar');
    return dateFormat.format(_now);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // ignore
    }
  }

  void _handleSearch() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('البحث'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'ابحث في الموقع...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (_) {
              Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        height: 40,
        color: Colors.blue.shade900,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  if (_timeText.isNotEmpty)
                    Text(
                      _timeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (_dateText.isNotEmpty)
                    Text(
                      _dateText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: _handleSearch,
              icon: const Icon(Icons.search, color: Colors.white, size: 18),
              tooltip: 'بحث',
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: widget.onToggleTheme,
              icon: const Icon(Icons.brightness_6,
                  color: Colors.white, size: 18),
              tooltip: 'تبديل الثيم',
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                IconButton(
                  onPressed: () => _openUrl('https://www.facebook.com/palestine.awqaf'),
                  tooltip: 'Facebook',
                  icon: const Icon(Icons.facebook, color: Colors.white, size: 18),
                ),
                IconButton(
                  onPressed: () => _openUrl('https://x.com/PalestineAwqaf'),
                  tooltip: 'X (Twitter)',
                  icon: const Icon(Icons.alternate_email,
                      color: Colors.white, size: 18),
                ),
                IconButton(
                  onPressed: () => _openUrl('https://www.youtube.com/@PalestineAwqaf'),
                  tooltip: 'YouTube',
                  icon: const Icon(Icons.ondemand_video,
                      color: Colors.white, size: 18),
                ),
                IconButton(
                  onPressed: () => _openUrl('https://t.me/PalestineAwqaf'),
                  tooltip: 'Telegram',
                  icon: const Icon(Icons.telegram,
                      color: Colors.white, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
