import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/core/auth/auth_session_notifier.dart';
import 'package:wc_2026_mobile/core/exceptions/app_exception.dart';
import 'package:wc_2026_mobile/core/result.dart';
import 'package:wc_2026_mobile/data/repositories/album/album_repository.dart';
import 'package:wc_2026_mobile/data/repositories/auth_session/auth_session_repository.dart';
import 'package:wc_2026_mobile/domain/models/album/album.dart';
import 'package:wc_2026_mobile/domain/models/album/album_summary.dart';
import 'package:wc_2026_mobile/domain/models/album/recent_sticker.dart';
import 'package:wc_2026_mobile/domain/models/album/sticker_status.dart';
import 'package:wc_2026_mobile/domain/models/auth_session.dart';
import 'package:wc_2026_mobile/domain/models/team/team.dart';
import 'package:wc_2026_mobile/domain/use_cases/auth/auth_logout_use_case.dart';
import 'package:wc_2026_mobile/domain/use_cases/auth/auth_restore_session_use_case.dart';
import 'package:wc_2026_mobile/routing/routes.dart';
import 'package:wc_2026_mobile/ui/core/share/app_loading.dart';
import 'package:wc_2026_mobile/ui/core/share/error_indicator.dart';
import 'package:wc_2026_mobile/ui/home/home_screen.dart';
import 'package:wc_2026_mobile/ui/home/home_view_model.dart';
import 'package:wc_2026_mobile/ui/home/widgets/album_hero.dart';
import 'package:wc_2026_mobile/ui/home/widgets/sticker_card.dart';

class _FakeAlbumRepository implements AlbumRepository {
  Result<AlbumSummary> summary = Result.ok(
    const AlbumSummary(total: 980, missing: 300, repeated: 12),
  );
  Result<List<RecentSticker>> recent = Result.ok(const []);
  Completer<void>? gate;
  var summaryCalls = 0;
  var recentCalls = 0;

  @override
  Future<Result<AlbumSummary>> getSummary() async {
    summaryCalls++;
    await gate?.future;
    return summary;
  }

  @override
  Future<Result<List<RecentSticker>>> getRecentStickers() async {
    recentCalls++;
    await gate?.future;
    return recent;
  }

  @override
  Future<Result<Album>> getAlbum({StickerStatus? status, String? team}) async =>
      Result.ok(const Album(teams: [], loose: []));

  @override
  Future<Result<void>> registerSticker({
    required String code,
    required int quantity,
  }) async => Result.done;

  @override
  Future<Result<void>> updateStickerQuantity({
    required String code,
    required int quantity,
  }) async => Result.done;

  @override
  Future<Result<void>> removeSticker(String code) async => Result.done;
}

class _FakeAuthSessionRepository implements AuthSessionRepository {
  @override
  Future<Result<void>> delete() async => Result.done;

  @override
  Future<Result<AuthSession?>> fetch() async => Result.ok(null);

  @override
  Future<Result<void>> save(AuthSession session) async => Result.done;
}

const _brazil = Team(
  code: 'BRA',
  name: 'Brazil',
  flagUrl: '/flags/bra.png',
  primaryColor: 0xFFFFDF00,
);

late _FakeAlbumRepository _repository;
late HomeViewModel _viewModel;
late AuthSessionNotifier _session;

AuthSessionNotifier _buildSession() {
  final repository = _FakeAuthSessionRepository();
  final notifier = AuthSessionNotifier(
    authLogoutUseCase: AuthLogoutUseCase(authSessionRepository: repository),
    authRestoreSessionUseCase: AuthRestoreSessionUseCase(
      authSessionRepository: repository,
    ),
    sessionEnded: Stream<void>.empty(),
  );
  notifier.signedIn(
    const AuthSessionUser(name: 'Ada Lovelace', email: 'ada@mail.com'),
  );
  return notifier;
}

GoRouter _router() => GoRouter(
  initialLocation: Routes.home,
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (_, _) => HomeScreen(viewModel: _viewModel, session: _session),
    ),
    GoRoute(
      path: Routes.stickerRegister,
      builder: (context, _) => Column(
        children: [
          Text('register page'),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text('changed'),
          ),
          TextButton(
            onPressed: () => context.pop(false),
            child: Text('unchanged'),
          ),
        ],
      ),
    ),
  ],
);

Future<GoRouter> _openHome(WidgetTester tester) async {
  tester.view.physicalSize = Size(390, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final appRouter = _router();

  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: appRouter,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(0.6)),
        child: child!,
      ),
    ),
  );
  _viewModel.init();
  await tester.pump();
  await tester.pump();
  return appRouter;
}

