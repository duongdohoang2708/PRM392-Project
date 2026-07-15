import 'package:flutter/material.dart';
import '../constants/project_icons.dart';

class Project {
  final String id;
  final String name;
  final String description;
  final int colorValue;
  final IconData icon;
  final String status;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.colorValue,
    this.icon = ProjectIcons.defaultIcon,
    this.status = 'In Progress',
  });

  Project copyWith({
    String? name,
    String? description,
    int? colorValue,
    IconData? icon,
    String? status,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorValue: colorValue ?? this.colorValue,
      icon: icon ?? this.icon,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'colorValue': colorValue,
        'iconName': ProjectIcons.nameOf(icon),
        'status': status,
      };

  static const Map<int, int> _colorMigrationMap = {
    0xFF2E7D32: 0xFF388E3C, // Green
    0xFF00A676: 0xFF00796B, // Teal
    0xFF0097A7: 0xFF0097A7, // Cyan
    0xFF0277BD: 0xFF0288D1, // Light Blue
    0xFF3949AB: 0xFF303F9F, // Indigo
    0xFF7B1FA2: 0xFF7B1FA2, // Purple
    0xFFC2185B: 0xFFC2185B, // Pink
    0xFFD32F2F: 0xFFD32F2F, // Red
    0xFFE64A19: 0xFFE64A19, // Deep Orange
    0xFFF9A825: 0xFFFBC02D, // Yellow
    0xFF6D4C41: 0xFF5D4037, // Brown
    0xFF455A64: 0xFF455A64, // Blue Grey
    0xFF8BC34A: 0xFF689F38, // Light Green
    0xFF26C6DA: 0xFF0097A7, // (Merged to Cyan)
    0xFF42A5F5: 0xFF1976D2, // Blue
    0xFF5E35B1: 0xFF512DA8, // Deep Purple
    0xFFEC407A: 0xFFE91E63, // Bright Pink
    0xFFFF7043: 0xFFF57C00, // Orange
    0xFFFFCA28: 0xFFFFA000, // Amber
    0xFF78909C: 0xFF607D8B, // Slate
  };

  factory Project.fromMap(String id, Map<String, dynamic> data) {
    final iconName = data['iconName'] as String?;
    final iconCodePoint = data['iconCodePoint'] as int?;
    
    int rawColor = data['colorValue'] as int? ?? 0xFF000000;
    if (_colorMigrationMap.containsKey(rawColor)) {
      rawColor = _colorMigrationMap[rawColor]!;
    }
    
    return Project(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      colorValue: rawColor,
      icon: iconName != null
          ? ProjectIcons.byName(iconName)
          : ProjectIcons.byCodePoint(iconCodePoint),
      status: data['status'] as String? ?? 'In Progress',
    );
  }
}
