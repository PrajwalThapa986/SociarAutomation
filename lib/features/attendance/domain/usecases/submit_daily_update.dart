import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/attendance_repository.dart';

class SubmitDailyUpdate implements UseCase<void, ApiParams> {
  final AttendanceRepository repository;
  SubmitDailyUpdate(this.repository);

  @override
  Future<Either<Failure, void>> call(ApiParams params) async {
    return await repository.submitDailyUpdate(params.date, params.token);
  }
}

class ApiParams extends Equatable {
  final String date;
  final String token;

  const ApiParams({required this.date, required this.token});

  @override
  List<Object> get props => [date, token];
}
