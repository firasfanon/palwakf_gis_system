# 🕌 مستكشف الوقف - نظام الإعدادات المتقدم
## Waqf Explorer - Advanced Settings System

[![Flutter](https://img.shields.io/badge/Flutter-3.35.7-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9.2-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 📋 نظرة عامة

حزمة شاملة لنظام إعدادات متقدم لتطبيق **مستكشف الوقف الفلسطيني** - منصة وزارة الأوقاف والشؤون الدينية.

### ✨ المميزات الرئيسية

- 🎛️ **13 تبويب إعدادات** شاملة
- 💾 **تخزين محلي** مع SharedPreferences
- 📤 **تصدير/استيراد** الإعدادات (JSON)
- 🔄 **إدارة حالة** متقدمة مع Riverpod
- 🎨 **واجهة احترافية** RTL
- 🌙 **وضع ليلي/نهاري**
- 🌐 **دعم متعدد اللغات** (AR/EN)
- ⚡ **أداء عالي** مع Caching
- 🔒 **أمان متقدم** مع 2FA
- 📊 **تحليلات شاملة**

---

## 📦 المحتويات

```
waqf_final_package/
├── 📁 data/
│   ├── models/
│   │   └── settings_model.dart (850 سطر)
│   └── services/
│       ├── storage_service.dart (90 سطر)
│       └── export_import_service.dart (100 سطر)
├── 📁 domain/
│   └── providers/
│       └── settings_provider.dart (130 سطر)
├── 📁 core/
│   └── enums/
│       └── settings_tab.dart (110 سطر)
├── 📁 presentation/
│   ├── screens/admin/
│   │   └── general_settings_screen.dart (1100 سطر)
│   └── widgets/settings/
│       └── setting_widgets.dart (450 سطر)
├── 📁 enhanced_files/
│   ├── top_bar.dart
│   ├── header_nav.dart
│   ├── web_footer.dart
│   ├── hero_section.dart
│   └── home_screen.dart
└── 📁 docs/
    ├── INSTALLATION_GUIDE.md
    ├── QUICK_FIX_GUIDE.md
    └── README.md
```

**الإحصائيات:**
- 📄 23 ملف
- 💻 3,290+ سطر كود
- 🐛 27 مشكلة مُصلحة
- ✨ 15+ ميزة جديدة

---

## 🚀 التثبيت السريع

### 1. المتطلبات
```yaml
Flutter: 3.35.7+
Dart: 3.9.2+
```

### 2. إضافة Dependencies
```yaml
dependencies:
  flutter_riverpod: ^2.4.0
  shared_preferences: ^2.2.0
  path_provider: ^2.1.0
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
```

### 3. التثبيت
```bash
# فك الضغط
tar -xzf waqf_final_package.tar.gz

# نسخ الملفات
cp -r waqf_final_package/* lib/

# تثبيت Packages
flutter pub get

# توليد Freezed files
flutter pub run build_runner build --delete-conflicting-outputs

# تشغيل
flutter run -d chrome
```

**📖 للتفاصيل الكاملة:** [INSTALLATION_GUIDE.md](docs/INSTALLATION_GUIDE.md)

---

## 🎛️ التبويبات المتوفرة

### 1. **إعدادات عامة** 🌐
- اسم الموقع والوصف
- اللوغو والأيقونة
- اللغة الافتراضية
- المنطقة الزمنية
- تنسيق التاريخ/الوقت

### 2. **معلومات الاتصال** 📞
- البريد الإلكتروني
- رقم الهاتف
- العنوان
- واتساب

### 3. **وسائل التواصل** 📱
- فيسبوك
- تويتر
- إنستغرام
- يوتيوب
- لينكد إن
- تيليجرام

### 4. **اللغة والترجمة** 🌍
- تفعيل العربية
- تفعيل الإنجليزية
- تفعيل العبرية
- دعم RTL

### 5. **الأمان والخصوصية** 🔒
- المصادقة الثنائية (2FA)
- مهلة الجلسة
- CAPTCHA
- الوصول للضيوف
- عدد محاولات الدخول

### 6. **الإشعارات** 🔔
- إشعارات البريد
- إشعارات SMS
- Push Notifications
- إشعارات المسؤول

### 7. **النظام** ⚙️
- عدد العناصر بالصفحة
- التخزين المؤقت
- حجم الرفع الأقصى
- النسخ الاحتياطي التلقائي

### 8. **المظهر** 🎨
- الثيم الافتراضي
- الوضع الليلي
- الألوان الأساسية
- الخطوط

### 9. **الخرائط** 🗺️
- الموقع الافتراضي
- مستوى التكبير
- مزود الخريطة
- التجميع الذكي

### 10. **إدارة المحتوى** 📝
- مراجعة التعليقات
- التعليقات المجهولة
- البحث المتقدم

### 11. **التقارير** 📊
- Google Analytics
- تتبع المشاهدات
- تقارير شهرية

### 12. **الأداء** ⚡
- الضغط
- التصغير
- التحميل الكسول
- مدة تخزين الأصول

### 13. **التكامل** 🔌
- Supabase URL & Key
- واتساب للأعمال
- APIs خارجية

### 14. **الصيانة** 🔧
- وضع الصيانة
- رسالة الصيانة
- العد التنازلي

---

## 💻 الاستخدام

### تهيئة Provider
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(
      child: WaqfApp(),
    ),
  );
}
```

### قراءة الإعدادات
```dart
final settingsAsync = ref.watch(settingsProvider);

