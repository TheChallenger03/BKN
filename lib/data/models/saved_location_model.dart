import '../../domain/entities/saved_location.dart';

class SavedLocationModel extends SavedLocation {
  const SavedLocationModel({
    super.id,
    required super.label,
    required super.latitude,
    required super.longitude,
    required super.createdAt,
    super.isPinned,
  });

  // Convert from entity to model
  factory SavedLocationModel.fromEntity(SavedLocation entity) {
    return SavedLocationModel(
      id: entity.id,
      label: entity.label,
      latitude: entity.latitude,
      longitude: entity.longitude,
      createdAt: entity.createdAt,
      isPinned: entity.isPinned,
    );
  }

  // Convert from database map to model
  factory SavedLocationModel.fromMap(Map<String, dynamic> map) {
    return SavedLocationModel(
      id: map['id'] as int?,
      label: map['label'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      createdAt: DateTime.fromMicrosecondsSinceEpoch(map['createdAt'] as int),
      isPinned: (map['isPinned'] as int) == 1,
    );
  }

  // Convert model to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.microsecondsSinceEpoch,
      'isPinned': isPinned ? 1 : 0,
    };
  }

  // Convert model to entity
  SavedLocation toEntity() {
    return SavedLocation(
      id: id,
      label: label,
      latitude: latitude,
      longitude: longitude,
      createdAt: createdAt,
      isPinned: isPinned,
    );
  }

  // Override copyWith to return SavedLocationModel
  @override
  SavedLocationModel copyWith({
    int? id,
    String? label,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    bool? isPinned,
  }) {
    return SavedLocationModel(
      id: id ?? this.id,
      label: label ?? this.label,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}