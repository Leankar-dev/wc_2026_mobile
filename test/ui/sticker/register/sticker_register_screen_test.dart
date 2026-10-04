import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/core/exceptions/app_exception.dart';
import 'package:wc_2026_mobile/core/result.dart';
import 'package:wc_2026_mobile/data/repositories/album/album_repository.dart';
import 'package:wc_2026_mobile/data/repositories/team/team_repository.dart';
import 'package:wc_2026_mobile/domain/models/album/album.dart';
import 'package:wc_2026_mobile/domain/models/album/album_summary.dart';
import 'package:wc_2026_mobile/domain/models/album/recent_sticker.dart';
import 'package:wc_2026_mobile/domain/models/album/sticker_status.dart';
import 'package:wc_2026_mobile/domain/models/team/team.dart';
import 'package:wc_2026_mobile/routing/routes.dart';
import 'package:wc_2026_mobile/ui/core/theme/theme.dart';
import 'package:wc_2026_mobile/ui/sticker/register/sticker_register_screen.dart';
import 'package:wc_2026_mobile/ui/sticker/register/sticker_register_view_model.dart';
import 'package:wc_2026_mobile/ui/sticker/register/widgets/code_field.dart';
import 'package:wc_2026_mobile/ui/sticker/register/widgets/header.dart';
import 'package:wc_2026_mobile/ui/sticker/register/widgets/hint_banner.dart';
import 'package:wc_2026_mobile/ui/sticker/register/widgets/keypad.dart';
import 'package:wc_2026_mobile/ui/sticker/register/widgets/preview_card.dart';
import 'package:wc_2026_mobile/ui/sticker/widgets/sticker_action_button.dart';

class _FakeAlbumRepository implements AlbumRepository {
  Result<void> registerResult = Result.done;
  Completer<void>? gate;
  final registered = <({String code, int quantity})>[];

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
  }) async => Result.done;

  @override
  Future<Result<void>> removeSticker(String code) async => Result.done;

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

class _FakeTeamRepository implements TeamRepository {
  @override
  Future<Result<List<Team>>> getTeams() async => Result.ok(const [
    Team(
      code: 'BRA',
      name: 'Brazil',
      flagUrl: '/flags/bra.png',
      primaryColor: 0xFFFFDF00,
    ),
    Team(
      code: 'ARG',
      name: 'Argentina',
      flagUrl: '/flags/arg.png',
      primaryColor: 0xFF6CACE4,
    ),
  ]);
}

late _FakeAlbumRepository _albums;
late StickerRegisterViewModel _viewModel;

Widget _scaled(BuildContext context, Widget? child) => MediaQuery(
  data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(0.8)),
  child: child!,
);

