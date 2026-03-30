import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/attendance_repository.dart';

import 'package:injectable/injectable.dart';

@lazySingleton
class SaveToken implements UseCase<void, String> {
  final AttendanceRepository repository;
  SaveToken(this.repository);

  @override
  Future<Either<Failure, void>> call(String token) async {
    return await repository.saveToken(token);
  }
}
