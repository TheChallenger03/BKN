import 'package:dartz/dartz.dart';
import 'package:latlong2/latlong.dart';
import '../repositories/location_repository.dart';
import '../../core/errors/failures.dart';

class GetCurrentPosition {
  final LocationRepository repository;

  GetCurrentPosition(this.repository);

  Future<Either<Failure, LatLng>> call() async {
    return await repository.getCurrentPosition();
  }
}