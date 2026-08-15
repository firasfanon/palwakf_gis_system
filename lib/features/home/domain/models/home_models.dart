// lib/features/home/domain/models/home_models.dart
import 'package:flutter/foundation.dart';

@immutable
class HeroSlide {
  final int id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? ctaText;
  final String? ctaLink;

  const HeroSlide({
    required this.id,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.ctaText,
    this.ctaLink,
  });

  factory HeroSlide.fromMap(Map<String, dynamic> map) {
    return HeroSlide(
      id: map['id'] as int,
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      imageUrl: map['image_url'] as String?,
      ctaText: map['cta_text'] as String?,
      ctaLink: map['cta_link'] as String?,
    );
  }
}

@immutable
class HomeStats {
  final int landsCount;
  final int projectsCount;
  final int governoratesCount;

  const HomeStats({
    required this.landsCount,
    required this.projectsCount,
    required this.governoratesCount,
  });
}

@immutable
class NewsItem {
  final int id;
  final String title;
  final String? summary;
  final DateTime? publishedAt;
  final bool isAnnouncement; // news vs announcement

  const NewsItem({
    required this.id,
    required this.title,
    this.summary,
    this.publishedAt,
    this.isAnnouncement = false,
  });

  factory NewsItem.fromMap(Map<String, dynamic> map) {
    return NewsItem(
      id: map['id'] as int,
      title: map['title'] as String? ?? '',
      summary: map['summary'] as String?,
      publishedAt: map['published_at'] != null
          ? DateTime.tryParse(map['published_at'] as String)
          : null,
      isAnnouncement: (map['type'] as String?) == 'announcement',
    );
  }
}
