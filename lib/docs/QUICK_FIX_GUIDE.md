# ⚡ دليل الإصلاحات السريعة
## Quick Fix Guide

---

## 🔍 فهرس المشاكل

1. [أخطاء Build Runner](#build-runner-errors)
2. [أخطاء Import](#import-errors)
3. [مشاكل Provider](#provider-issues)
4. [مشاكل Storage](#storage-issues)
5. [مشاكل UI](#ui-issues)

---

## 🐛 Build Runner Errors

### المشكلة: فشل توليد الملفات
```
Error: No builder found for ...freezed...
```

### **Quickieeey:**
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### المشكلة: ملفات Freezed قديمة
```
Error: The getter 'copyWith' isn't defined
```

### **Quickieeey:**
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📦 Import Errors

### المشكلة: Cannot find package
```
Error: Couldn't resolve the package 'flutter_riverpod'
```

### **Quickieeey:**
```yaml
# في pubspec.yaml
dependencies:
  flutter_riverpod: ^2.4.0

# ثم:
flutter pub get
```

---

### المشكلة: Wrong import path
```
Error: 'package:flutter_riverpod/legacy.dart' not found
```

### **Quickieeey:**
استبدل:
```dart
import 'package:flutter_riverpod/legacy.dart';  // ❌
```
بـ:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';  // ✅
```

---

## 🔄 Provider Issues

### المشكلة: ProviderScope not found
```
Error: Couldn't find ProviderScope widget
```

### **Quickieeey:**
```dart
// في main.dart
void main() {
  runApp(
    const ProviderScope(  // ✅ أضف هذا
      child: WaqfApp(),
    ),
  );
}
```

---

### المشكلة: Provider not initialized
```
Error: Bad state: No ProviderScope found
```

### **Quickieeey:**
تأكد من وجود `ProviderScope` في أعلى شجرة widgets.

---

## 💾 Storage Issues

### المشكلة: SharedPreferences لا يحفظ
```
Settings not persisting after restart
```

### **Quickieeey:**
```dart
// تحقق من:
1. await prefs.setString(key, value) ✅
2. return await - استخدم await ✅
3. لا تنسى await عند الحفظ ✅
```

---

### المشكلة: JSON decode error
```
Error: type 'String' is not a subtype of type 'int'
```

### **Quickieeey:**
```dart
// في settings_model.dart
@Default(30) int sessionTimeout,  // ✅ استخدم int
// لا تستخدم:
@Default('30') int sessionTimeout,  // ❌
```

---

## 🎨 UI Issues

### المشكلة: RTL لا يعمل
```
Text appears left-to-right instead of right-to-left
```

### **Quickieeey:**
```dart
import 'dart:ui' as ui;

// ثم استخدم:
textDirection: ui.TextDirection.rtl  // ✅
```

---

### المشكلة: TopBar buttons not working
```
Search/Theme buttons don't respond
```

### **Quickieeey:**
```dart
// تأكد من:
1. onPressed: () { ... }  // ✅ ليست null
2. الدالة معرّفة في State  // ✅
3. setState() تُستدعى  // ✅
```

---

### المشكلة: Colors not applying
```
withOpacity is deprecated
```

### **Quickieeey:**
استبدل:
```dart
color.withOpacity(0.5)  // ❌
```
بـ:
```dart
color.withValues(alpha: 0.5)  // ✅
```

---

## 🗺️ Map Issues

### المشكلة: Map not loading
```
Map tiles not appearing
```

### **Quickieeey:**
```dart
// تحقق من الإعدادات:
defaultLatitude: 31.9522  // فلسطين ✅
defaultLongitude: 35.2332
mapProvider: 'OpenStreetMap'  // ✅
```

---

## 🔐 Security Issues

### المشكلة: Supabase not initialized
```
Error: You must initialize supabase
```

### **Quickieeey:**
```dart
// في main.dart
await Supabase.initialize(
  url: dotenv.env['SUPABASE_URL']!,
  anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
);
```

---

## 📱 Router Issues

### المشكلة: Route not found
```
Error: Could not find a generator for route
```

### **Quickieeey:**
```dart
// في router.dart
GoRoute(
  path: '/admin/settings',  // ✅ أضف المسار
  builder: (context, state) => const GeneralSettingsScreen(),
),
```

---

## 💻 Build Issues

### المشكلة: Web build fails
```
Error building web app
```

### **Quickieeey:**
```bash
flutter clean
flutter pub get
flutter build web --release
```

---

## 🔄 Hot Reload Issues

### المشكلة: Changes not reflecting
```
Hot reload not working
```

### **Quickieeey:**
```bash
# اضغط:
r  # للـ hot reload
R  # للـ hot restart
q  # للخروج ثم flutter run مرة أخرى
```

---

## 📦 Dependencies Issues

### المشكلة: Version conflict
```
Error: Package version conflict
```

### **Quickieeey:**
```bash
flutter pub upgrade
# أو:
flutter pub upgrade --major-versions
```

---

## 🎯 Performance Issues

### المشكلة: App slow/laggy
```
UI freezing or slow response
```

### **Quickieeey:**
```dart
// في الإعدادات:
enableCache: true  // ✅
enableCompression: true  // ✅
enableLazyLoading: true  // ✅
```

---

## 📝 حفظ الإعدادات

### المشكلة: Settings not saving
```
Changes lost after restart
```

### **Quickieeey:**
تحقق من الترتيب:
```dart
1. تعديل الإعدادات ✅
2. الضغط على "حفظ" ✅
3. انتظار رسالة النجاح ✅
4. await في updateSettings ✅
```

---

## 🚨 خطأ شائع جداً!

### ❌ نسيان await
```dart
// خطأ:
storageService.saveSettings(settings);  // ❌

// صحيح:
await storageService.saveSettings(settings);  // ✅
```

---

## 📞 ما زلت تواجه مشكلة؟

### خطوات التشخيص:
1. تحقق من console للأخطاء
2. نفّذ `flutter doctor`
3. احذف `.dart_tool` و `build`
4. `flutter clean && flutter pub get`
5. أعد تشغيل IDE

---

**💡 نصيحة:** احتفظ بهذا الملف مفتوحاً أثناء التطوير!

---

*تم حل المشكلة؟ عظيم! 🎉*
