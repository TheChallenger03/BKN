import 'package:dartz/dartz.dart';
import '../entities/saved_location.dart';
import '../repositories/location_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/constants/app_constants.dart';

class UpdateLocationLabel {
  final LocationRepository repository;

  UpdateLocationLabel(this.repository);

  Future<Either<Failure, SavedLocation>> call({
    required int id,
    required String newLabel,
  }) async {
    // Validate the new label
    if(newLabel.trim().isEmpty) {
      return Left(ValidationFailure("Label cannot be empty."));
    }
    if(newLabel.length > AppConstants.maxLabelLength) {
      return Left(ValidationFailure("The new label is too long"));
    }
    final locationResult = await repository.getSavedLocationById(id);
    return locationResult.fold(
      (failure) => Left(failure),
      (location) async {
        final updatedLocation = location.copyWith(label: newLabel.trim());
        return await repository.updateLocation(updatedLocation);
      },
    );
  }
}