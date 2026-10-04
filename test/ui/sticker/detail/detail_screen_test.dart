import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/core/exceptions/app_exception.dart';
import 'package:wc_2026_mobile/core/result.dart';
import 'package:wc_2026_mobile/data/repositories/album/album_repository.dart';
import 'package:wc_2026_mobile/domain/models/album/album.dart';
import 'package:wc_2026_mobile/domain/models/album/album_summary.dart';
import 'package:wc_2026_mobile/domain/models/album/recent_sticker.dart';
import 'package:wc_2026_mobile/domain/models/album/sticker_status.dart';
import 'package:wc_2026_mobile/routing/routes.dart';
import 'package:wc_2026_mobile/ui/album/widgets/hero_card.dart';
import 'package:wc_2026_mobile/ui/core/theme/theme.dart';
import 'package:wc_2026_mobile/ui/sticker/detail/detail_screen.dart';
import 'package:wc_2026_mobile/ui/sticker/detail/detail_view_model.dart';
import 'package:wc_2026_mobile/ui/sticker/detail/widgets/backdrop.dart';
import 'package:wc_2026_mobile/ui/sticker/detail/widgets/delete_action.dart';
import 'package:wc_2026_mobile/ui/sticker/detail/widgets/delete_dialog.dart';
import 'package:wc_2026_mobile/ui/sticker/detail/widgets/quantity_counter.dart';
import 'package:wc_2026_mobile/ui/sticker/detail/widgets/status_banner.dart';
import 'package:wc_2026_mobile/ui/sticker/detail/widgets/top_bar.dart';
import 'package:wc_2026_mobile/ui/sticker/widgets/sticker_action_button.dart';

class _FakeAlbumRepository implements AlbumRepository {
  Result<void> registerResult = Result.done;
  Result<void> updateResult = Result.done;
  Result<void> removeResult = Result.done;
  Completer<void>? gate;

  final registered = <({String code, int quantity})>[];
  final updated = <({String code, int quantity})>[];
  final removed = <String>[];

  @override
  Future<Result<void>> registerSticker({
    required String code,
    required int quantity,
  }) async {
    registered.add((code: code, quantity: quantity));
    await gate?.future;
    return registerResult;
  }

  @override
  Future<Result<void>> updateStickerQuantity({
    required String code,
    required int quantity,
  }) async {
    updated.add((code: code, quantity: quantity));
    await gate?.future;
    return updateResult;
  }

  @override
  Future<Result<void>> removeSticker(String code) async {
    removed.add(code);
    await gate?.future;
    return removeResult;
  }

  @override
  Future<Result<Album>> getAlbum({StickerStatus? status, String? team}) async =>
      Result.ok(const Album(teams: [], loose: []));

  @override
  Future<Result<AlbumSummary>> getSummary() async =>
      Result.ok(const AlbumSummary(total: 0, missing: 0, repeated: 0));

  @override
  Future<Result<List<RecentSticker>>> getRecentStickers() async =>
      Result.ok(const []);
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

DetailArgs _withCount(int count) => (
  code: _args.code,
  number: _args.number,
  team: _args.team,
  country: _args.country,
  teamColor: _args.teamColor,
  rare: _args.rare,
  count: count,
);

late _FakeAlbumRepository _repository;
late DetailViewModel _viewModel;
var _viewModelDisposed = false;

void _build(DetailArgs sticker) {
  _viewModel = DetailViewModel(
    albumRepository: _repository,
    code: sticker.code,
    count: sticker.count,
  );
}

Widget _host({
  EdgeInsets padding = EdgeInsets.zero,
  DetailArgs sticker = _args,
}) {
  _build(sticker);

  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(padding: padding, textScaler: TextScaler.linear(0.8)),
      child: child!,
    ),
    home: DetailScreen(sticker: sticker, viewModel: _viewModel),
  );
}

GoRouter _router({required String initialLocation, DetailArgs? sticker}) {
  final args = sticker ?? _args;
  _build(args);

  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: Routes.album, builder: (_, _) => Text('album page')),
      GoRoute(
        path: Routes.stickerPath,
        builder: (_, _) => DetailScreen(sticker: args, viewModel: _viewModel),
      ),
    ],
  );
}

Widget _app(GoRouter router) => MaterialApp.router(
  routerConfig: router,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(0.8)),
    child: child!,
  ),
);

