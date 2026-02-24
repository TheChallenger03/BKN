import 'package:dartz/dartz.dart';
import 'package:latlong2/latlong.dart';
import '../entities/route_info.dart';
import '../repositories/location_repository.dart';
import '../../core/errors/failures.dart';

class GetRoute {
  final LocationRepository repository;

  GetRoute(this.repository);

  Future<Either<Failure, RouteInfo>> call({
    required LatLng from,
    required LatLng to,
  }) async {
    return await repository.getRoute(from: from, to: to);
  }
}