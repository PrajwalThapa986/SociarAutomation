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
        final textForDate = _getTextForDate(event.worklogText, dateStr);

        if (textForDate == null) {
          currentLogs.add("⏭️ [$dateStr] Skipped Worklog (No data provided for this date)");
          emit(AttendanceRunning(logs: List.from(currentLogs), savedToken: previousToken));
        } else {
          currentLogs.add("⏳ [$dateStr] Processing Worklog...");
          emit(AttendanceRunning(logs: List.from(currentLogs), savedToken: previousToken));

          final entries = _parseEntries(textForDate);
          
          if (entries.isEmpty) {
              currentLogs.add("⚠️ [$dateStr] No valid worklog formatting ([HH:MM - HH:MM]) found. Falling back to default split.");
          }

          final finalEntries = entries.isNotEmpty ? entries : _getDefaultEntries(textForDate);

          final worklogResult = await submitWorklog(WorklogParams(
            date: dateStr, 
            token: event.token, 
            entries: finalEntries,
          ));
          
          worklogResult.fold(
            (failure) {
              currentLogs.add("❌ [$dateStr] Worklog Failed: ${failure.message}");
            },
            (_) {
              currentLogs.add("✅ [$dateStr] Worklog Successful");
              for (var entry in finalEntries) {
                currentLogs.add("   ┕ [${entry.startTime} - ${entry.endTime}] ${entry.description}");
              }
            },
          );

          emit(AttendanceRunning(logs: List.from(currentLogs), savedToken: previousToken));
          await Future.delayed(const Duration(milliseconds: 600));
        }
      }

      current = current.add(const Duration(days: 1));
    }

    currentLogs.add("🏁 Execution completed.");
    emit(AttendanceCompleted(logs: List.from(currentLogs), savedToken: previousToken));
  }

  List<WorklogEntry> _parseEntries(String text) {
    final List<WorklogEntry> entries = [];
    final lines = text.split('\n');
    final regex = RegExp(r'\[(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})\]\s*(.*)');

    for (var line in lines) {
      final match = regex.firstMatch(line.trim());
      if (match != null) {
        String start = match.group(1)!;
        String end = match.group(2)!;
        
        // Pad single digit hours so 9:00 becomes 09:00 for the API
        if (start.length == 4) start = "0$start";
        if (end.length == 4) end = "0$end";

        entries.add(WorklogEntry(
          startTime: start,
          endTime: end,
          description: match.group(3)!.trim(),
        ));
      }
    }
    return entries;
  }

  String? _getTextForDate(String text, String targetDate) {
    final datePattern = RegExp(r'\b\d{4}-\d{2}-\d{2}\b');
    if (!datePattern.hasMatch(text)) {
      return text; // No dates found anywhere, treat entire text as applicable for every day
    }

    final lines = text.split('\n');
    final StringBuffer block = StringBuffer();
    bool recording = false;
    bool foundDate = false;

    for (var line in lines) {
      final match = datePattern.firstMatch(line);
      if (match != null) {
        if (match.group(0) == targetDate) {
          recording = true;
          foundDate = true;
        } else {
          recording = false;
        }
      } else if (recording) {
        block.writeln(line);
      }
    }

    if (foundDate) {
      return block.toString();
    } else {
      return null;
    }
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
