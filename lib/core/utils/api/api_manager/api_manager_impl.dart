import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_loggy_dio/flutter_loggy_dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loggy/loggy.dart';

import '../../../../domain/service_providers.dart';
import '../../../../presentation/providers/core/connectivity_provider.dart';
import '../../../configs/app_configuration.dart';
import '../../errors/api_exception.dart';
import '../../errors/app_exception.dart';
import '../../mappers/api_dto.dart';
import '../dto_serializers.dart';
import '../interceptor/auth_interceptor.dart';
import '../response/api_error_response.dart';
import '../response/api_response.dart';
import 'api_manager.dart';

typedef HttpLibraryMethod<T> = Future<ApiResponse<T>> Function();

class ApiManagerImpl extends ApiManager {
  late final Dio _dio;
  late final CancelToken _cancelToken;
  late final Ref _ref;

  ApiManagerImpl(this._ref) {
    final BaseOptions options = BaseOptions(
      connectTimeout: const Duration(minutes: 1),
      receiveTimeout: const Duration(minutes: 1),
      headers: {
        HttpHeaders.contentTypeHeader: "application/json",
      },
      // baseUrl: AppConfiguration.baseUrl
    );

    // // Global options
    // final CacheOptions cacheOptions = CacheOptions(
    //   // A default store is required for interceptor.
    //   store: MemCacheStore(maxSize: 10485760, maxEntrySize: 1048576),
    //   // Returns a cached response on error but for statuses 401 & 403.
    //   // Also allows to return a cached response on network errors (e.g. offline usage).
    //   // Defaults to [null].
    //   hitCacheOnErrorExcept: [401, 403],
    // );

    _dio = Dio(options);
    _dio.interceptors.addAll([
      // DioCacheInterceptor(options: cacheOptions),
      LoggyDioInterceptor(
        errorLevel: LogLevel.all,
      ),
      // NetworkLogInterceptor(_ref.read(loggerServiceProvider)),
      AuthInterceptor(_ref),
    ]);
    _cancelToken = CancelToken();
  }

  String _generateUrl(String endPoint, String? newBaseUrl) {
    if (newBaseUrl == null) {
      final baseUrl = AppConfiguration.baseUrl;
      return "$baseUrl/$endPoint";
    } else {
      return "$newBaseUrl/$endPoint";
    }
  }

