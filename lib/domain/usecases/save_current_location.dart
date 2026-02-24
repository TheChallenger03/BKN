import 'package:dartz/dartz.dart';
import '../entities/saved_location.dart';
import '../repositories/location_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/constants/app_constants.dart';

class SaveCurrentLocation {
  final LocationRepository repository;

  SaveCurrentLocation(this.repository);

  Future<Either<Failure, SavedLocation>> call(String label) async {
    //Validate label
    if(label.trim().isEmpty) {
      return Left(ValidationFailure("Label cannot be empty."));
    }
    if(label.length > AppConstants.maxLabelLength) {
      return Left(ValidationFailure("Label is too long."));
    }
    final positionResult = await repository.getCurrentPosition();

    return positionResult.fold(
      (failure) => Left(failure),
      (position) async {
        final savedLocation = SavedLocation(
          label: label,
          latitude: position.latitude,
          longitude: position.longitude,
          createdAt: DateTime.now(),
          isPinned: false,
        );
        return await repository.saveLocation(savedLocation);
      },
    );
  }
}