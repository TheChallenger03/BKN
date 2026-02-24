import 'package:equatable/equatable.dart';

class SavedLocation extends Equatable {
  final int? id;
  final String label;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final bool isPinned;

  const SavedLocation({
    this.id,
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.isPinned = false,
  });

  SavedLocation copyWith({
    int? id,
    String? label,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    bool? isPinned,
  }) {
    return SavedLocation(
      id: id ?? this.id,
      label: label ?? this.label,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  @override
  List<Object?> get props => [
    id,
    label, 
    latitude, 
    longitude, 
    createdAt, 
    isPinned];
}