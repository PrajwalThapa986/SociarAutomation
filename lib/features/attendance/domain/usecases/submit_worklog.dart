import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/attendance_repository.dart';
import '../entities/worklog_entry.dart';

import 'package:injectable/injectable.dart';

@lazySingleton
class SubmitWorklog implements UseCase<void, WorklogParams> {
  final AttendanceRepository repository;
  SubmitWorklog(this.repository);

  @override
  Future<Either<Failure, void>> call(WorklogParams params) async {
    return await repository.submitWorklog(params.date, params.token, params.entries);
  }
}

class WorklogParams extends Equatable {
  final String date;
  final String token;
  final List<WorklogEntry> entries;

  const WorklogParams({
    required this.date,
    required this.token,
    required this.entries,
  });

  @override
  List<Object> get props => [date, token, entries];
}
