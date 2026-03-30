// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:attendance_automator/core/di/register_module.dart' as _i1055;
import 'package:attendance_automator/features/attendance/data/datasources/attendance_remote_data_source.dart'
    as _i429;
import 'package:attendance_automator/features/attendance/data/datasources/token_local_data_source.dart'
    as _i834;
import 'package:attendance_automator/features/attendance/data/repositories/attendance_repository_impl.dart'
    as _i1063;
import 'package:attendance_automator/features/attendance/domain/repositories/attendance_repository.dart'
    as _i818;
import 'package:attendance_automator/features/attendance/domain/usecases/get_token.dart'
    as _i110;
import 'package:attendance_automator/features/attendance/domain/usecases/save_token.dart'
    as _i893;
import 'package:attendance_automator/features/attendance/domain/usecases/submit_attendance.dart'
    as _i924;
import 'package:attendance_automator/features/attendance/presentation/bloc/attendance_bloc.dart'
    as _i193;
import 'package:get_it/get_it.dart' as _i174;
import 'package:http/http.dart' as _i519;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.prefs,
      preResolve: true,
    );
    gh.lazySingleton<_i519.Client>(() => registerModule.client);
    gh.lazySingleton<_i429.AttendanceRemoteDataSource>(
      () => _i429.AttendanceRemoteDataSourceImpl(client: gh<_i519.Client>()),
    );
    gh.lazySingleton<_i834.TokenLocalDataSource>(
      () => _i834.TokenLocalDataSourceImpl(
        sharedPreferences: gh<_i460.SharedPreferences>(),
      ),
    );
    gh.lazySingleton<_i818.AttendanceRepository>(
      () => _i1063.AttendanceRepositoryImpl(
        remoteDataSource: gh<_i429.AttendanceRemoteDataSource>(),
        localDataSource: gh<_i834.TokenLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i110.GetToken>(
      () => _i110.GetToken(gh<_i818.AttendanceRepository>()),
    );
    gh.lazySingleton<_i893.SaveToken>(
      () => _i893.SaveToken(gh<_i818.AttendanceRepository>()),
    );
    gh.lazySingleton<_i924.SubmitAttendance>(
      () => _i924.SubmitAttendance(gh<_i818.AttendanceRepository>()),
    );
    gh.factory<_i193.AttendanceBloc>(
      () => _i193.AttendanceBloc(
        getToken: gh<_i110.GetToken>(),
        saveToken: gh<_i893.SaveToken>(),
        submitAttendance: gh<_i924.SubmitAttendance>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i1055.RegisterModule {}
