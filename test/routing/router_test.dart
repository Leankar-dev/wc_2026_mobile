import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:wc_2026_mobile/core/auth/auth_session_notifier.dart';
import 'package:wc_2026_mobile/core/result.dart';
import 'package:wc_2026_mobile/data/repositories/auth_session/auth_session_repository.dart';
import 'package:wc_2026_mobile/domain/models/auth_session.dart';
import 'package:wc_2026_mobile/domain/use_cases/auth/auth_logout_use_case.dart';
import 'package:wc_2026_mobile/domain/use_cases/auth/auth_restore_session_use_case.dart';
import 'package:wc_2026_mobile/routing/router.dart';
import 'package:wc_2026_mobile/routing/routes.dart';
import 'package:wc_2026_mobile/ui/sticker/detail/detail_screen.dart';

class _FakeAuthSessionRepository implements AuthSessionRepository {
  @override
  Future<Result<void>> delete() async => Result.done;

  @override
  Future<Result<AuthSession?>> fetch() async => Result.ok(
    const AuthSession(
      token: 'abc',
      user: AuthSessionUser(name: 'Ada', email: 'ada@mail.com'),
    ),
  );

  @override
  Future<Result<void>> save(AuthSession session) async => Result.done;
}

const DetailArgs _args = (
  code: 'BRA-1',
  number: 1,
  team: 'Brazil',
  country: 'BRA',
  teamColor: Color(0xFFFFDF00),
  rare: false,
  count: 2,
);

AuthSessionNotifier _signedInNotifier() {
  final repository = _FakeAuthSessionRepository();
  return AuthSessionNotifier(
    authLogoutUseCase: AuthLogoutUseCase(authSessionRepository: repository),
    authRestoreSessionUseCase: AuthRestoreSessionUseCase(
      authSessionRepository: repository,
    ),
    sessionEnded: Stream<void>.empty(),
  );
}

Future<GoRouter> _openApp(
  WidgetTester tester,
  AuthSessionNotifier notifier,
) async {
  tester.view.physicalSize = Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final appRouter = router(notifier);

  await tester.pumpWidget(
    ChangeNotifierProvider<AuthSessionNotifier>.value(
      value: notifier,
      child: MaterialApp.router(
        routerConfig: appRouter,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(0.8)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pump();
  return appRouter;
}

void main() {
  group('router sticker detail route', () {
    testWidgets('opens the detail screen with the sticker it receives', (
      tester,
    ) async {
      final notifier = _signedInNotifier();
      final appRouter = await _openApp(tester, notifier);

      appRouter.go(Routes.sticker('BRA-1'), extra: _args);
      await tester.pump();
      await tester.pump();

      final screen = tester.widget<DetailScreen>(find.byType(DetailScreen));

      expect(screen.sticker, _args);
      expect(find.byType(Placeholder), findsOneWidget);

      notifier.dispose();
    });

    testWidgets('fails when the detail is opened without the sticker', (
      tester,
    ) async {
      final notifier = _signedInNotifier();
      final appRouter = await _openApp(tester, notifier);

      appRouter.go(Routes.sticker('BRA-1'));
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isA<TypeError>());

      notifier.dispose();
    });
  });
}
