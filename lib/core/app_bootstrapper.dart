import 'dart:developer';

import 'package:flutter/widgets.dart';

import 'configs/adapters/cache_dto_adapters.dart';
import 'configs/app_serializers.dart';
import 'logger/logger_service.dart';
import 'utils/local_storage/cache/cache_manager_impl.dart';
import 'utils/local_storage/secure/secure_storage_manager_impl.dart';

class AppBootStrapper {
  static Future<void> initialize() async {
    try {
      // await Firebase.initializeApp(
      //   options: DefaultFirebaseOptions.currentPlatform,
      // );
      // FlutterError.onError = (errorDetails) {
      //   CrashAnalyticsService().recordFlutterError(errorDetails);
      // };
      final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

      SplashFactory.preserve(widgetsBinding: widgetsBinding);

      LoggerService.init();
      AppSerializer.init();
      await SecureStorageManagerImpl.init();
      await CacheManagerImpl.init(
        registerAdapterAndOpen: (hive) => CacheDtoAdapters.call(hive),
      );
    } catch (ex) {
      log("Error : $ex", error: ex);
    }
  }
}

class SplashFactory {
  static WidgetsBinding? _widgetsBinding;

  // Prevents app from closing splash screen, app layout will be build but not displayed.
  static void preserve({required WidgetsBinding widgetsBinding}) {
    _widgetsBinding = widgetsBinding;
    _widgetsBinding?.deferFirstFrame();
  }

  static void remove() {
    _widgetsBinding?.allowFirstFrame();
    _widgetsBinding = null;
  }
}
