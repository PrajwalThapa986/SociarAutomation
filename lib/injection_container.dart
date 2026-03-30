import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'features/attendance/data/datasources/attendance_remote_data_source.dart';
import 'features/attendance/data/datasources/token_local_data_source.dart';
import 'features/attendance/data/repositories/attendance_repository_impl.dart';
import 'features/attendance/domain/repositories/attendance_repository.dart';
import 'features/attendance/domain/usecases/get_token.dart';
import 'features/attendance/domain/usecases/save_token.dart';
import 'features/attendance/domain/usecases/submit_attendance.dart';
import 'features/attendance/presentation/bloc/attendance_bloc.dart';

final sl = GetIt.instance; // sl = Service Locator

Future<void> init() async {
  // Features - Attendance
  // Bloc
  sl.registerFactory(
    () => AttendanceBloc(
      getToken: sl(),
      saveToken: sl(),
      submitAttendance: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetToken(sl()));
  sl.registerLazySingleton(() => SaveToken(sl()));
  sl.registerLazySingleton(() => SubmitAttendance(sl()));

  // Repository
  sl.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<AttendanceRemoteDataSource>(
    () => AttendanceRemoteDataSourceImpl(client: sl()),
  );

  sl.registerLazySingleton<TokenLocalDataSource>(
    () => TokenLocalDataSourceImpl(sharedPreferences: sl()),
  );

  // Core (if any)
  
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => http.Client());
}