  @override
  Future<ApiResponse<T>> getAsync<T extends ToJson>({
    required String endpoint,
    String? newBaseUrl,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    return _tryApiRequest<T>(
      () async {
        final response = await _dio.get(
          _generateUrl(endpoint, newBaseUrl),
          queryParameters: queryParams,
          options: Options(
            headers: headers,
          ),
          cancelToken: cancelToken ?? _cancelToken,
        );
        return serializeResponseData<T>(response);
      },
    );
  }

  @override
  Future<ApiResponse<List<T>>> getAsyncList<T extends ToJson>({
    required String endpoint,
    String? newBaseUrl,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    return _tryApiRequest<List<T>>(
      () async {
        final response = await _dio.get(
          _generateUrl(endpoint, newBaseUrl),
          queryParameters: queryParams,
          options: Options(
            headers: headers,
          ),
          cancelToken: cancelToken
          // cancelToken: cancelToken ?? _cancelToken,
          ,
        );
        return serializeResponseDataList<T>(response);
      },
    );
  }

  // if need to post only one object then data will be: post.toJson() i.e Map<String, dynamic>,
  // else data will be posts.map((post) => post.toJson()).toList() i.e List<Map<String,dynamic>>
  @override
  Future<ApiResponse<T>> postAsync<T extends ToJson>({
    required String endpoint,
    required dynamic data,
    String? newBaseUrl,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    return _tryApiRequest<T>(
      () async {
        final response = await _dio.post(
          _generateUrl(endpoint, newBaseUrl),
          data: data,
          queryParameters: queryParams,
          options: Options(
            headers: headers,
          ),
          cancelToken: cancelToken ?? _cancelToken,
        );
        return serializeResponseData<T>(response);
      },
    );
  }

  @override
  Future<ApiResponse<List<T>>> postAsyncList<T extends ToJson>({
    required String endpoint,
    required dynamic data,
    String? newBaseUrl,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    return _tryApiRequest<List<T>>(
      () async {
        final response = await _dio.post(
          _generateUrl(endpoint, newBaseUrl),
          queryParameters: queryParams,
          data: data,
          options: Options(
            headers: headers,
          ),
          cancelToken: cancelToken
          // cancelToken: cancelToken ?? _cancelToken,
          ,
        );
        return serializeResponseDataList<T>(response);
      },
    );
  }

  @override
  Future<ApiResponse<T>> putAsync<T extends ToJson>({
    required String endpoint,
    required dynamic data,
    String? newBaseUrl,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    bool requiresAuthToken = true,
  }) async {
    return _tryApiRequest<T>(
      () async {
        final response = await _dio.put(
          _generateUrl(endpoint, newBaseUrl),
          data: data,
          queryParameters: queryParams,
          options: Options(
            headers: headers,
          ),
          cancelToken: cancelToken ?? _cancelToken,
        );
        return serializeResponseData<T>(response);
      },
    );
  }

  // give the id of object need to be deleted in endpoint otherwise give data
  // if need to delete only one object then data will be: post.toJson() i.e Map<String, dynamic>,
  // else data will be posts.map((post) => post.toJson()).toList() i.e List<Map<String,dynamic>>
  @override
  Future<ApiResponse<T>> deleteAsync<T extends ToJson>({
    required String endpoint,
    dynamic data,
    String? newBaseUrl,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    return _tryApiRequest<T>(
      () async {
        final response = await _dio.delete(
          _generateUrl(endpoint, newBaseUrl),
          data: data,
          queryParameters: queryParams,
          options: Options(
            headers: headers,
          ),
          cancelToken: cancelToken ?? _cancelToken,
        );
        return serializeResponseData<T>(response);
      },
    );
  }

  // give the id of object need to be deleted in endpoint otherwise give data
  // if need to delete only one object then data will be: post.toJson() i.e Map<String, dynamic>,
  // else data will be posts.map((post) => post.toJson()).toList() i.e List<Map<String,dynamic>>
  @override
  Future<ApiResponse<List<T>>> deleteAsyncList<T extends ToJson>({
    required String endpoint,
    dynamic data,
    String? newBaseUrl,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    return _tryApiRequest<List<T>>(
      () async {
        final response = await _dio.delete(
          _generateUrl(endpoint, newBaseUrl),
          data: data,
          queryParameters: queryParams,
          options: Options(
            headers: headers,
          ),
          cancelToken: cancelToken ?? _cancelToken,
        );
        return serializeResponseDataList<T>(response);
      },
    );
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getMapAsync({
    required String endpoint,
    String? newBaseUrl,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    return _tryApiRequest<Map<String, dynamic>>(
      () async {
        final response = await _dio.get(
          _generateUrl(endpoint, newBaseUrl),
          queryParameters: queryParams,
          options: Options(
            headers: headers,
          ),
          cancelToken: cancelToken ?? _cancelToken,
        );
        final data = response.data as Map<String, dynamic>?;
        if (data == null) {
          return const ApiResponse.error(
            AppException.unknownError("Api Response is Empty"),
          );
        }
        return ApiResponse<Map<String, dynamic>>.success(
          data,
          headerResponse: response.headers.map,
        );
      },
    );
  }

  // for APIs that give just a string as response
  @override
  Future<ApiResponse<String>> getStringAsync({
    required String endpoint,
    String? newBaseUrl,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    return _tryApiRequest<String>(() async {
      final response = await _dio.get(
        _generateUrl(endpoint, newBaseUrl),
        queryParameters: queryParams,
        options: Options(
          headers: headers,
        ),
        cancelToken: cancelToken ?? _cancelToken,
      );
      final data = response.data as String?;
      if (data == null) {
        return const ApiResponse.error(
          AppException.unknownError("Api Response is Empty"),
        );
      }
      return ApiResponse<String>.success(
        data,
        headerResponse: response.headers.map,
      );
    });
  }

  @override
  void cancelRequests({CancelToken? cancelToken}) {
    if (cancelToken == null) {
      _cancelToken.cancel('Request Cancelled');
    } else {
      cancelToken.cancel();
    }
  }

  Future<ApiResponse<T>> _tryApiRequest<T>(
    HttpLibraryMethod<T> executeMethod,
  ) async {
    try {
      if (await _ref.read(hasConnectivityProvider)) {
        return await executeMethod();
      } else {
        return const ApiResponse.error(AppException.networkError());
      }
    } on DioException catch (ex, stackTrace) {
      // _loggerService.errorLog(ex, s);

      if (ex.requestOptions.cancelToken?.isCancelled == false) {
        await _ref.read(loggerServiceProvider).dioErrorLog(
              "${ex.requestOptions.path}/${ex.requestOptions.queryParameters}",
              ex,
              stackTrace,
            );
      }

      try {
        return ApiResponse.error(
          AppException.apiError(
            ex.response == null || ex.response!.data == null
                ? null
                : ApiErrorResponse.fromJson(
                    ex.response!.data! as Map<String, dynamic>,
                  ),
            ApiException.getDioException(ex),
          ),
        );
      } catch (_, __) {
        return ApiResponse.error(
          AppException.apiError(
            ApiErrorResponse(
              reason: ex.message,
              code: ex.response?.data.toString(),
              error: null,
              message: null,
              data: null,
            ),
            ApiException.getDioException(ex),
          ),
        );
      }
    } catch (ex, _) {
      // _loggerService.errorLog(ex, s);
      return ApiResponse.error(
        AppException.apiError(null, ApiException.defaultError(ex.toString())),
      );
    }
  }

  Future<ApiResponse<T>> serializeResponseData<T>(Response response) async {
    if (DtoSerializers.serializers[T] != null) {
      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        await _ref.read(loggerServiceProvider).dioErrorLog(
              "${response.requestOptions.path}/${response.requestOptions.queryParameters}",
              "null_data_in_response",
              StackTrace.current,
            );

        return const ApiResponse.error(
          AppException.unknownError("Api Response is Empty"),
        );
      }
      return ApiResponse<T>.success(
        DtoSerializers.serializers[T]!(data) as T,
        headerResponse: response.headers.map,
      );
    } else {
      await _ref.read(loggerServiceProvider).serializationErrorLog<T>(
            "${response.requestOptions.path}/${response.requestOptions.queryParameters}",
          );

      return const ApiResponse.error(
        AppException.serializationError(),
      );
    }
  }

  Future<ApiResponse<List<T>>> serializeResponseDataList<T>(
    Response response,
  ) async {
    if (DtoSerializers.serializers[T] != null) {
      final listData = response.data as List?;
      if (listData == null) {
        return const ApiResponse.success([]);
      }
      return ApiResponse<List<T>>.success(
        listData
            .map(
              (e) => DtoSerializers.serializers[T]!(
                e as Map<String, dynamic>,
              ) as T,
            )
            .toList(),
        headerResponse: response.headers.map,
      );
    } else {
      await _ref.read(loggerServiceProvider).serializationErrorLog<T>(
            "${response.requestOptions.path}/${response.requestOptions.queryParameters}",
          );

      return const ApiResponse.error(
        AppException.serializationError(),
      );
    }
  }
}
