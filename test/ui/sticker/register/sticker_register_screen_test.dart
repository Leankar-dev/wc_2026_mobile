import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wc_2026_mobile/routing/routes.dart';
import 'package:wc_2026_mobile/ui/core/theme/theme.dart';
import 'package:wc_2026_mobile/ui/sticker/register/sticker_register_screen.dart';
import 'package:wc_2026_mobile/ui/sticker/register/widgets/code_field.dart';
import 'package:wc_2026_mobile/ui/sticker/register/widgets/header.dart';
import 'package:wc_2026_mobile/ui/sticker/register/widgets/hint_banner.dart';
import 'package:wc_2026_mobile/ui/sticker/register/widgets/keypad.dart';
import 'package:wc_2026_mobile/ui/sticker/register/widgets/preview_card.dart';
import 'package:wc_2026_mobile/ui/sticker/widgets/sticker_action_button.dart';

Widget _scaled(BuildContext context, Widget? child) => MediaQuery(
  data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(0.8)),
  child: child!,
);

Widget _host() => MaterialApp(builder: _scaled, home: StickerRegisterScreen());

GoRouter _router({required String initialLocation}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: Routes.home, builder: (_, _) => Text('home page')),
    GoRoute(
      path: Routes.stickerRegister,
      builder: (_, _) => StickerRegisterScreen(),
    ),
  ],
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

Finder get _scrollable => find.descendant(
  of: find.byType(SingleChildScrollView),
  matching: find.byType(Scrollable),
);

ScrollableState _state(WidgetTester tester) =>
    tester.state<ScrollableState>(_scrollable);