void main() {
  setUp(() {
    _repository = _FakeAlbumRepository();
    _viewModel = HomeViewModel(albumRepository: _repository);
    _session = _buildSession();
  });

  tearDown(() {
    _viewModel.dispose();
    _session.dispose();
  });

  group('HomeScreen header', () {
    testWidgets('shows the initials and the name of the user', (tester) async {
      await _openHome(tester);

      expect(find.text('AL'), findsOneWidget);
      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('OLÁ COLECIONADOR'), findsOneWidget);
    });
  });

  group('HomeScreen summary', () {
    testWidgets('shows the album progress', (tester) async {
      await _openHome(tester);

      expect(find.byType(AlbumHero), findsOneWidget);
      expect(find.text('680 / 980 FIGURINHAS'), findsOneWidget);
      expect(find.text('69%'), findsOneWidget);
    });

    testWidgets('shows the repeated stickers', (tester) async {
      await _openHome(tester);

      expect(find.text('12 REPETIDAS'), findsOneWidget);
    });

    testWidgets('shows the loader while the data loads', (tester) async {
      _repository.gate = Completer<void>();

      await _openHome(tester);

      expect(find.byType(AppLoading), findsWidgets);
      expect(find.byType(AlbumHero), findsNothing);

      _repository.gate!.complete();
      await tester.pump();
      await tester.pump();
    });

    testWidgets('shows the error with retry when the summary fails', (
      tester,
    ) async {
      _repository.summary = Result.error(const NetworkException());

      await _openHome(tester);

      expect(find.byType(ErrorIndicator), findsOneWidget);
      expect(
        find.text('Sem conexão. Verifique sua internet e tente novamente.'),
        findsOneWidget,
      );
      expect(find.byType(AlbumHero), findsNothing);
    });

    testWidgets('loads the summary again when retrying', (tester) async {
      _repository.summary = Result.error(const ServerException());
      await _openHome(tester);

      _repository.summary = Result.ok(
        const AlbumSummary(total: 980, missing: 0, repeated: 0),
      );
      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();
      await tester.pump();

      expect(_repository.summaryCalls, 2);
      expect(find.text('980 / 980 FIGURINHAS'), findsOneWidget);
    });
  });

  group('HomeScreen recent stickers', () {
    testWidgets('shows the empty message when there are none', (tester) async {
      await _openHome(tester);

      expect(
        find.text('Você ainda não colou nenhum figurinha'),
        findsOneWidget,
      );
    });

    testWidgets('shows a card for each recent sticker', (tester) async {
      _repository.recent = Result.ok(const [
        RecentSticker(code: 'BRA-1', number: 1, repeated: 0, team: _brazil),
        RecentSticker(code: 'BRA-2', number: 2, repeated: 1, team: _brazil),
      ]);

      await _openHome(tester);

      final cards = tester
          .widgetList<StickerCard>(find.byType(StickerCard))
          .toList();

      expect(cards, hasLength(2));
      expect(cards.map((card) => card.number), [1, 2]);
      expect(cards.map((card) => card.label), ['BRA', 'BRA']);
    });

    testWidgets('shows the error when the recent stickers fail', (
      tester,
    ) async {
      _repository.recent = Result.error(const ServerException());

      await _openHome(tester);

      expect(find.byType(ErrorIndicator), findsOneWidget);
      expect(find.byType(AlbumHero), findsOneWidget);
    });
  });

  group('HomeScreen actions', () {
    testWidgets('opens the register screen when adding a sticker', (
      tester,
    ) async {
      await _openHome(tester);

      await tester.tap(find.text('ADICIONAR'));
      await tester.pumpAndSettle();

      expect(find.text('register page'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('comes back to the home from the register screen', (
      tester,
    ) async {
      final appRouter = await _openHome(tester);

      await tester.tap(find.text('ADICIONAR'));
      await tester.pumpAndSettle();
      appRouter.pop();
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('reloads the data when the register screen reports a change', (
      tester,
    ) async {
      await _openHome(tester);

      _repository.summary = Result.ok(
        const AlbumSummary(total: 980, missing: 100, repeated: 5),
      );
      await tester.tap(find.text('ADICIONAR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('changed'));
      await tester.pumpAndSettle();

      expect(_repository.summaryCalls, 2);
      expect(_repository.recentCalls, 2);
      expect(find.text('880 / 980 FIGURINHAS'), findsOneWidget);
    });

    testWidgets('does not reload when the register screen reports no change', (
      tester,
    ) async {
      await _openHome(tester);

      await tester.tap(find.text('ADICIONAR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('unchanged'));
      await tester.pumpAndSettle();

      expect(_repository.summaryCalls, 1);
      expect(_repository.recentCalls, 1);
    });

    testWidgets(
      'does not reload when the register screen closes without a result',
      (
        tester,
      ) async {
        final appRouter = await _openHome(tester);

        await tester.tap(find.text('ADICIONAR'));
        await tester.pumpAndSettle();
        appRouter.pop();
        await tester.pumpAndSettle();

        expect(_repository.summaryCalls, 1);
        expect(_repository.recentCalls, 1);
      },
    );

    testWidgets('can open the register screen more than once', (tester) async {
      await _openHome(tester);

      await tester.tap(find.text('ADICIONAR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('changed'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ADICIONAR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('changed'));
      await tester.pumpAndSettle();

      expect(_repository.summaryCalls, 3);
    });

    testWidgets('does nothing when trading for now', (tester) async {
      await _openHome(tester);

      await tester.tap(find.text('TROCAR'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('register page'), findsNothing);
    });

    testWidgets('reloads the summary and the recent stickers on refresh', (
      tester,
    ) async {
      await _openHome(tester);

      unawaited(
        tester
            .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
            .show(),
      );
      await tester.pump();
      await tester.pump(Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(_repository.summaryCalls, 2);
      expect(_repository.recentCalls, 2);
    });
  });
}
