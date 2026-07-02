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

  factory Project.fromMap(String id, Map<String, dynamic> data) {
    final iconName = data['iconName'] as String?;
    final iconCodePoint = data['iconCodePoint'] as int?;
    return Project(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      colorValue: data['colorValue'] as int? ?? 0xFF000000,
      icon: iconName != null
          ? ProjectIcons.byName(iconName)
          : ProjectIcons.byCodePoint(iconCodePoint),
      status: data['status'] as String? ?? 'In Progress',
    );
  }
}
