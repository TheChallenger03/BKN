import 'package:dartz/dartz.dart';
import '../entities/saved_location.dart';
import '../repositories/location_repository.dart';
import '../../core/errors/failures.dart';

class GetSavedLocations {
  final LocationRepository repository;

  GetSavedLocations(this.repository);

  Future<Either<Failure, List<SavedLocation>>> call() async {
    return await repository.getSavedLocations();
  }
}