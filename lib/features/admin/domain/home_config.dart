// lib/features/admin/domain/home_config.dart

class HomeConfig {
  final String id;
  final String heroTitle;
  final String heroSubtitle;
  final String? heroImageUrl;
  final String? aboutText;
  final bool showStats;
  final bool showNews;
  final bool showServices;
  final DateTime? updatedAt;

  const HomeConfig({
    required this.id,
    required this.heroTitle,
    required this.heroSubtitle,
    this.heroImageUrl,
    this.aboutText,
    this.showStats = true,
    this.showNews = true,
    this.showServices = true,
    this.updatedAt,
  });

  factory HomeConfig.fromMap(Map<String, dynamic> map) {
    return HomeConfig(
      id: map['id'] as String,
      heroTitle: map['hero_title'] as String? ?? 'مستكشف الوقف',
      heroSubtitle: map['hero_subtitle'] as String? ?? 'منصة وطنية لاستكشاف الأوقاف',
      heroImageUrl: map['hero_image_url'] as String?,
      aboutText: map['about_text'] as String?,
      showStats: map['show_stats'] as bool? ?? true,
      showNews: map['show_news'] as bool? ?? true,
      showServices: map['show_services'] as bool? ?? true,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hero_title': heroTitle,
      'hero_subtitle': heroSubtitle,
      'hero_image_url': heroImageUrl,
      'about_text': aboutText,
      'show_stats': showStats,
      'show_news': showNews,
      'show_services': showServices,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  HomeConfig copyWith({
    String? id,
    String? heroTitle,
    String? heroSubtitle,
    String? heroImageUrl,
    String? aboutText,
    bool? showStats,
    bool? showNews,
    bool? showServices,
    DateTime? updatedAt,
  }) {
    return HomeConfig(
      id: id ?? this.id,
      heroTitle: heroTitle ?? this.heroTitle,
      heroSubtitle: heroSubtitle ?? this.heroSubtitle,
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      aboutText: aboutText ?? this.aboutText,
      showStats: showStats ?? this.showStats,
      showNews: showNews ?? this.showNews,
      showServices: showServices ?? this.showServices,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}