settingsAsync.when(
  data: (settings) {
    print('Site Name: ${settings.siteName}');
  },
  loading: () => CircularProgressIndicator(),
  error: (e, s) => Text('Error: $e'),
);
```

### تحديث الإعدادات
```dart
final notifier = ref.read(settingsProvider.notifier);

await notifier.updateSettings(
  settings.copyWith(
    siteName: 'اسم جديد',
    enableDarkMode: true,
  ),
);
```

### تصدير الإعدادات
```dart
final path = await notifier.exportSettings();
print('Exported to: $path');
```

---

## 🎨 التصميم

### الألوان
```dart
الأخضر الإسلامي: #2D5016
الذهبي: #C4A962
الذهبي الفاتح: #D4AF37
الأخضر الفاتح: #7A9B76
```

### الخطوط
```dart
العربية: Noto Kufi Arabic
الإنجليزية: Roboto
```

---

## 🐛 حل المشاكل

**📖 دليل الإصلاحات السريعة:** [QUICK_FIX_GUIDE.md](docs/QUICK_FIX_GUIDE.md)

### مشاكل شائعة:

#### Build Runner يفشل
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

#### Provider غير موجود
```dart
// تأكد من:
runApp(const ProviderScope(child: WaqfApp()));
```

#### Import خاطئ
```dart
// استخدم:
import 'package:flutter_riverpod/flutter_riverpod.dart';  // ✅
// لا تستخدم:
import 'package:flutter_riverpod/legacy.dart';  // ❌
```

---

## 📚 الوثائق

- [📦 دليل التثبيت](docs/INSTALLATION_GUIDE.md)
- [⚡ الإصلاحات السريعة](docs/QUICK_FIX_GUIDE.md)
- [📖 هذا الملف](docs/README.md)

---

## 🔄 التطورات المستقبلية

- [ ] دمج API الخلفي
- [ ] تطبيق Flutter Mobile
- [ ] خريطة تفاعلية متقدمة
- [ ] نظام إشعارات فوري
- [ ] معرض صور ووثائق
- [ ] تقارير PDF
- [ ] دعم لغات إضافية

---

## 🤝 المساهمة

نرحب بالمساهمات! لتقديم مساهمة:

1. Fork المشروع
2. أنشئ فرع للميزة (`git checkout -b feature/AmazingFeature`)
3. Commit التغييرات (`git commit -m 'Add AmazingFeature'`)
4. Push للفرع (`git push origin feature/AmazingFeature`)
5. افتح Pull Request

---

## 📄 الترخيص

هذا المشروع مرخص تحت MIT License - انظر ملف [LICENSE](LICENSE) للتفاصيل.

---

## 👥 الفريق

**المطور الرئيسي:** Firas  
**المنظمة:** وزارة الأوقاف والشؤون الدينية الفلسطينية  
**الموقع:** https://waqf.ps

---

## 📞 الدعم

- 📧 البريد: info@waqf.ps
- 📱 هاتف: +970 2 2944000
- 🌐 الموقع: https://waqf.ps

---

## 🌟 شكر خاص

شكر خاص لفريق Flutter وRiverpod على الأدوات الرائعة، ولوزارة الأوقاف على دعم المشروع.

---

## 📊 الإحصائيات

![Lines of Code](https://img.shields.io/badge/Lines%20of%20Code-3290-blue)
![Files](https://img.shields.io/badge/Files-23-green)
![Size](https://img.shields.io/badge/Size-33KB-orange)

---

<div dir="rtl">
  
### 🕌 مستكشف الوقف الفلسطيني
**حفظ التراث • توثيق التاريخ • خدمة الأمة**

</div>

---

*آخر تحديث: نوفمبر 2025*
