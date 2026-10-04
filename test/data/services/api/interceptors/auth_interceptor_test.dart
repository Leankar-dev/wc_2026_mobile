import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wc_2026_mobile/data/services/api/interceptors/auth_interceptor.dart';
import 'package:wc_2026_mobile/data/services/local/secure_storage_service.dart';
import 'package:wc_2026_mobile/data/services/local/storage_keys.dart';

class _FakeSecureStorage implements FlutterSecureStorage {
  _FakeSecureStorage(this.values);

  final Map<String, String> values;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.statusCode);

  final int statusCode;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      '{}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _RecordingAdapter adapter;
  late List<void> unauthorizedEvents;

  Dio buildDio({required int status, Map<String, String> stored = const {}}) {
    adapter = _RecordingAdapter(status);
    unauthorizedEvents = [];
    final storage = SecureStorageService(
      storage: _FakeSecureStorage(Map.of(stored)),
    );
    final interceptor = AuthInterceptor(storage: storage);
    interceptor.onUnauthorized.listen(unauthorizedEvents.add);
    return Dio(
        BaseOptions(validateStatus: (code) => code != null && code < 400),
      )
      ..httpClientAdapter = adapter
      ..interceptors.add(interceptor);
  }

  group('AuthInterceptor', () {
    test('sends the bearer token on private routes', () async {
      final dio = buildDio(
        status: 200,
        stored: {StorageKeys.authToken: 'abc'},
      );

      await dio.get<dynamic>('/private');

      expect(adapter.requests.single.headers['Authorization'], 'Bearer abc');
    });

    test('does not send the token on public routes', () async {
      final dio = buildDio(
        status: 200,
        stored: {StorageKeys.authToken: 'abc'},
      );

      await dio.get<dynamic>(
        '/public',
        options: Options(extra: AuthInterceptor.publicRoute),
      );

      expect(
        adapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('sends no header when there is no stored token', () async {
      final dio = buildDio(status: 200);

      await dio.get<dynamic>('/private');

      expect(
        adapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    for (final status in [401, 403]) {
      test('propagates the $status error of a private route', () async {
        final dio = buildDio(
          status: status,
          stored: {StorageKeys.authToken: 'abc'},
        );

        await expectLater(
          dio.get<dynamic>('/private'),
          throwsA(
            isA<DioException>().having(
              (e) => e.response?.statusCode,
              'statusCode',
              status,
            ),
          ),
        );
      });
    }

    test('propagates the 401 error of a public route', () async {
      final dio = buildDio(status: 401);

      await expectLater(
        dio.get<dynamic>(
          '/public',
          options: Options(extra: AuthInterceptor.publicRoute),
        ),
        throwsA(isA<DioException>()),
      );
    });

    for (final status in [401, 403]) {
      test('emits onUnauthorized on $status with a token', () async {
        final dio = buildDio(
          status: status,
          stored: {StorageKeys.authToken: 'abc'},
        );

        await expectLater(
          dio.get<dynamic>('/private'),
          throwsA(isA<DioException>()),
        );
        await Future<void>.delayed(Duration.zero);

        expect(unauthorizedEvents, hasLength(1));
      });
    }

    test('does not emit onUnauthorized on 401 of a public route', () async {
      final dio = buildDio(
        status: 401,
        stored: {StorageKeys.authToken: 'abc'},
      );

      await expectLater(
        dio.get<dynamic>(
          '/public',
          options: Options(extra: AuthInterceptor.publicRoute),
        ),
        throwsA(isA<DioException>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(unauthorizedEvents, isEmpty);
    });

    test('does not emit onUnauthorized on 401 without a token', () async {
      final dio = buildDio(status: 401);

      await expectLater(
        dio.get<dynamic>('/private'),
        throwsA(isA<DioException>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(unauthorizedEvents, isEmpty);
    });

    test('does not emit onUnauthorized on a successful call', () async {
      final dio = buildDio(
        status: 200,
        stored: {StorageKeys.authToken: 'abc'},
      );

      await dio.get<dynamic>('/private');
      await Future<void>.delayed(Duration.zero);

      expect(unauthorizedEvents, isEmpty);
    });

    test('dispose does nothing', () {
      final interceptor = AuthInterceptor(
        storage: SecureStorageService(storage: _FakeSecureStorage({})),
      );

      expect(interceptor.dispose, returnsNormally);
    });
  });
}
