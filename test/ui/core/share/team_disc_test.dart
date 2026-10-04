import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/ui/core/share/team_disc.dart';
import 'package:wc_2026_mobile/ui/core/share/team_flag.dart';

const _color = Color(0xFF009C3B);

Widget _host(Widget disc) => MaterialApp(
  home: Scaffold(body: Center(child: disc)),
);

Finder get _ink =>
    find.descendant(of: find.byType(TeamDisc), matching: find.byType(InkWell));

CircleBorder _border(WidgetTester tester) => tester
    .widgetList<Material>(
      find.descendant(
        of: find.byType(TeamDisc),
        matching: find.byType(Material),
      ),
    )
    .map((material) => material.shape)
    .whereType<CircleBorder>()
    .first;

void main() {
  group('TeamDisc', () {
    testWidgets('draws a regular disc by default', (tester) async {
      await tester.pumpWidget(_host(TeamDisc(color: _color, flagCode: 'BRA')));

      expect(tester.getSize(_ink), Size.square(44));
      expect(_border(tester).side.width, 2.0);
      expect(_border(tester).side.color, _color);
    });

    testWidgets('enlarges the disc and thickens the border when selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(TeamDisc(color: _color, flagCode: 'BRA', selected: true)),
      );

      expect(tester.getSize(_ink), Size.square(52));
      expect(_border(tester).side.width, 3.0);
    });

    testWidgets('sizes the flag from the disc and the border', (tester) async {
      await tester.pumpWidget(_host(TeamDisc(color: _color, flagCode: 'BRA')));
      expect(tester.widget<TeamFlag>(find.byType(TeamFlag)).size, 32);

      await tester.pumpWidget(
        _host(TeamDisc(color: _color, flagCode: 'BRA', selected: true)),
      );
      expect(tester.widget<TeamFlag>(find.byType(TeamFlag)).size, 38);
    });

    testWidgets('shows the flag by its code', (tester) async {
      await tester.pumpWidget(_host(TeamDisc(color: _color, flagCode: 'BRA')));

      final flag = tester.widget<TeamFlag>(find.byType(TeamFlag));

      expect(flag.code, 'BRA');
      expect(flag.path, isNull);
    });

    testWidgets('shows the flag by its path', (tester) async {
      await tester.pumpWidget(
        _host(TeamDisc(color: _color, flagPath: '/flags/bra.png')),
      );

      final flag = tester.widget<TeamFlag>(find.byType(TeamFlag));

      expect(flag.path, '/flags/bra.png');
      expect(flag.code, isNull);
    });

    testWidgets('prefers the path when both are given', (tester) async {
      await tester.pumpWidget(
        _host(
          TeamDisc(color: _color, flagPath: '/flags/bra.png', flagCode: 'ARG'),
        ),
      );

      expect(
        tester.widget<TeamFlag>(find.byType(TeamFlag)).path,
        '/flags/bra.png',
      );
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var taps = 0;

      await tester.pumpWidget(
        _host(TeamDisc(color: _color, flagCode: 'BRA', onTap: () => taps++)),
      );
      await tester.tap(find.byType(TeamDisc));

      expect(taps, 1);
    });

    testWidgets('stays tappable without an onTap', (tester) async {
      await tester.pumpWidget(_host(TeamDisc(color: _color, flagCode: 'BRA')));
      await tester.tap(find.byType(TeamDisc));
      await tester.pump();

      expect(_ink, findsOneWidget);
    });

    testWidgets('paints a white background', (tester) async {
      await tester.pumpWidget(_host(TeamDisc(color: _color, flagCode: 'BRA')));

      final material = tester
          .widgetList<Material>(
            find.descendant(
              of: find.byType(TeamDisc),
              matching: find.byType(Material),
            ),
          )
          .firstWhere((m) => m.shape is CircleBorder);

      expect(material.color, Color(0xFFFFFFFF));
    });
  });
}
