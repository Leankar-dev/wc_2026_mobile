import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wc_2026_mobile/core/auth/auth_session_notifier.dart';
import 'package:wc_2026_mobile/core/exceptions/app_exception.dart';
import 'package:wc_2026_mobile/core/result.dart';
import 'package:wc_2026_mobile/data/repositories/auth_session/auth_session_repository.dart';
import 'package:wc_2026_mobile/domain/models/auth_session.dart';
import 'package:wc_2026_mobile/domain/use_cases/auth/auth_logout_use_case.dart';
import 'package:wc_2026_mobile/domain/use_cases/auth/auth_restore_session_use_case.dart';

class _FakeAuthSessionRepository implements AuthSessionRepository {
  _FakeAuthSessionRepository({required this.stored});

  Result<AuthSession?> stored;
  Result<void> deleteResult = Result.done;
  var deleteCalls = 0;

  @override
  Future<Result<void>> delete() async {
    deleteCalls++;
    return deleteResult;
  }

  @override
  Future<Result<AuthSession?>> fetch() async => stored;

  @override
  Future<Result<void>> save(AuthSession session) async => Result.done;
}

const _user = AuthSessionUser(name: 'Ada Lovelace', email: 'ada@mail.com');
const _session = AuthSession(token: 'abc', user: _user);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeAuthSessionRepository repository;
  late StreamController<void> sessionEnded;
  late AuthSessionNotifier notifier;
  var disposed = false;

  AuthSessionNotifier buildNotifier() => AuthSessionNotifier(
    authLogoutUseCase: AuthLogoutUseCase(authSessionRepository: repository),
    authRestoreSessionUseCase: AuthRestoreSessionUseCase(
      authSessionRepository: repository,
    ),
    sessionEnded: sessionEnded.stream,
  );

  setUp(() {
    disposed = false;
    repository = _FakeAuthSessionRepository(stored: Result.ok(_session));
    sessionEnded = StreamController<void>.broadcast();
    notifier = buildNotifier();
  });

  tearDown(() async {
    if (!disposed) notifier.dispose();
    await sessionEnded.close();
  });

  group('AuthSessionNotifier', () {
    test('restores the stored session on creation', () async {
      await _settle();

      expect(notifier.isRestored, isTrue);
      expect(notifier.isSignedIn, isTrue);
      expect(notifier.user, _user);
      expect(notifier.initials, 'AL');
    });

    test('starts signed out when there is no stored session', () async {
      notifier.dispose();
      repository.stored = Result.ok(null);
      notifier = buildNotifier();

      await _settle();

      expect(notifier.isRestored, isTrue);
      expect(notifier.isSignedIn, isFalse);
    });

    test('starts signed out when restoring fails', () async {
      notifier.dispose();
      repository.stored = Result.error(const StorageException());
      notifier = buildNotifier();

      await _settle();

      expect(notifier.isRestored, isTrue);
      expect(notifier.isSignedIn, isFalse);
    });

    test('signedIn stores the user and notifies', () async {
      await _settle();
      var notifications = 0;
      notifier.addListener(() => notifications++);

      notifier.signedIn(const AuthSessionUser(name: 'Grace', email: 'g@x.io'));

      expect(notifier.isSignedIn, isTrue);
      expect(notifier.initials, 'G');
      expect(notifications, 1);
    });

    test('logs out when the backend ends the session', () async {
      await _settle();
      var notifications = 0;
      notifier.addListener(() => notifications++);

      sessionEnded.add(null);
      await _settle();

      expect(repository.deleteCalls, 1);
      expect(notifier.isSignedIn, isFalse);
      expect(notifier.user, isNull);
      expect(notifications, 1);
    });

    test('notifies only once when the session ends repeatedly', () async {
      await _settle();
      var notifications = 0;
      notifier.addListener(() => notifications++);

      sessionEnded
        ..add(null)
        ..add(null)
        ..add(null);
      await _settle();

      expect(notifier.isSignedIn, isFalse);
      expect(notifications, 1);
    });

    test('ends the session even when deleting the token fails', () async {
      await _settle();
      repository.deleteResult = Result.error(const StorageException());

      sessionEnded.add(null);
      await _settle();

      expect(notifier.isSignedIn, isFalse);
    });

    test('stops listening to the stream after dispose', () async {
      await _settle();

      notifier.dispose();
      disposed = true;
      sessionEnded.add(null);
      await _settle();

      expect(repository.deleteCalls, 0);
    });

    test('has no initials without a user', () async {
      notifier.dispose();
      repository.stored = Result.ok(null);
      notifier = buildNotifier();
      await _settle();

      expect(notifier.initials, isEmpty);
    });
  });
}
