import 'package:dartz/dartz.dart';
import '../repositories/location_repository.dart';
import '../../core/errors/failures.dart';

class DeleteLocation {
  final LocationRepository repository;

  DeleteLocation(this.repository);

  Future<Either<Failure, void>> call(int locationId) async {
    return await repository.deleteLocation(locationId);
  }
}