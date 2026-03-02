import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Entity per rappresentare una categoria di location.
/// Segue Clean Architecture: domain layer, indipendente da framework.
class Category extends Equatable {
  final int? id;
  final String name;
  final String icon;
  final String colorHex;

  const Category({
    this.id,
    required this.name,
    this.icon = '📍',
    this.colorHex = '#1976D2',
  });

  /// Converte il colore hex in Color di Flutter
  Color get color {
    final hexColor = colorHex.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }

  Category copyWith({
    int? id,
    String? name,
    String? icon,
    String? colorHex,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  @override
  List<Object?> get props => [id, name, icon, colorHex];
}
