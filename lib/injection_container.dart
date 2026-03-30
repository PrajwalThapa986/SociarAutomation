import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection_container.config.dart';

final sl = GetIt.instance; // sl = Service Locator

@InjectableInit()
Future<void> init() async => await sl.init();
