import 'package:equatable/equatable.dart';
import 'category.dart';

class SavedLocation extends Equatable {
  final int? id;
  final String label;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final bool isPinned;
  final String? photoPath;
  final Category? category;

  const SavedLocation({
    this.id,
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.isPinned = false,
    this.photoPath,
    this.category,
  });

  SavedLocation copyWith({
    int? id,
    String? label,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    bool? isPinned,
    String? photoPath,
    Category? category,
  }) {
    return SavedLocation(
      id: id ?? this.id,
      label: label ?? this.label,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      isPinned: isPinned ?? this.isPinned,
      photoPath: photoPath ?? this.photoPath,
      category: category ?? this.category,
    );
  }

  @override
  List<Object?> get props => [
    id,
    label, 
    latitude, 
    longitude, 
    createdAt, 
    isPinned,
    photoPath,
    category,
  ];
}