void _useScreen(
  WidgetTester tester, {
  double height = 1400,
  double width = 390,
}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _open(
  WidgetTester tester, {
  double height = 1400,
  double width = 390,
}) async {
  _useScreen(tester, height: height, width: width);
  await tester.pumpWidget(
    MaterialApp(
      builder: _scaled,
      home: StickerRegisterScreen(viewModel: _viewModel),
    ),
  );
  _viewModel.init();
  await tester.pump();
}

Future<void> _type(WidgetTester tester, String text) async {
  for (final key in text.split('')) {
    await tester.tap(
      find.descendant(of: find.byType(Keypad), matching: find.text(key)),
    );
    await tester.pump();
  }
}

Finder get _scrollable => find.descendant(
  of: find.byType(SingleChildScrollView),
  matching: find.byType(Scrollable),
);

StickerActionButton _button(WidgetTester tester) =>
    tester.widget<StickerActionButton>(find.byType(StickerActionButton));

Keypad _keypad(WidgetTester tester) =>
    tester.widget<Keypad>(find.byType(Keypad));

void main() {
  setUp(() {
    _albums = _FakeAlbumRepository();
    _viewModel = StickerRegisterViewModel(
      albumRepository: _albums,
      teamRepository: _FakeTeamRepository(),
    );
  });

  tearDown(() => _viewModel.dispose());

  group('StickerRegisterScreen layout', () {
    testWidgets('shows the header with the title', (tester) async {
      await _open(tester);

      expect(find.byType(Header), findsOneWidget);
      expect(find.text('ADICIONAR'), findsOneWidget);
      expect(find.text('FIGURINHA'), findsOneWidget);
    });

    testWidgets('keeps the header fixed outside the scroll view', (
      tester,
    ) async {
      await _open(tester);

      expect(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Header),
        ),
        findsNothing,
      );
    });

    testWidgets('asks for light status bar icons', (tester) async {
      await _open(tester);

      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find
            .descendant(
              of: find.byType(StickerRegisterScreen),
              matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
            )
            .first,
      );

      expect(region.value, SystemUiOverlayStyle.light);
    });

    testWidgets('shows the title of the code', (tester) async {
      await _open(tester);

      expect(find.text('CÓDIGO DA FIGURINHA'), findsOneWidget);
    });

    testWidgets('shows a code field with five boxes', (tester) async {
      await _open(tester);

      final field = tester.widget<CodeField>(find.byType(CodeField));

      expect(field.length, 5);
      expect(field.letters, 3);
      expect(field.code, isEmpty);
    });

    testWidgets('shows a single keypad starting with the letters', (
      tester,
    ) async {
      await _open(tester);

      expect(find.byType(Keypad), findsOneWidget);
      expect(_keypad(tester).letters, isTrue);
    });

    testWidgets('tells the user to type three letters and two numbers', (
      tester,
    ) async {
      await _open(tester);

      expect(find.text('DIGITE 3 LETRAS DO TIME + 2 NÚMEROS'), findsOneWidget);
      expect(find.text('DIGITE 3 LETRAS DO TIME + 3 NÚMEROS'), findsNothing);
    });

    testWidgets('waits for the code in the preview', (tester) async {
      await _open(tester);

      expect(find.text('SEM TIME'), findsOneWidget);
      expect(find.text('DIGITE O CÓDIGO'), findsOneWidget);
    });

    testWidgets('shows the register button disabled', (tester) async {
      await _open(tester);

      expect(_button(tester).label, 'CADASTRAR FIGURINHA');
      expect(_button(tester).icon, Icons.arrow_forward_rounded);
      expect(_button(tester).onPressed, isNull);
    });

    testWidgets('does not glow around the disabled button', (tester) async {
      await _open(tester);

      final glow = tester
          .widgetList<DecoratedBox>(
            find.ancestor(
              of: find.byType(StickerActionButton),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((box) => box.decoration)
          .whereType<ShapeDecoration>()
          .first;

      expect(glow.shadows, isNull);
    });
  });

  group('StickerRegisterScreen typing', () {
    testWidgets('shows the typed letters in the field', (tester) async {
      await _open(tester);

      await _type(tester, 'BR');

      expect(
        tester.widget<CodeField>(find.byType(CodeField)).code,
        'BR',
      );
      expect(_viewModel.code, 'BR');
    });

    testWidgets('switches to the digits after three letters', (tester) async {
      await _open(tester);

      await _type(tester, 'BRA');

      expect(_keypad(tester).letters, isFalse);
      expect(
        find.descendant(of: find.byType(Keypad), matching: find.text('0')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byType(Keypad), matching: find.text('V')),
        findsNothing,
      );
    });

    testWidgets('goes back to the letters when a letter is erased', (
      tester,
    ) async {
      await _open(tester);
      await _type(tester, 'BRA');

      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();

      expect(_keypad(tester).letters, isTrue);
      expect(_viewModel.code, 'BR');
    });

    testWidgets('keeps the digits while the number is erased', (tester) async {
      await _open(tester);
      await _type(tester, 'BRA1');

      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();

      expect(_keypad(tester).letters, isFalse);
      expect(_viewModel.code, 'BRA');
    });

    testWidgets('can type the letter V', (tester) async {
      await _open(tester);

      await _type(tester, 'V');

      expect(_viewModel.code, 'V');
    });

    testWidgets('stops accepting keys when the code is complete', (
      tester,
    ) async {
      await _open(tester);
      await _type(tester, 'BRA01');

      await tester.tap(
        find.descendant(of: find.byType(Keypad), matching: find.text('5')),
      );
      await tester.pump();

      expect(_viewModel.code, 'BRA01');
    });

    testWidgets('identifies the sticker when the code is complete', (
      tester,
    ) async {
      await _open(tester);

      await _type(tester, 'BRA01');

      expect(find.text('BRAZIL'), findsOneWidget);
      expect(find.text('SELEÇÃO'), findsOneWidget);
      expect(find.text('BRA – 01'), findsOneWidget);
      expect(find.text('ENCONTRADA:  BRA – 01 · '), findsOneWidget);
      expect(find.text(' BRAZIL'), findsOneWidget);
    });

    testWidgets('identifies a special sticker with a star', (tester) async {
      await _open(tester);

      await _type(tester, 'FWC03');

      expect(find.text('ESPECIAL'), findsWidgets);
      expect(find.byIcon(Icons.star_rounded), findsWidgets);
      expect(find.text('FWC – 03'), findsWidgets);
    });

    testWidgets('does not identify an unknown team', (tester) async {
      await _open(tester);

      await _type(tester, 'XYZ05');

      expect(find.text('SEM TIME'), findsOneWidget);
      expect(find.text('DIGITE 3 LETRAS DO TIME + 2 NÚMEROS'), findsOneWidget);
      expect(_button(tester).onPressed, isNull);
    });

    testWidgets('does not identify the number zero', (tester) async {
      await _open(tester);

      await _type(tester, 'BRA00');

      expect(find.text('SEM TIME'), findsOneWidget);
      expect(_button(tester).onPressed, isNull);
    });

    testWidgets('does not identify a number above twenty', (tester) async {
      await _open(tester);

      await _type(tester, 'BRA21');

      expect(find.text('SEM TIME'), findsOneWidget);
      expect(_button(tester).onPressed, isNull);
    });

    testWidgets('keeps the button disabled while the code is incomplete', (
      tester,
    ) async {
      await _open(tester);

      await _type(tester, 'BRA0');

      expect(_button(tester).onPressed, isNull);
    });

    testWidgets('enables the button with a glow when it is identified', (
      tester,
    ) async {
      await _open(tester);

      await _type(tester, 'BRA01');

      expect(_button(tester).onPressed, isNotNull);

      final glow = tester
          .widgetList<DecoratedBox>(
            find.ancestor(
              of: find.byType(StickerActionButton),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((box) => box.decoration)
          .whereType<ShapeDecoration>()
          .first;

      expect(glow.shadows, AppShadows.fabGlow);
    });

    testWidgets('shows the hint with the found team', (tester) async {
      await _open(tester);

      await _type(tester, 'ARG10');

      expect(find.byType(HintBanner), findsOneWidget);
      expect(find.text('ENCONTRADA:  ARG – 10 · '), findsOneWidget);
    });

    testWidgets('shows the preview of the identified team', (tester) async {
      await _open(tester);

      await _type(tester, 'ARG10');

      expect(find.text('ARGENTINA'), findsOneWidget);
      expect(find.byType(PreviewCard), findsOneWidget);
    });
  });

  group('StickerRegisterScreen register', () {
    testWidgets('registers the identified sticker', (tester) async {
      await _open(tester);
      await _type(tester, 'BRA01');

      await tester.tap(find.text('CADASTRAR FIGURINHA'));
      await tester.pump();
      await tester.pump();

      expect(_albums.registered, [(code: 'BRA-1', quantity: 1)]);
    });

    testWidgets('confirms the registration in a snack bar', (tester) async {
      await _open(tester);
      await _type(tester, 'BRA01');

      await tester.tap(find.text('CADASTRAR FIGURINHA'));
      await tester.pump();
      await tester.pump();

      expect(find.text('BRA – 01 colada no álbum'), findsOneWidget);
      expect(find.text('BRA – 01 colada no albúm'), findsNothing);
    });

    testWidgets('clears the code and goes back to the letters', (tester) async {
      await _open(tester);
      await _type(tester, 'BRA01');

      await tester.tap(find.text('CADASTRAR FIGURINHA'));
      await tester.pump();
      await tester.pump();

      expect(_viewModel.code, isEmpty);
      expect(_keypad(tester).letters, isTrue);
      expect(find.text('SEM TIME'), findsOneWidget);
      expect(_button(tester).onPressed, isNull);
    });

    testWidgets('stays on the screen to register another sticker', (
      tester,
    ) async {
      await _open(tester);
      await _type(tester, 'BRA01');

      await tester.tap(find.text('CADASTRAR FIGURINHA'));
      await tester.pump();
      await tester.pump();
      await _type(tester, 'ARG02');
      await tester.tap(find.text('CADASTRAR FIGURINHA'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(StickerRegisterScreen), findsOneWidget);
      expect(_albums.registered, [
        (code: 'BRA-1', quantity: 1),
        (code: 'ARG-2', quantity: 1),
      ]);
    });

    testWidgets('shows the error and keeps the code when it fails', (
      tester,
    ) async {
      _albums.registerResult = Result.error(const NetworkException());
      await _open(tester);
      await _type(tester, 'BRA01');

      await tester.tap(find.text('CADASTRAR FIGURINHA'));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Sem conexão. Verifique sua internet e tente novamente.'),
        findsOneWidget,
      );
      expect(_viewModel.code, 'BRA01');
      expect(_button(tester).onPressed, isNotNull);
    });

    testWidgets('shows a generic error when the sticker already exists', (
      tester,
    ) async {
      _albums.registerResult = Result.error(const UnknownException());
      await _open(tester);
      await _type(tester, 'BRA01');

      await tester.tap(find.text('CADASTRAR FIGURINHA'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Algo deu errado. Tente novamente.'), findsOneWidget);
    });

    testWidgets('disables the button while the registration runs', (
      tester,
    ) async {
      _albums.gate = Completer<void>();
      await _open(tester);
      await _type(tester, 'BRA01');

      await tester.tap(find.text('CADASTRAR FIGURINHA'));
      await tester.pump();

      expect(_button(tester).onPressed, isNull);

      _albums.gate!.complete();
      await tester.pump();
      await tester.pump();
    });
  });

  group('StickerRegisterScreen scroll', () {
    testWidgets('does not scroll when the form fits', (tester) async {
      await _open(tester, height: 1400);

      final state = tester.state<ScrollableState>(_scrollable);

      expect(state.position.maxScrollExtent, 0);
    });

    testWidgets('scrolls only the form on a short screen', (tester) async {
      await _open(tester, height: 600);
      final before = tester.getTopLeft(find.byType(Header)).dy;

      await tester.drag(_scrollable, Offset(0, -300));
      await tester.pump();

      expect(tester.getTopLeft(find.byType(Header)).dy, before);
      expect(
        tester.state<ScrollableState>(_scrollable).position.maxScrollExtent,
        greaterThan(0),
      );
    });

    testWidgets('reaches the register button on a short screen', (
      tester,
    ) async {
      await _open(tester, height: 600);

      await tester.scrollUntilVisible(
        find.byType(StickerActionButton),
        100,
        scrollable: _scrollable,
      );

      expect(find.byType(StickerActionButton), findsOneWidget);
    });

    testWidgets('does not overflow on a narrow screen', (tester) async {
      await _open(tester, width: 320, height: 800);

      expect(tester.takeException(), isNull);
    });
  });

  group('StickerRegisterScreen back', () {
    GoRouter router({required String initialLocation}) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: Routes.home, builder: (_, _) => Text('home page')),
        GoRoute(
          path: Routes.stickerRegister,
          builder: (_, _) => StickerRegisterScreen(viewModel: _viewModel),
        ),
      ],
    );

    Future<GoRouter> openRouter(
      WidgetTester tester, {
      required String initialLocation,
    }) async {
      _useScreen(tester);
      final appRouter = router(initialLocation: initialLocation);

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter, builder: _scaled),
      );
      _viewModel.init();
      await tester.pump();
      return appRouter;
    }

    testWidgets('closes reporting no change when nothing was registered', (
      tester,
    ) async {
      final appRouter = await openRouter(tester, initialLocation: Routes.home);
      final result = appRouter.push<bool>(Routes.stickerRegister);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('home page'), findsOneWidget);
      expect(await result, isFalse);
    });

    testWidgets('closes reporting a change after a registration', (
      tester,
    ) async {
      final appRouter = await openRouter(tester, initialLocation: Routes.home);
      final result = appRouter.push<bool>(Routes.stickerRegister);
      await tester.pumpAndSettle();
      await _type(tester, 'BRA01');
      await tester.tap(find.text('CADASTRAR FIGURINHA'));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(await result, isTrue);
    });

    testWidgets('goes to the home when there is nothing to go back to', (
      tester,
    ) async {
      await openRouter(tester, initialLocation: Routes.stickerRegister);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(StickerRegisterScreen), findsNothing);
      expect(find.text('home page'), findsOneWidget);
    });
  });
}
