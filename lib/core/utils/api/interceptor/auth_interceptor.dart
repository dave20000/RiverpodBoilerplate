import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/service_providers.dart';
import '../../constants/app_constants.dart';

class AuthInterceptor extends Interceptor {
  final Ref _ref;
  AuthInterceptor(this._ref);
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!options.path.contains('/login')) {
      final token = await _ref.read(secureStorageManagerProvider).getAsync(
            key: AppConstants.tokenKey,
          );
      options.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }
    handler.next(options);
  }
}
