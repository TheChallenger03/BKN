import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../repositories/location_repository.dart';

/// Use case per aggiornare la foto di una location.
/// Rispetta Clean Architecture e Single Responsibility Principle.
class UpdateLocationPhoto {
  final LocationRepository repository;

  UpdateLocationPhoto(this.repository);

  /// Aggiorna la foto di una location
  /// [locationId] - ID della location da aggiornare
  /// [photoPath] - Path della nuova foto (null per rimuoverla)
  Future<Either<Failure, void>> call(int locationId, String? photoPath) async {
    return await repository.updateLocationPhoto(locationId, photoPath);
  }
}
