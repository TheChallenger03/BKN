/// Modello per le statistiche delle location salvate
class LocationStatistics {
  /// Numero totale di location salvate
  final int totalCount;
  
  /// Numero di location con pin attivo
  final int pinnedCount;
  
  LocationStatistics({
    required this.totalCount,
    required this.pinnedCount,
  });
  
  /// Percentuale di location con pin rispetto al totale
  double get pinnedPercentage => 
      totalCount > 0 ? (pinnedCount / totalCount) * 100 : 0;
  
  /// Numero di location non pinnate
  int get unpinnedCount => totalCount - pinnedCount;
  
  @override
  String toString() => 
      'LocationStatistics(total: $totalCount, pinned: $pinnedCount)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationStatistics &&
          runtimeType == other.runtimeType &&
          totalCount == other.totalCount &&
          pinnedCount == other.pinnedCount;
  
  @override
  int get hashCode => totalCount.hashCode ^ pinnedCount.hashCode;
}
