import 'package:equatable/equatable.dart';

abstract class AttendanceState extends Equatable {
  final List<String> logs;
  final String? savedToken;

  const AttendanceState({this.logs = const [], this.savedToken});

  @override
  List<Object?> get props => [logs, savedToken];
}

class AttendanceInitial extends AttendanceState {
  const AttendanceInitial({super.savedToken});
}

class AttendanceRunning extends AttendanceState {
  const AttendanceRunning({required super.logs, super.savedToken});
}

class AttendanceCompleted extends AttendanceState {
  const AttendanceCompleted({required super.logs, super.savedToken});
}

class AttendanceError extends AttendanceState {
  final String message;

  const AttendanceError({required this.message, required super.logs, super.savedToken});

  @override
  List<Object?> get props => [message, logs, savedToken];
}
