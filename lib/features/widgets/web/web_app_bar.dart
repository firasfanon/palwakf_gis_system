import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// شريط علوي مخصص لنسخة الويب (RTL)
/// الشعار يمين - الروابط في الوسط - زر الدخول يسار
class WebAppBar extends StatelessWidget implements PreferredSizeWidget {
  WebAppBar({super.key});

  // يمكنك تعديل هذه القيم حسب الهوية البصرية
  final Color _backgroundColor = const Color(0xFF0D47A1); // أزرق غامق
  final Color _accentColor = const Color(0xFFFFC107); // ذهبي
  final Color _textColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: preferredSize.height,
        decoration: BoxDecoration(
          color: _backgroundColor,
          boxShadow: const [
            BoxShadow(
              blurRadius: 4,
              offset: Offset(0, 2),
              color: Color(0x33000000),
            ),
          ],
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // ✅ الشعار والعنوان (يمين في RTL)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // لو عندك لوجو حقيقي استبدل Placeholder بـ Image.asset
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _accentColor,
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'و',
                          style: TextStyle(
                            color: _accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مستكشف الوقف الفلسطيني',
                            style: TextStyle(
                              color: _textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'وزارة الأوقاف والشؤون الدينية',
                            style: TextStyle(
                              color: _textColor.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Spacer(),

                  // ✅ روابط التنقل (المنتصف)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _NavButton(
                        label: 'الرئيسية',
                        onTap: () => context.go('/'),
                      ),
                      _NavButton(
                        label: 'الخريطة التفاعلية',
                        onTap: () => context.go('/gis'),
                      ),

                      // ✅ قائمة منسدلة: أخبار | إعلانات
                      const _NavMenuButton(
                        label: 'الأخبار',
                        items: [
                          _NavMenuItem(
                            label: 'الأخبار',
                            route: '/mustakshif/news',
                          ),
                          _NavMenuItem(
                            label: 'الإعلانات',
                            route: '/mustakshif/announcements',
                          ),
                        ],
                      ),

                      // TODO: مسار الخدمات الإلكترونية (سنربطه لاحقاً)
                      _NavButton(
                        label: 'الخدمات الإلكترونية',
                        onTap: () {},
                      ),
                      _NavButton(
                        label: 'عن المشروع',
                        onTap: () => context.go('/about'),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // ✅ زر الدخول (يسار في RTL)
                  TextButton.icon(
                    onPressed: () => context.go('/login'),
                    style: TextButton.styleFrom(
                      foregroundColor: _backgroundColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      backgroundColor: _accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    icon: const Icon(Icons.login),
                    label: const Text('دخول'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(72);
}

class _NavButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NavButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavMenuItem {
  final String label;
  final String route;

  const _NavMenuItem({
    required this.label,
    required this.route,
  });
}

class _NavMenuButton extends StatelessWidget {
  final String label;
  final List<_NavMenuItem> items;

  const _NavMenuButton({
    required this.label,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: PopupMenuButton<_NavMenuItem>(
        tooltip: label,
        position: PopupMenuPosition.under,
        onSelected: (item) => context.go(item.route),
        itemBuilder: (context) => items
            .map(
              (e) => PopupMenuItem<_NavMenuItem>(
                value: e,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(e.label),
                ),
              ),
            )
            .toList(growable: false),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
