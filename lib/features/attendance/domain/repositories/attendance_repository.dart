import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/worklog_entry.dart';

abstract class AttendanceRepository {
  Future<Either<Failure, void>> saveToken(String token);
  Future<Either<Failure, String?>> getToken();
  Future<Either<Failure, void>> submitAttendance(String date, String token);
  Future<Either<Failure, void>> submitWorklog(String date, String token, List<WorklogEntry> entries);
}
