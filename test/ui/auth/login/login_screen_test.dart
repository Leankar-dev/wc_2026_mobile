import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/core/auth/auth_session_notifier.dart';
import 'package:wc_2026_mobile/core/result.dart';
import 'package:wc_2026_mobile/data/repositories/auth/auth_repository.dart';
import 'package:wc_2026_mobile/data/repositories/auth_session/auth_session_repository.dart';
import 'package:wc_2026_mobile/domain/models/auth_session.dart';
import 'package:wc_2026_mobile/domain/use_cases/auth/auth_login_use_case.dart';
import 'package:wc_2026_mobile/domain/use_cases/auth/auth_logout_use_case.dart';
import 'package:wc_2026_mobile/domain/use_cases/auth/auth_restore_session_use_case.dart';
import 'package:wc_2026_mobile/ui/auth/login/login_screen.dart';
import 'package:wc_2026_mobile/ui/auth/login/login_viewmodel.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  }) async => Result.ok(
    AuthSession(
      token: 'abc',
      user: AuthSessionUser(name: 'Ada', email: email),
    ),
  );

  @override
  Future<Result<void>> register({
    required String name,
    required String email,
    required String password,
    required List<String> favoriteTeams,
    required bool acceptedTerms,
  }) async => Result.done;
}

class _FakeAuthSessionRepository implements AuthSessionRepository {
  @override
  Future<Result<void>> delete() async => Result.done;

  @override
  Future<Result<AuthSession?>> fetch() async => Result.ok(null);

  @override
  Future<Result<void>> save(AuthSession session) async => Result.done;
}

LoginViewModel _viewModel() {
  final sessionRepository = _FakeAuthSessionRepository();
  final notifier = AuthSessionNotifier(
    authLogoutUseCase: AuthLogoutUseCase(
      authSessionRepository: sessionRepository,
    ),
    authRestoreSessionUseCase: AuthRestoreSessionUseCase(
      authSessionRepository: sessionRepository,
    ),
    sessionEnded: Stream<void>.empty(),
  );
  return LoginViewModel(
    loginUseCase: AuthLoginUseCase(
      authRepository: _FakeAuthRepository(),
      authSessionRepository: sessionRepository,
    ),
    sessionNotifier: notifier,
  );
}

Widget _host() => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(0.8)),
    child: child!,
  ),
  home: LoginScreen(viewModel: _viewModel()),
);

void main() {
  group('LoginScreen', () {
    testWidgets('shows the title and the register link', (tester) async {
      tester.view.physicalSize = Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host());

      expect(find.text('FIFA WORLD CUP 26™'), findsOneWidget);
      expect(find.text('Não tem conta?  Criar conta →'), findsOneWidget);
    });

    testWidgets('wraps the content in a scroll view', (tester) async {
      tester.view.physicalSize = Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host());

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('keeps the register link reachable on a short screen', (
      tester,
    ) async {
      tester.view.physicalSize = Size(390, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host());
      await tester.scrollUntilVisible(
        find.text('Não tem conta?  Criar conta →'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Não tem conta?  Criar conta →'), findsOneWidget);
    });
  });
}
