import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/attendance_repository.dart';
import 'submit_daily_update.dart'; // To reuse ApiParams

class SubmitAttendance implements UseCase<void, ApiParams> {
  final AttendanceRepository repository;
  SubmitAttendance(this.repository);

  @override
  Future<Either<Failure, void>> call(ApiParams params) async {
    return await repository.submitAttendance(params.date, params.token);
  }
}
