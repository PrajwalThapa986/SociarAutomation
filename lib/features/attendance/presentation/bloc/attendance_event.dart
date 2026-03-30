import 'package:equatable/equatable.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class LoadTokenEvent extends AttendanceEvent {}

class ExecuteAttendanceEvent extends AttendanceEvent {
  final String token;
  final DateTime startDate;
  final DateTime endDate;

  const ExecuteAttendanceEvent({
    required this.token,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [token, startDate, endDate];
}
