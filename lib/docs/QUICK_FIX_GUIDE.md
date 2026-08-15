# âڑ، ط¯ظ„ظٹظ„ ط§ظ„ط¥طµظ„ط§ط­ط§طھ ط§ظ„ط³ط±ظٹط¹ط©
## Quick Fix Guide

---

## ًں”چ ظپظ‡ط±ط³ ط§ظ„ظ…ط´ط§ظƒظ„

1. [ط£ط®ط·ط§ط، Build Runner](#build-runner-errors)
2. [ط£ط®ط·ط§ط، Import](#import-errors)
3. [ظ…ط´ط§ظƒظ„ Provider](#provider-issues)
4. [ظ…ط´ط§ظƒظ„ Storage](#storage-issues)
5. [ظ…ط´ط§ظƒظ„ UI](#ui-issues)

---

## ًںگ› Build Runner Errors

### ط§ظ„ظ…ط´ظƒظ„ط©: ظپط´ظ„ طھظˆظ„ظٹط¯ ط§ظ„ظ…ظ„ظپط§طھ
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

### ط§ظ„ظ…ط´ظƒظ„ط©: ظ…ظ„ظپط§طھ Freezed ظ‚ط¯ظٹظ…ط©
```
Error: The getter 'copyWith' isn't defined
```

### **Quickieeey:**
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## ًں“¦ Import Errors

### ط§ظ„ظ…ط´ظƒظ„ط©: Cannot find package
```
Error: Couldn't resolve the package 'flutter_riverpod'
```

### **Quickieeey:**
```yaml
# ظپظٹ pubspec.yaml
dependencies:
  flutter_riverpod: ^2.4.0

# ط«ظ…:
flutter pub get
```

---

### ط§ظ„ظ…ط´ظƒظ„ط©: Wrong import path
```
Error: 'package:flutter_riverpod/legacy.dart' not found
```

### **Quickieeey:**
ط§ط³طھط¨ط¯ظ„:
```dart
import 'package:flutter_riverpod/legacy.dart';  // â‌Œ
```
ط¨ظ€:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';  // âœ…
```

---

## ًں”„ Provider Issues

### ط§ظ„ظ…ط´ظƒظ„ط©: ProviderScope not found
```
Error: Couldn't find ProviderScope widget
```

### **Quickieeey:**
```dart
// ظپظٹ main.dart
void main() {
  runApp(
    const ProviderScope(  // âœ… ط£ط¶ظپ ظ‡ط°ط§
      child: WaqfApp(),
    ),
  );
}
```

---

### ط§ظ„ظ…ط´ظƒظ„ط©: Provider not initialized
```
Error: Bad state: No ProviderScope found
```

### **Quickieeey:**
طھط£ظƒط¯ ظ…ظ† ظˆط¬ظˆط¯ `ProviderScope` ظپظٹ ط£ط¹ظ„ظ‰ ط´ط¬ط±ط© widgets.

---

## ًں’¾ Storage Issues

### ط§ظ„ظ…ط´ظƒظ„ط©: SharedPreferences ظ„ط§ ظٹط­ظپط¸
```
Settings not persisting after restart
```

### **Quickieeey:**
```dart
// طھط­ظ‚ظ‚ ظ…ظ†:
1. await prefs.setString(key, value) âœ…
2. return await - ط§ط³طھط®ط¯ظ… await âœ…
3. ظ„ط§ طھظ†ط³ظ‰ await ط¹ظ†ط¯ ط§ظ„ط­ظپط¸ âœ…
```

---

### ط§ظ„ظ…ط´ظƒظ„ط©: JSON decode error
```
Error: type 'String' is not a subtype of type 'int'
```

### **Quickieeey:**
```dart
// ظپظٹ settings_model.dart
@Default(30) int sessionTimeout,  // âœ… ط§ط³طھط®ط¯ظ… int
// ظ„ط§ طھط³طھط®ط¯ظ…:
@Default('30') int sessionTimeout,  // â‌Œ
```

---

## ًںژ¨ UI Issues

### ط§ظ„ظ…ط´ظƒظ„ط©: RTL ظ„ط§ ظٹط¹ظ…ظ„
```
Text appears left-to-right instead of right-to-left
```

### **Quickieeey:**
```dart
import 'dart:ui' as ui;

// ط«ظ… ط§ط³طھط®ط¯ظ…:
textDirection: ui.TextDirection.rtl  // âœ…
```

---

### ط§ظ„ظ…ط´ظƒظ„ط©: TopBar buttons not working
```
Search/Theme buttons don't respond
```

### **Quickieeey:**
```dart
// طھط£ظƒط¯ ظ…ظ†:
1. onPressed: () { ... }  // âœ… ظ„ظٹط³طھ null
2. ط§ظ„ط¯ط§ظ„ط© ظ…ط¹ط±ظ‘ظپط© ظپظٹ State  // âœ…
3. setState() طھظڈط³طھط¯ط¹ظ‰  // âœ…
```

---

### ط§ظ„ظ…ط´ظƒظ„ط©: Colors not applying
```
withOpacity is deprecated
```

### **Quickieeey:**
ط§ط³طھط¨ط¯ظ„:
```dart
color.withOpacity(0.5)  // â‌Œ
```
ط¨ظ€:
```dart
color.withValues(alpha: 0.5)  // âœ…
```

---

## ًں—؛ï¸ڈ Map Issues

### ط§ظ„ظ…ط´ظƒظ„ط©: Map not loading
```
Map tiles not appearing
```

### **Quickieeey:**
```dart
// طھط­ظ‚ظ‚ ظ…ظ† ط§ظ„ط¥ط¹ط¯ط§ط¯ط§طھ:
defaultLatitude: 31.9522  // ظپظ„ط³ط·ظٹظ† âœ…
defaultLongitude: 35.2332
mapProvider: 'OpenStreetMap'  // âœ…
```

---

## ًں”گ Security Issues

### ط§ظ„ظ…ط´ظƒظ„ط©: Supabase not initialized
```
Error: You must initialize supabase
```

### **Quickieeey:**
```dart
// ظپظٹ main.dart
await Supabase.initialize(
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
);
```

---

## ًں“± Router Issues

### ط§ظ„ظ…ط´ظƒظ„ط©: Route not found
```
Error: Could not find a generator for route
```

### **Quickieeey:**
```dart
// ظپظٹ router.dart
GoRoute(
  path: '/admin/settings',  // âœ… ط£ط¶ظپ ط§ظ„ظ…ط³ط§ط±
  builder: (context, state) => const GeneralSettingsScreen(),
),
```

---

## ًں’» Build Issues

### ط§ظ„ظ…ط´ظƒظ„ط©: Web build fails
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

## ًں”„ Hot Reload Issues

### ط§ظ„ظ…ط´ظƒظ„ط©: Changes not reflecting
```
Hot reload not working
```

### **Quickieeey:**
```bash
# ط§ط¶ط؛ط·:
r  # ظ„ظ„ظ€ hot reload
R  # ظ„ظ„ظ€ hot restart
q  # ظ„ظ„ط®ط±ظˆط¬ ط«ظ… flutter run ظ…ط±ط© ط£ط®ط±ظ‰
```

---

## ًں“¦ Dependencies Issues

### ط§ظ„ظ…ط´ظƒظ„ط©: Version conflict
```
Error: Package version conflict
```

### **Quickieeey:**
```bash
flutter pub upgrade
# ط£ظˆ:
flutter pub upgrade --major-versions
```

---

## ًںژ¯ Performance Issues

### ط§ظ„ظ…ط´ظƒظ„ط©: App slow/laggy
```
UI freezing or slow response
```

### **Quickieeey:**
```dart
// ظپظٹ ط§ظ„ط¥ط¹ط¯ط§ط¯ط§طھ:
enableCache: true  // âœ…
enableCompression: true  // âœ…
enableLazyLoading: true  // âœ…
```

---

## ًں“‌ ط­ظپط¸ ط§ظ„ط¥ط¹ط¯ط§ط¯ط§طھ

### ط§ظ„ظ…ط´ظƒظ„ط©: Settings not saving
```
Changes lost after restart
```

### **Quickieeey:**
طھط­ظ‚ظ‚ ظ…ظ† ط§ظ„طھط±طھظٹط¨:
```dart
1. طھط¹ط¯ظٹظ„ ط§ظ„ط¥ط¹ط¯ط§ط¯ط§طھ âœ…
2. ط§ظ„ط¶ط؛ط· ط¹ظ„ظ‰ "ط­ظپط¸" âœ…
3. ط§ظ†طھط¸ط§ط± ط±ط³ط§ظ„ط© ط§ظ„ظ†ط¬ط§ط­ âœ…
4. await ظپظٹ updateSettings âœ…
```

---

## ًںڑ¨ ط®ط·ط£ ط´ط§ط¦ط¹ ط¬ط¯ط§ظ‹!

### â‌Œ ظ†ط³ظٹط§ظ† await
```dart
// ط®ط·ط£:
storageService.saveSettings(settings);  // â‌Œ

// طµط­ظٹط­:
await storageService.saveSettings(settings);  // âœ…
```

---

## ًں“‍ ظ…ط§ ط²ظ„طھ طھظˆط§ط¬ظ‡ ظ…ط´ظƒظ„ط©طں

### ط®ط·ظˆط§طھ ط§ظ„طھط´ط®ظٹطµ:
1. طھط­ظ‚ظ‚ ظ…ظ† console ظ„ظ„ط£ط®ط·ط§ط،
2. ظ†ظپظ‘ط° `flutter doctor`
3. ط§ط­ط°ظپ `.dart_tool` ظˆ `build`
4. `flutter clean && flutter pub get`
5. ط£ط¹ط¯ طھط´ط؛ظٹظ„ IDE

---

**ًں’، ظ†طµظٹط­ط©:** ط§ط­طھظپط¸ ط¨ظ‡ط°ط§ ط§ظ„ظ…ظ„ظپ ظ…ظپطھظˆط­ط§ظ‹ ط£ط«ظ†ط§ط، ط§ظ„طھط·ظˆظٹط±!

---

*طھظ… ط­ظ„ ط§ظ„ظ…ط´ظƒظ„ط©طں ط¹ط¸ظٹظ…! ًںژ‰*
