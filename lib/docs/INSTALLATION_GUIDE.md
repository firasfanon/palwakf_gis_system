# 📦 دليل التثبيت الكامل - مستكشف الوقف
## Complete Installation Guide - Waqf Explorer

---

## 🎯 نظرة عامة

هذا الدليل سيرشدك خطوة بخطوة لتثبيت نظام الإعدادات المتقدم لمستكشف الوقف.

**الوقت المتوقع:** 35-45 دقيقة

---

## ✅ المتطلبات الأساسية

### Flutter & Dart
```bash
Flutter: 3.35.7+
Dart: 3.9.2+
```

### Dependencies المطلوبة
```yaml
dependencies:
  flutter_riverpod: ^2.4.0
  shared_preferences: ^2.2.0
  path_provider: ^2.1.0
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1

dev_dependencies:
  build_runner: ^2.4.6
  freezed: ^2.4.5
  json_serializable: ^6.7.1
```

---

## 📂 الخطوة 1: فك الضغط

```bash
# فك ضغط الملف
tar -xzf waqf_final_package.tar.gz

# التحقق من المحتويات
ls -R waqf_final_package/
```

**المحتويات المتوقعة:**
```
waqf_final_package/
├── data/
│   ├── models/
│   └── services/
├── domain/
│   └── providers/
├── core/
│   └── enums/
├── presentation/
│   ├── screens/
│   └── widgets/
├── enhanced_files/
└── docs/
```

---

## 📋 الخطوة 2: إضافة Dependencies

### 2.1 تحديث pubspec.yaml
```bash
cd your_waqf_project
nano pubspec.yaml
```

### 2.2 أضف هذه السطور:
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.0
  
  # Storage
  shared_preferences: ^2.2.0
  path_provider: ^2.1.0
  
  # Serialization
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1

dev_dependencies:
  # Code Generation
  build_runner: ^2.4.6
  freezed: ^2.4.5
  json_serializable: ^6.7.1
```

### 2.3 تثبيت Packages
```bash
flutter pub get
```

---

## 📁 الخطوة 3: نسخ الملفات

### 3.1 نسخ مجلد data
```bash
cp -r waqf_final_package/data lib/
```

**الملفات المنسوخة:**
- `data/models/settings_model.dart`
- `data/services/storage_service.dart`
- `data/services/export_import_service.dart`

### 3.2 نسخ مجلد domain
```bash
cp -r waqf_final_package/domain lib/
```

**الملفات المنسوخة:**
- `domain/providers/settings_provider.dart`

### 3.3 نسخ enums
```bash
cp waqf_final_package/core/enums/settings_tab.dart lib/core/enums/
```

### 3.4 نسخ screens
```bash
cp waqf_final_package/presentation/screens/admin/general_settings_screen.dart \
   lib/presentation/screens/admin/
```

### 3.5 نسخ widgets
```bash
cp waqf_final_package/presentation/widgets/settings/setting_widgets.dart \
   lib/presentation/widgets/settings/
```

---

## 🔧 الخطوة 4: Code Generation

### 4.1 توليد ملفات Freezed & JSON
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**الملفات المتوقع توليدها:**
- `settings_model.freezed.dart`
- `settings_model.g.dart`

### 4.2 التحقق من النجاح
```bash
ls lib/data/models/
```

يجب أن ترى:
```
settings_model.dart
settings_model.freezed.dart  ✅
settings_model.g.dart        ✅
```

---

## 🎨 الخطوة 5: استبدال الملفات المحسنة

### 5.1 TopBar المحسّن
```bash
cp waqf_final_package/enhanced_files/top_bar.dart \
   lib/presentation/widgets/
```

### 5.2 باقي الملفات
```bash
cp waqf_final_package/enhanced_files/header_nav.dart lib/presentation/widgets/
cp waqf_final_package/enhanced_files/web_footer.dart lib/presentation/widgets/
cp waqf_final_package/enhanced_files/hero_section.dart lib/presentation/widgets/
cp waqf_final_package/enhanced_files/home_screen.dart lib/presentation/screens/
```

---

## 🔗 الخطوة 6: تحديث Router

### 6.1 إضافة المسار الجديد

افتح `lib/app/router.dart`:
```dart
import '../presentation/screens/admin/general_settings_screen.dart';

// في قسم routes:
GoRoute(
  path: '/admin/settings',
  builder: (context, state) => const GeneralSettingsScreen(),
),
```

---

## 🚀 الخطوة 7: تحديث main.dart

### 7.1 إضافة ProviderScope

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    const ProviderScope(  // ✅ أضف هذا
      child: WaqfApp(),
    ),
  );
}
```

---

## ✅ الخطوة 8: الاختبار

### 8.1 تشغيل التطبيق
```bash
flutter run -d chrome
```

### 8.2 الانتقال إلى الإعدادات
```
الصفحة الرئيسية → لوحة التحكم → الإعدادات
أو مباشرة: http://localhost:port/admin/settings
```

### 8.3 التحقق من الوظائف
- ✅ فتح 13 تبويب
- ✅ حفظ الإعدادات
- ✅ استعادة الافتراضيات
- ✅ تصدير/استيراد

---

## 🐛 حل المشاكل الشائعة

### مشكلة 1: Build Runner يفشل
```bash
# احذف الملفات القديمة
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### مشكلة 2: Provider غير موجود
```bash
# تأكد من إضافة ProviderScope في main.dart
runApp(const ProviderScope(child: WaqfApp()));
```

### مشكلة 3: Import Errors
```bash
# تأكد من المسارات الصحيحة
import 'package:flutter_riverpod/flutter_riverpod.dart';  // ✅
import 'package:flutter_riverpod/legacy.dart';  // ❌
```

### مشكلة 4: SharedPreferences لا يعمل
```bash
# تأكد من إضافة المكتبة
flutter pub add shared_preferences
flutter pub get
```

---

## 📊 التحقق النهائي

### Checklist:
- [ ] Dependencies مثبتة بنجاح
- [ ] جميع الملفات منسوخة
- [ ] Build runner نفذ بنجاح
- [ ] Router محدّث
- [ ] ProviderScope مضاف
- [ ] التطبيق يعمل بدون أخطاء
- [ ] صفحة الإعدادات تفتح
- [ ] الحفظ يعمل
- [ ] التصدير/الاستيراد يعمل

---

## 🎉 انتهى التثبيت!

**تهانينا!** 🎊 نظام الإعدادات المتقدم جاهز الآن.

### الخطوات التالية:
1. تخصيص الإعدادات حسب احتياجاتك
2. إضافة روابط وسائل التواصل الحقيقية
3. دمج مع Backend API
4. إضافة المزيد من التبويبات عند الحاجة

---

**💡 نصيحة:** احتفظ بنسخة احتياطية من إعداداتك باستخدام زر "تصدير" في واجهة الإعدادات!

---

*تم التثبيت بنجاح! 🚀*