void main() {
  group('StickerRegisterScreen header', () {
    testWidgets('shows the title of the header', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      expect(find.byType(Header), findsOneWidget);
      expect(find.text('ADICIONAR'), findsOneWidget);
      expect(find.text('FIGURINHA'), findsOneWidget);
    });

    testWidgets('waits for the code in the preview card', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      expect(find.byType(PreviewCard), findsOneWidget);
      expect(find.text('SEM TIME'), findsOneWidget);
      expect(find.text('AGUARDANDO'), findsOneWidget);
      expect(find.text('DIGITE O CÓDIGO'), findsOneWidget);
    });

    testWidgets('asks for light status bar icons', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

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
  });

  group('StickerRegisterScreen form', () {
    testWidgets('shows the title of the code', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      expect(find.text('CÓDIGO DA FIGURINHA'), findsOneWidget);
    });

    testWidgets('shows the code field with six boxes', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      final field = tester.widget<CodeField>(find.byType(CodeField));

      expect(field.length, 6);
      expect(field.letters, 3);
      expect(field.code, isEmpty);
    });

    testWidgets('shows the hint without a match', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      expect(find.byType(HintBanner), findsOneWidget);
      expect(find.text('DIGITE 3 LETRAS DO TIME + 3 NÚMEROS'), findsOneWidget);
    });

    testWidgets('shows the letters keypad and the digits keypad', (
      tester,
    ) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      final keypads = tester
          .widgetList<Keypad>(find.byType(Keypad))
          .map((keypad) => keypad.letters)
          .toList();

      expect(keypads, [true, false]);
    });

    testWidgets('lets the user reach every letter and every digit', (
      tester,
    ) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      for (final key in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.split('')) {
        expect(
          find.descendant(
            of: find.byType(Keypad),
            matching: find.text(key),
          ),
          findsOneWidget,
          reason: key,
        );
      }
    });

    testWidgets('shows the register button with the arrow', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      final button = tester.widget<StickerActionButton>(
        find.byType(StickerActionButton),
      );

      expect(button.label, 'CADASTRAR FIGURINHA');
      expect(button.icon, Icons.arrow_forward_rounded);
      expect(button.discSize, 28);
    });

    testWidgets(
      'keeps the register button enabled with an empty code for now',
      (
        tester,
      ) async {
        _useScreen(tester);

        await tester.pumpWidget(_host());

        expect(
          tester
              .widget<StickerActionButton>(find.byType(StickerActionButton))
              .onPressed,
          isNotNull,
        );
      },
    );

    testWidgets('glows around the enabled register button', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

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

    testWidgets('stacks the blocks from the header to the button', (
      tester,
    ) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      final tops = [
        tester.getTopLeft(find.byType(Header)).dy,
        tester.getTopLeft(find.text('CÓDIGO DA FIGURINHA')).dy,
        tester.getTopLeft(find.byType(CodeField)).dy,
        tester.getTopLeft(find.byType(HintBanner)).dy,
        tester.getTopLeft(find.byType(Keypad).first).dy,
        tester.getTopLeft(find.byType(Keypad).last).dy,
        tester.getTopLeft(find.byType(StickerActionButton)).dy,
      ];

      expect(tops, [...tops]..sort());
      expect(tops.toSet(), hasLength(7));
    });

    testWidgets('does nothing when a key is tapped for now', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());
      await tester.tap(find.text('V'));
      await tester.tap(find.text('5'));
      await tester.tap(find.byIcon(Icons.backspace_outlined).first);
      await tester.pump();

      expect(find.byType(StickerRegisterScreen), findsOneWidget);
      expect(find.text('DIGITE 3 LETRAS DO TIME + 3 NÚMEROS'), findsOneWidget);
    });

    testWidgets('does nothing when the register button is tapped for now', (
      tester,
    ) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());
      await tester.tap(find.text('CADASTRAR FIGURINHA'));
      await tester.pump();

      expect(find.byType(StickerRegisterScreen), findsOneWidget);
    });
  });

  group('StickerRegisterScreen scroll', () {
    testWidgets('wraps the whole page in a scroll view', (tester) async {
      _useScreen(tester);

      await tester.pumpWidget(_host());

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Header),
        ),
        findsOneWidget,
      );
    });

    testWidgets('does not scroll when everything fits', (tester) async {
      _useScreen(tester, height: 1400);

      await tester.pumpWidget(_host());

      expect(_state(tester).position.maxScrollExtent, 0);
    });

    testWidgets('scrolls when the screen is short', (tester) async {
      _useScreen(tester, height: 700);

      await tester.pumpWidget(_host());

      expect(_state(tester).position.maxScrollExtent, greaterThan(0));
    });

    testWidgets('scrolls the header away together with the form', (
      tester,
    ) async {
      _useScreen(tester, height: 700);
      await tester.pumpWidget(_host());
      final before = tester.getTopLeft(find.byType(Header)).dy;

      await tester.drag(_scrollable, Offset(0, -400));
      await tester.pump();

      expect(tester.getTopLeft(find.byType(Header)).dy, lessThan(before));
    });

    testWidgets('reaches the register button on a short screen', (
      tester,
    ) async {
      _useScreen(tester, height: 700);
      await tester.pumpWidget(_host());

      await tester.scrollUntilVisible(
        find.byType(StickerActionButton),
        100,
        scrollable: _scrollable,
      );

      expect(find.byType(StickerActionButton), findsOneWidget);
    });

    testWidgets('reaches the digits keypad on a short screen', (tester) async {
      _useScreen(tester, height: 700);
      await tester.pumpWidget(_host());

      await tester.scrollUntilVisible(
        find.text('9'),
        100,
        scrollable: _scrollable,
      );

      expect(find.text('9'), findsOneWidget);
    });

    testWidgets('keeps the code field reachable on a short screen', (
      tester,
    ) async {
      _useScreen(tester, height: 500);
      await tester.pumpWidget(_host());

      await tester.scrollUntilVisible(
        find.byType(CodeField),
        100,
        scrollable: _scrollable,
      );

      expect(find.byType(CodeField), findsOneWidget);
    });

    testWidgets('does not overflow on a very short screen', (tester) async {
      _useScreen(tester, height: 300);

      await tester.pumpWidget(_host());

      expect(tester.takeException(), isNull);
    });

    testWidgets('does not overflow on a narrow screen', (tester) async {
      _useScreen(tester, width: 320, height: 700);

      await tester.pumpWidget(_host());

      expect(tester.takeException(), isNull);
    });
  });

  group('StickerRegisterScreen back', () {
    testWidgets('closes the screen reporting no change when it can pop', (
      tester,
    ) async {
      _useScreen(tester);
      final router = _router(initialLocation: Routes.home);

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router, builder: _scaled),
      );
      final result = router.push<bool>(Routes.stickerRegister);
      await tester.pumpAndSettle();
      expect(find.byType(StickerRegisterScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(StickerRegisterScreen), findsNothing);
      expect(find.text('home page'), findsOneWidget);
      expect(await result, isFalse);
    });

    testWidgets('goes to the home when there is nothing to go back to', (
      tester,
    ) async {
      _useScreen(tester);
      final router = _router(initialLocation: Routes.stickerRegister);

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router, builder: _scaled),
      );
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(StickerRegisterScreen), findsNothing);
      expect(find.text('home page'), findsOneWidget);
    });
  });
}
