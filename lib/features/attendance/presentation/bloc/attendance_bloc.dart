import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/worklog_entry.dart';
import '../../domain/usecases/get_token.dart';
import '../../domain/usecases/save_token.dart';
import '../../domain/usecases/submit_attendance.dart';
import '../../domain/usecases/submit_worklog.dart';
import '../../../../core/usecases/usecase.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

import 'package:injectable/injectable.dart';

@injectable
class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final GetToken getToken;
  final SaveToken saveToken;
  final SubmitAttendance submitAttendance;
  final SubmitWorklog submitWorklog;

  AttendanceBloc({
    required this.getToken,
    required this.saveToken,
    required this.submitAttendance,
    required this.submitWorklog,
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
    if (event.saveTokenLocally) {
      await saveToken(event.token);
    }
    final previousToken = event.saveTokenLocally ? event.token : null;

    List<String> currentLogs = ["🚀 Starting execution..."];
    emit(AttendanceRunning(logs: List.from(currentLogs), savedToken: previousToken));

    DateTime current = event.startDate;
    DateTime end = event.endDate;

    while (!current.isAfter(end)) {
      // 1. Omit Fridays and Saturdays if skipWeekends is enabled
      // DateTime.weekday: Monday is 1, Friday is 5, Saturday is 6
      if (event.skipWeekends && (current.weekday == DateTime.friday || current.weekday == DateTime.saturday)) {
        currentLogs.add("⏭️ [${_formatDate(current)}] Skipped (Weekend)");
        emit(AttendanceRunning(logs: List.from(currentLogs), savedToken: previousToken));
        current = current.add(const Duration(days: 1));
        continue;
      }

      String dateStr = _formatDate(current);
      
      if (event.submitAttendance) {
        currentLogs.add("⏳ [$dateStr] Processing Attendance...");
        emit(AttendanceRunning(logs: List.from(currentLogs), savedToken: previousToken));

        final result = await submitAttendance(ApiParams(date: dateStr, token: event.token));
        
        result.fold(
          (failure) {
            currentLogs.add("❌ [$dateStr] Attendance Failed: ${failure.message}");
          },
          (_) {
            currentLogs.add("✅ [$dateStr] Attendance Successful");
          },
        );
        
        emit(AttendanceRunning(logs: List.from(currentLogs), savedToken: previousToken));
        // 600ms delay to prevent rate-limiting
        await Future.delayed(const Duration(milliseconds: 600));
      }

      if (event.submitWorklog) {
        currentLogs.add("⏳ [$dateStr] Processing Worklog...");
        emit(AttendanceRunning(logs: List.from(currentLogs), savedToken: previousToken));

        final entries = _parseEntries(event.worklogText);
        
        if (entries.isEmpty) {
            currentLogs.add("⚠️ [$dateStr] No valid worklog formatting ([HH:MM-HH:MM]) found. Falling back to default split.");
        }

        final worklogResult = await submitWorklog(WorklogParams(
          date: dateStr, 
          token: event.token, 
          entries: entries.isNotEmpty ? entries : _getDefaultEntries(event.worklogText),
        ));
        
        worklogResult.fold(
          (failure) {
            currentLogs.add("❌ [$dateStr] Worklog Failed: ${failure.message}");
          },
          (_) {
            final count = entries.isNotEmpty ? entries.length : 2;
            currentLogs.add("✅ [$dateStr] Worklog Successful ($count segments)");
          },
        );

        emit(AttendanceRunning(logs: List.from(currentLogs), savedToken: previousToken));
        await Future.delayed(const Duration(milliseconds: 600));
      }

      current = current.add(const Duration(days: 1));
    }

    currentLogs.add("🏁 Execution completed.");
    emit(AttendanceCompleted(logs: List.from(currentLogs), savedToken: previousToken));
  }

  List<WorklogEntry> _parseEntries(String text) {
    final List<WorklogEntry> entries = [];
    final lines = text.split('\n');
    final regex = RegExp(r'\[(\d{2}:\d{2})\s*-\s*(\d{2}:\d{2})\]\s*(.*)');

    for (var line in lines) {
      final match = regex.firstMatch(line.trim());
      if (match != null) {
        entries.add(WorklogEntry(
          startTime: match.group(1)!,
          endTime: match.group(2)!,
          description: match.group(3)!.trim(),
        ));
      }
    }
    return entries;
  }

  List<WorklogEntry> _getDefaultEntries(String text) {
      final cleanText = text.trim();
      if (cleanText.length > 100) {
          final midpoint = (cleanText.length ~/ 2);
          return [
              WorklogEntry(startTime: '09:00', endTime: '13:00', description: cleanText.substring(0, midpoint)),
              WorklogEntry(startTime: '14:00', endTime: '18:00', description: cleanText.substring(midpoint)),
          ];
      }
      return [
          WorklogEntry(startTime: '09:00', endTime: '13:00', description: cleanText),
          const WorklogEntry(startTime: '14:00', endTime: '18:00', description: 'Continued work...'),
      ];
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
