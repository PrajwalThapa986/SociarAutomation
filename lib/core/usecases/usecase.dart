import 'package:dartz/dartz.dart';
import 'package:attendance_automator/core/error/failures.dart';

// Interface for all usecases with arguments
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

// Generic params class if no arguments are needed
class NoParams {}
