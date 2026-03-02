import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/category.dart';
import '../repositories/location_repository.dart';

/// Use case per ottenere tutte le categorie disponibili.
/// Rispetta Clean Architecture e Single Responsibility Principle.
class GetCategories {
  final LocationRepository repository;

  GetCategories(this.repository);

  Future<Either<Failure, List<Category>>> call() async {
    return await repository.getCategories();
  }
}
