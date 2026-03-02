import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../repositories/location_repository.dart';

/// Use case per assegnare una categoria a una location.
/// Rispetta Clean Architecture e Single Responsibility Principle.
class AssignCategoryToLocation {
  final LocationRepository repository;

  AssignCategoryToLocation(this.repository);

  /// Assegna una categoria a una location
  /// [locationId] - ID della location da aggiornare
  /// [categoryId] - ID della categoria da assign (null per rimuoverla)
  Future<Either<Failure, void>> call(int locationId, int? categoryId) async {
    return await repository.assignCategoryToLocation(locationId, categoryId);
  }
}
