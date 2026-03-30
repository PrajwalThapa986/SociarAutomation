import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/attendance_repository.dart';

import 'package:injectable/injectable.dart';

@lazySingleton
class SubmitWorklog implements UseCase<void, WorklogParams> {
  final AttendanceRepository repository;
  SubmitWorklog(this.repository);

  @override
  Future<Either<Failure, void>> call(WorklogParams params) async {
    return await repository.submitWorklog(params.date, params.token, params.logContent);
  }
}

class WorklogParams extends Equatable {
  final String date;
  final String token;
  final String logContent;

  const WorklogParams({
    required this.date,
    required this.token,
    required this.logContent,
  });

  @override
  List<Object> get props => [date, token, logContent];
}
