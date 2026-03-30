import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_token.dart';
import '../../domain/usecases/save_token.dart';
import '../../domain/usecases/submit_attendance.dart';
import '../../../../core/usecases/usecase.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

import 'package:injectable/injectable.dart';

@injectable
class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final GetToken getToken;
  final SaveToken saveToken;
  final SubmitAttendance submitAttendance;

  AttendanceBloc({
    required this.getToken,
    required this.saveToken,
    required this.submitAttendance,
  }) : super(const AttendanceInitial()) {
    on<LoadTokenEvent>(_onLoadToken);
    on<ExecuteAttendanceEvent>(_onExecuteAttendance);
  }

  Future<void> _onLoadToken(LoadTokenEvent event, Emitter<AttendanceState> emit) async {
    final result = await getToken(NoParams());
    result.fold(
      (failure) => emit(const AttendanceInitial()), 
      (token) => emit(AttendanceInitial(savedToken: token)),
    );
  }

  Future<void> _onExecuteAttendance(ExecuteAttendanceEvent event, Emitter<AttendanceState> emit) async {
    // Save token immediately when executing
    await saveToken(event.token);
    final previousToken = event.token;

    List<String> currentLogs = ["🚀 Starting execution..."];
    emit(AttendanceRunning(logs: List.from(currentLogs), savedToken: previousToken));

    DateTime current = event.startDate;
    DateTime end = event.endDate;

    while (!current.isAfter(end)) {
      // 1. Omit Fridays and Saturdays
      // DateTime.weekday: Monday is 1, Friday is 5, Saturday is 6
      if (current.weekday == DateTime.friday || current.weekday == DateTime.saturday) {
        currentLogs.add("⏭️ [${_formatDate(current)}] Skipped (Weekend)");
        emit(AttendanceRunning(logs: List.from(currentLogs), savedToken: previousToken));
        current = current.add(const Duration(days: 1));
        continue;
      }

      String dateStr = _formatDate(current);
      currentLogs.add("⏳ [$dateStr] Processing...");
      emit(AttendanceRunning(logs: List.from(currentLogs), savedToken: previousToken));

      final result = await submitAttendance(ApiParams(date: dateStr, token: event.token));
      
      result.fold(
        (failure) {
          currentLogs.add("❌ [$dateStr] Failed: ${failure.message}");
        },
        (_) {
          currentLogs.add("✅ [$dateStr] Attendance successful");
        },
      );

      emit(AttendanceRunning(logs: List.from(currentLogs), savedToken: previousToken));

      // 600ms delay to prevent rate-limiting as required
      await Future.delayed(const Duration(milliseconds: 600));

      current = current.add(const Duration(days: 1));
    }

    currentLogs.add("🏁 Execution completed.");
    emit(AttendanceCompleted(logs: List.from(currentLogs), savedToken: previousToken));
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
