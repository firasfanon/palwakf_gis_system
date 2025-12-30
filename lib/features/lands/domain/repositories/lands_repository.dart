// lib/features/lands/domain/repositories/lands_repository.dart
import '../models/waqf_land.dart';

/// واجهة مستودع بيانات الأراضي الوقفية
abstract class ILandsRepository {
  Future<List<WaqfLand>> getLands({String? searchQuery});
  Future<WaqfLand?> getLandById(String id);
  Future<WaqfLand> createLand(WaqfLand land);
  Future<WaqfLand> updateLand(WaqfLand land);
  Future<void> deleteLand(String id);
}
