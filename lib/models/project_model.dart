import 'package:flutter/material.dart';

class Project {
  final String id;
  final String name;
  final String description;
  final int colorValue; 
  final IconData icon;
  final String status; // 'Active', 'Completed', 'Archived'

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.colorValue,
    this.icon = Icons.folder_open,
    this.status = 'Active',
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
}
