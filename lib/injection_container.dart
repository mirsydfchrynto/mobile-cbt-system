import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:okey_bimbel/core/utils/remote_data_source.dart';
import 'package:okey_bimbel/core/utils/app_logger.dart';

final sl = GetIt.instance;

Future<void> init() async {
  AppLogger.i("Initializing Dependency Injection...");
  
  // External
  if (!sl.isRegistered<FlutterSecureStorage>()) {
    sl.registerLazySingleton(() => const FlutterSecureStorage());
  }
  
  // Services
  if (!sl.isRegistered<RemoteDataSource>()) {
    sl.registerLazySingleton(() => RemoteDataSource());
  }
  
  AppLogger.i("Dependency Injection Initialized.");
}