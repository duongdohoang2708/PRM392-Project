import 'package:flutter/material.dart';

/// Curated project icons — all compile-time constants for release tree-shaking.
abstract final class ProjectIcons {
  static const IconData defaultIcon = Icons.folder_outlined;

  static const List<IconData> all = [
    Icons.folder_outlined,
    Icons.work_outline,
    Icons.school_outlined,
    Icons.home_outlined,
    Icons.favorite_outline,
    Icons.fitness_center,
    Icons.code,
    Icons.brush_outlined,
    Icons.book_outlined,
    Icons.flight_outlined,
    Icons.restaurant_outlined,
    Icons.music_note_outlined,
    Icons.shopping_bag_outlined,
    Icons.people_outline,
    Icons.star_outline,
    Icons.rocket_launch_outlined,
    Icons.lightbulb_outline,
    Icons.camera_alt_outlined,
    Icons.sports_esports_outlined,
    Icons.pets_outlined,
  ];

  static const List<String> names = [
    'folder_outlined',
    'work_outline',
    'school_outlined',
    'home_outlined',
    'favorite_outline',
    'fitness_center',
    'code',
    'brush_outlined',
    'book_outlined',
    'flight_outlined',
    'restaurant_outlined',
    'music_note_outlined',
    'shopping_bag_outlined',
    'people_outline',
    'star_outline',
    'rocket_launch_outlined',
    'lightbulb_outline',
    'camera_alt_outlined',
    'sports_esports_outlined',
    'pets_outlined',
  ];

  static String nameOf(IconData icon) {
    for (var i = 0; i < all.length; i++) {
      if (all[i].codePoint == icon.codePoint) return names[i];
    }
    return names.first;
  }

  static IconData byName(String? name) {
    switch (name) {
      case 'folder_outlined':
        return Icons.folder_outlined;
      case 'work_outline':
        return Icons.work_outline;
      case 'school_outlined':
        return Icons.school_outlined;
      case 'home_outlined':
        return Icons.home_outlined;
      case 'favorite_outline':
        return Icons.favorite_outline;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'code':
        return Icons.code;
      case 'brush_outlined':
        return Icons.brush_outlined;
      case 'book_outlined':
        return Icons.book_outlined;
      case 'flight_outlined':
        return Icons.flight_outlined;
      case 'restaurant_outlined':
        return Icons.restaurant_outlined;
      case 'music_note_outlined':
        return Icons.music_note_outlined;
      case 'shopping_bag_outlined':
        return Icons.shopping_bag_outlined;
      case 'people_outline':
        return Icons.people_outline;
      case 'star_outline':
        return Icons.star_outline;
      case 'rocket_launch_outlined':
        return Icons.rocket_launch_outlined;
      case 'lightbulb_outline':
        return Icons.lightbulb_outline;
      case 'camera_alt_outlined':
        return Icons.camera_alt_outlined;
      case 'sports_esports_outlined':
        return Icons.sports_esports_outlined;
      case 'pets_outlined':
        return Icons.pets_outlined;
      default:
        return defaultIcon;
    }
  }

  /// Legacy Firestore field `iconCodePoint` — maps to a known constant icon.
  static IconData byCodePoint(int? codePoint) {
    if (codePoint == null) return defaultIcon;
    for (final icon in all) {
      if (icon.codePoint == codePoint) return icon;
    }
    return defaultIcon;
  }
}
