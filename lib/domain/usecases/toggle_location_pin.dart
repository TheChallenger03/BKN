import 'package:dartz/dartz.dart';
import '../entities/saved_location.dart';
import '../repositories/location_repository.dart';
import '../../core/errors/failures.dart';

class ToggleLocationPin {
  final LocationRepository repository;

  ToggleLocationPin(this.repository);

  Future<Either<Failure, SavedLocation>> call(int id) async {
    return await repository.togglePin(id);
  }
}