void _useScreen(WidgetTester tester, {double height = 1800}) {
  tester.view.physicalSize = Size(390, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<Future<bool?>> _openDetail(
  WidgetTester tester, {
  DetailArgs? sticker,
}) async {
  _useScreen(tester);
  final appRouter = _router(
    initialLocation: Routes.album,
    sticker: sticker,
  );

  await tester.pumpWidget(_app(appRouter));
  final result = appRouter.push<bool>(Routes.sticker('BRA-1'));
  await tester.pumpAndSettle();
  return result;
}

StickerActionButton _saveButton(WidgetTester tester) =>
    tester.widget<StickerActionButton>(find.byType(StickerActionButton));

void main() {
  setUp(() {
    _repository = _FakeAlbumRepository();
    _viewModelDisposed = false;
  });

  tearDown(() {
    if (!_viewModelDisposed) _viewModel.dispose();
  });

  group('DetailScreen layout', () {
    testWidgets('shows the backdrop, the top bar and the card', (
      tester,
    ) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      expect(find.byType(Backdrop), findsOneWidget);
      expect(find.byType(TopBar), findsOneWidget);
      expect(find.byType(HeroCard), findsOneWidget);
    });

    testWidgets('keeps the sticker it was opened with', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      expect(
        tester.widget<DetailScreen>(find.byType(DetailScreen)).sticker,
        _args,
      );
    });

    testWidgets('shows the sticker number with a fixed total', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      final bar = tester.widget<TopBar>(find.byType(TopBar));

      expect(bar.number, 1);
      expect(bar.total, 980);
      expect(find.text('01 / 980'), findsOneWidget);
    });

    testWidgets('shows the card with the data of the sticker', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      final card = tester.widget<HeroCard>(find.byType(HeroCard));

      expect(card.number, 1);
      expect(card.team, 'Brazil');
      expect(card.country, 'BRA');
      expect(card.teamColor, Color(0xFFFFDF00));
      expect(card.rare, isFalse);
    });

    testWidgets('uses the dark color as the page background', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        AppColors.ink,
      );
    });

    testWidgets('asks for light status bar icons', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find
            .descendant(
              of: find.byType(DetailScreen),
              matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
            )
            .first,
      );

      expect(region.value, SystemUiOverlayStyle.light);
    });

    testWidgets('keeps the top bar below the status bar', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host(padding: EdgeInsets.only(top: 40)));

      expect(tester.getTopLeft(find.byType(TopBar)).dy, 40);
    });

    testWidgets('stacks the blocks from the card to the counter', (
      tester,
    ) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      final tops = [
        for (final finder in [
          find.byType(HeroCard),
          find.byType(StatusBanner),
          find.byType(StickerActionButton),
          find.byType(DeleteAction),
          find.byType(QuantityCounter),
        ])
          tester.getTopLeft(finder).dy,
      ];

      expect(tops, [...tops]..sort());
      expect(tops.toSet(), hasLength(5));
    });

    testWidgets('scrolls to reach the counter on a short screen', (
      tester,
    ) async {
      _useScreen(tester, height: 700);

      await tester.pumpWidget(_host());

      final scrollable = find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Scrollable),
      );

      expect(
        tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
        greaterThan(0),
      );

      await tester.scrollUntilVisible(
        find.byType(QuantityCounter),
        100,
        scrollable: scrollable,
      );

      expect(find.byType(QuantityCounter), findsOneWidget);
    });
  });

  group('DetailScreen state', () {
    testWidgets('shows the banner and the counter with the count', (
      tester,
    ) async {
      _useScreen(tester);

      await tester.pumpWidget(_host(sticker: _withCount(5)));

      expect(tester.widget<StatusBanner>(find.byType(StatusBanner)).count, 5);
      expect(
        tester.widget<QuantityCounter>(find.byType(QuantityCounter)).count,
        5,
      );
    });

    testWidgets('paints the backdrop and the card as collected', (
      tester,
    ) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      expect(tester.widget<Backdrop>(find.byType(Backdrop)).collected, isTrue);
      expect(tester.widget<HeroCard>(find.byType(HeroCard)).collected, isTrue);
    });

    testWidgets('paints the backdrop and the card as missing', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host(sticker: _withCount(0)));

      expect(tester.widget<Backdrop>(find.byType(Backdrop)).collected, isFalse);
      expect(tester.widget<HeroCard>(find.byType(HeroCard)).collected, isFalse);
      expect(find.text('VOCÊ NÃO TEM ESSA FIGURINHA'), findsOneWidget);
    });

    testWidgets('adds a copy when the plus button is tapped', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(_viewModel.count, 3);
      expect(tester.widget<StatusBanner>(find.byType(StatusBanner)).count, 3);
      expect(
        tester.widget<QuantityCounter>(find.byType(QuantityCounter)).count,
        3,
      );
    });

    testWidgets('removes a copy when the minus button is tapped', (
      tester,
    ) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();

      expect(_viewModel.count, 1);
    });

    testWidgets('does not go below one copy', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host(sticker: _withCount(1)));
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();

      expect(_viewModel.count, 1);
    });

    testWidgets('keeps a missing sticker at zero with the minus button', (
      tester,
    ) async {
      _useScreen(tester);

      await tester.pumpWidget(_host(sticker: _withCount(0)));
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();

      expect(_viewModel.count, 0);
    });

    testWidgets('marks a missing sticker as collected with the plus button', (
      tester,
    ) async {
      _useScreen(tester);

      await tester.pumpWidget(_host(sticker: _withCount(0)));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(tester.widget<Backdrop>(find.byType(Backdrop)).collected, isTrue);
      expect(tester.widget<HeroCard>(find.byType(HeroCard)).collected, isTrue);
    });

    testWidgets('has no upper limit on the plus button', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host(sticker: _withCount(99)));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(_viewModel.count, 100);
    });
  });

  group('DetailScreen primary button', () {
    testWidgets('says save when the sticker is already in the album', (
      tester,
    ) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      expect(find.text('SALVAR'), findsOneWidget);
      expect(_saveButton(tester).icon, Icons.check_rounded);
    });

    testWidgets('says it has the sticker when it is missing', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host(sticker: _withCount(0)));

      expect(find.text('TENHO ESTA FIGURINHA'), findsOneWidget);
      expect(_saveButton(tester).icon, Icons.add_rounded);
    });

    testWidgets('keeps the label until the sticker is stored', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host(sticker: _withCount(0)));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(find.text('COLAR NO ALBUM'), findsOneWidget);
      expect(_saveButton(tester).icon, Icons.check_rounded);
    });

    testWidgets('is enabled when nothing is running', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      expect(_saveButton(tester).onPressed, isNotNull);
    });
  });

  group('DetailScreen save', () {
    testWidgets('saves the count and leaves reporting a change', (
      tester,
    ) async {
      final result = await _openDetail(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      await tester.tap(find.text('SALVAR'));
      await tester.pumpAndSettle();

      expect(_repository.updated, [(code: 'BRA-1', quantity: 3)]);
      expect(find.byType(DetailScreen), findsNothing);
      expect(find.text('album page'), findsOneWidget);
      expect(await result, isTrue);
    });

    testWidgets('registers a missing sticker with one copy', (tester) async {
      final result = await _openDetail(tester, sticker: _withCount(0));

      await tester.tap(find.text('TENHO ESTA FIGURINHA'));
      await tester.pumpAndSettle();

      expect(_repository.registered, [(code: 'BRA-1', quantity: 1)]);
      expect(_repository.updated, isEmpty);
      expect(await result, isTrue);
    });

    testWidgets('shows the error and stays on the screen when it fails', (
      tester,
    ) async {
      _repository.updateResult = Result.error(const NetworkException());
      await _openDetail(tester);

      await tester.tap(find.text('SALVAR'));
      await tester.pumpAndSettle();

      expect(find.byType(DetailScreen), findsOneWidget);
      expect(
        find.text('Sem conexão. Verifique sua internet e tente novamente.'),
        findsOneWidget,
      );
    });

    testWidgets('keeps the count when the save fails', (tester) async {
      _repository.updateResult = Result.error(const ServerException());
      await _openDetail(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      await tester.tap(find.text('SALVAR'));
      await tester.pumpAndSettle();

      expect(_viewModel.count, 3);
    });

    testWidgets('keeps the button enabled after a failed save', (
      tester,
    ) async {
      _repository.updateResult = Result.error(const NetworkException());
      await _openDetail(tester);

      await tester.tap(find.text('SALVAR'));
      await tester.pumpAndSettle();

      expect(_saveButton(tester).onPressed, isNotNull);
    });

    testWidgets('lets the user retry after a failed save', (tester) async {
      _repository.updateResult = Result.error(const NetworkException());
      final result = await _openDetail(tester);

      await tester.tap(find.text('SALVAR'));
      await tester.pumpAndSettle();
      expect(find.byType(DetailScreen), findsOneWidget);

      _repository.updateResult = Result.done;
      await tester.tap(find.text('SALVAR'));
      await tester.pumpAndSettle();

      expect(_repository.updated, hasLength(2));
      expect(find.byType(DetailScreen), findsNothing);
      expect(await result, isTrue);
    });

    testWidgets('does not disable the button while the save is running', (
      tester,
    ) async {
      _repository.gate = Completer<void>();
      await _openDetail(tester);

      await tester.tap(find.text('SALVAR'));
      await tester.pump();

      expect(_viewModel.busy, isTrue);
      expect(_saveButton(tester).onPressed, isNotNull);

      _repository.gate!.complete();
      await tester.pumpAndSettle();
    });
  });

  group('DetailScreen delete', () {
    testWidgets('shows the delete action for a sticker in the album', (
      tester,
    ) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      expect(find.byType(DeleteAction), findsOneWidget);
    });

    testWidgets('hides the delete action for a missing sticker', (
      tester,
    ) async {
      _useScreen(tester);

      await tester.pumpWidget(_host(sticker: _withCount(0)));

      expect(find.byType(DeleteAction), findsNothing);
    });

    testWidgets('asks for confirmation before deleting', (tester) async {
      await _openDetail(tester);

      await tester.tap(find.text('EXCLUIR FIGURINHA'));
      await tester.pumpAndSettle();

      expect(find.byType(DeleteDialog), findsOneWidget);
      expect(find.text('EXCLUIR BRA - 01?'), findsOneWidget);
      expect(_repository.removed, isEmpty);
    });

    testWidgets('keeps the sticker when the deletion is cancelled', (
      tester,
    ) async {
      await _openDetail(tester);

      await tester.tap(find.text('EXCLUIR FIGURINHA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CANCELAR'));
      await tester.pumpAndSettle();

      expect(find.byType(DeleteDialog), findsNothing);
      expect(find.byType(DetailScreen), findsOneWidget);
      expect(_repository.removed, isEmpty);
    });

    testWidgets('deletes and leaves reporting a change when confirmed', (
      tester,
    ) async {
      final result = await _openDetail(tester);

      await tester.tap(find.text('EXCLUIR FIGURINHA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('EXCLUIR'));
      await tester.pumpAndSettle();

      expect(_repository.removed, ['BRA-1']);
      expect(find.byType(DetailScreen), findsNothing);
      expect(find.text('album page'), findsOneWidget);
      expect(await result, isTrue);
    });

    testWidgets('shows the error and stays when the deletion fails', (
      tester,
    ) async {
      _repository.removeResult = Result.error(const NotFoundException());
      await _openDetail(tester);

      await tester.tap(find.text('EXCLUIR FIGURINHA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('EXCLUIR'));
      await tester.pumpAndSettle();

      expect(find.byType(DetailScreen), findsOneWidget);
      expect(
        find.text('Não encontramos o que você procurou.'),
        findsOneWidget,
      );
      expect(_viewModel.inAlbum, isTrue);
    });
  });

  group('DetailScreen back', () {
    testWidgets('closes the detail and reports no change when it can pop', (
      tester,
    ) async {
      final result = await _openDetail(tester);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(DetailScreen), findsNothing);
      expect(find.text('album page'), findsOneWidget);
      expect(await result, isFalse);
    });

    testWidgets('goes to the album when there is nothing to go back to', (
      tester,
    ) async {
      _useScreen(tester);
      final appRouter = _router(initialLocation: Routes.sticker('BRA-1'));

      await tester.pumpWidget(_app(appRouter));
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(DetailScreen), findsNothing);
      expect(find.text('album page'), findsOneWidget);
    });

    testWidgets('does not touch the repository when leaving', (tester) async {
      await _openDetail(tester);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(_repository.updated, isEmpty);
      expect(_repository.registered, isEmpty);
      expect(_repository.removed, isEmpty);
    });
  });
}
