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
  final bool submitAttendance;
  final bool submitWorklog;
  final String worklogText;

  const ExecuteAttendanceEvent({
    required this.token,
    required this.startDate,
    required this.endDate,
    this.saveTokenLocally = true,
    this.skipWeekends = true,
    this.submitAttendance = true,
    this.submitWorklog = false,
    this.worklogText = "",
  });

  @override
  List<Object> get props => [
        token,
        startDate,
        endDate,
        saveTokenLocally,
        skipWeekends,
        submitAttendance,
        submitWorklog,
        worklogText,
      ];
}

class ApproveAttendanceRequestsEvent extends AttendanceEvent {
  final String token;
  final bool saveTokenLocally;

  const ApproveAttendanceRequestsEvent({
    required this.token,
    this.saveTokenLocally = true,
  });

  @override
  List<Object> get props => [token, saveTokenLocally];
}
