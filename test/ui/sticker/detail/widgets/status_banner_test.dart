import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/ui/core/theme/theme.dart';
import 'package:wc_2026_mobile/ui/sticker/detail/widgets/status_banner.dart';

const _teamColor = Color(0xFF009C3B);

Widget _host({required int count, Color teamColor = _teamColor}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(0.8)),
    child: child!,
  ),
  home: Scaffold(
    body: Center(
      child: StatusBanner(count: count, teamColor: teamColor),
    ),
  ),
);

Color? _bannerColor(WidgetTester tester) {
  final banner = tester.widget<Container>(
    find
        .descendant(
          of: find.byType(StatusBanner),
          matching: find.byType(Container),
        )
        .first,
  );
  return (banner.decoration! as BoxDecoration).color;
}

CircleAvatar _badge(WidgetTester tester) => tester.widget<CircleAvatar>(
  find.descendant(
    of: find.byType(StatusBanner),
    matching: find.byType(CircleAvatar),
  ),
);

void main() {
  group('StatusBanner collected', () {
    testWidgets('paints the banner with the team color', (tester) async {
      await tester.pumpWidget(_host(count: 2));

      expect(_bannerColor(tester), _teamColor);
    });

    testWidgets('shows a yellow check badge', (tester) async {
      await tester.pumpWidget(_host(count: 2));

      expect(_badge(tester).backgroundColor, AppColors.yellow);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('says the sticker is owned', (tester) async {
      await tester.pumpWidget(_host(count: 2));

      expect(find.text('VOCÊ TEM ESTA FIGURINHA'), findsOneWidget);
      expect(find.text('VOCÊ NÃO TEM ESSA FIGURINHA'), findsNothing);
    });

    testWidgets('shows the count in the box', (tester) async {
      await tester.pumpWidget(_host(count: 4));

      expect(find.text('×4'), findsOneWidget);
    });

    testWidgets('shows the available repeated line', (tester) async {
      await tester.pumpWidget(_host(count: 4));

      expect(find.text('×4 repetidas disponíveis'), findsOneWidget);
    });

    testWidgets('counts a single copy as a repeated one for now', (
      tester,
    ) async {
      await tester.pumpWidget(_host(count: 1));

      expect(find.text('×1 repetidas disponíveis'), findsOneWidget);
    });
  });

  group('StatusBanner missing', () {
    testWidgets('paints the banner gray', (tester) async {
      await tester.pumpWidget(_host(count: 0));

      expect(_bannerColor(tester), AppColors.grayDark);
    });

    testWidgets('shows a red cross badge', (tester) async {
      await tester.pumpWidget(_host(count: 0));

      expect(_badge(tester).backgroundColor, AppColors.red);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });

    testWidgets('says the sticker is missing', (tester) async {
      await tester.pumpWidget(_host(count: 0));

      expect(find.text('VOCÊ NÃO TEM ESSA FIGURINHA'), findsOneWidget);
      expect(find.text('Ainda falta colar no álbum'), findsOneWidget);
      expect(find.text('VOCÊ TEM ESTA FIGURINHA'), findsNothing);
    });

    testWidgets('shows a zero in the box', (tester) async {
      await tester.pumpWidget(_host(count: 0));

      expect(find.text('×0'), findsOneWidget);
    });

    testWidgets('ignores the team color', (tester) async {
      await tester.pumpWidget(_host(count: 0, teamColor: Color(0xFFFF0000)));

      expect(_bannerColor(tester), AppColors.grayDark);
    });
  });

  group('StatusBanner layout', () {
    testWidgets('keeps the height at sixty four pixels', (tester) async {
      await tester.pumpWidget(_host(count: 2));

      expect(tester.getSize(find.byType(StatusBanner)).height, 64);
    });

    testWidgets('rounds the corners', (tester) async {
      await tester.pumpWidget(_host(count: 2));

      final banner = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(StatusBanner),
              matching: find.byType(Container),
            )
            .first,
      );

      expect(
        (banner.decoration! as BoxDecoration).borderRadius,
        AppDimens.borderRadiusMd,
      );
    });

    testWidgets('fits a narrow width without overflowing', (tester) async {
      tester.view.physicalSize = Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(count: 12));

      expect(tester.takeException(), isNull);
    });
  });
}
