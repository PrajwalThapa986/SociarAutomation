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
  final bool saveTokenLocally;
  final bool skipWeekends;

  const ExecuteAttendanceEvent({
    required this.token,
    required this.startDate,
    required this.endDate,
    this.saveTokenLocally = true,
    this.skipWeekends = true,
  });

  @override
  List<Object> get props => [token, startDate, endDate, saveTokenLocally, skipWeekends];
}
