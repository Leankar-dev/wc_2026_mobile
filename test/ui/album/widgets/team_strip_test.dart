import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/domain/models/team/team.dart';
import 'package:wc_2026_mobile/ui/album/widgets/team_strip.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

Team _team(int index) => Team(
  code: 'T${index.toString().padLeft(2, '0')}',
  name: 'Team $index',
  flagUrl: '/flags/t$index.png',
  primaryColor: 0xFF000000 + index * 0x010101,
);

final _discs = find.descendant(
  of: find.byType(TeamStrip),
  matching: find.byType(InkWell),
);

void main() {
  group('TeamStrip', () {
    testWidgets('shows one disc per team', (tester) async {
      await tester.pumpWidget(
        _host(
          TeamStrip(
            teams: [_team(1), _team(2), _team(3)],
            selected: null,
            onSelected: (_) {},
          ),
        ),
      );

      expect(_discs, findsNWidgets(3));
    });

    testWidgets('shows no disc when there are no teams', (tester) async {
      await tester.pumpWidget(
        _host(TeamStrip(teams: const [], selected: null, onSelected: (_) {})),
      );

      expect(_discs, findsNothing);
    });

    testWidgets('keeps every disc at the regular size when none is selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          TeamStrip(
            teams: [_team(1), _team(2)],
            selected: null,
            onSelected: (_) {},
          ),
        ),
      );

      expect(tester.getSize(_discs.at(0)).width, 44.0);
      expect(tester.getSize(_discs.at(1)).width, 44.0);
    });

    testWidgets('enlarges only the selected disc', (tester) async {
      await tester.pumpWidget(
        _host(
          TeamStrip(
            teams: [_team(1), _team(2), _team(3)],
            selected: 'T02',
            onSelected: (_) {},
          ),
        ),
      );

      expect(tester.getSize(_discs.at(0)).width, 44.0);
      expect(tester.getSize(_discs.at(1)).width, 52.0);
      expect(tester.getSize(_discs.at(2)).width, 44.0);
    });

    testWidgets('draws each disc border with the team color', (tester) async {
      await tester.pumpWidget(
        _host(
          TeamStrip(
            teams: [_team(1), _team(2)],
            selected: 'T02',
            onSelected: (_) {},
          ),
        ),
      );

      final borders = tester
          .widgetList<Material>(
            find.descendant(
              of: find.byType(TeamStrip),
              matching: find.byType(Material),
            ),
          )
          .map((material) => material.shape)
          .whereType<CircleBorder>()
          .map((shape) => shape.side)
          .toList();

      expect(borders.map((side) => side.color), [
        Color(_team(1).primaryColor),
        Color(_team(2).primaryColor),
      ]);
      expect(borders.map((side) => side.width), [2.0, 3.0]);
    });

    testWidgets('reports the code of the tapped team', (tester) async {
      final selections = <String>[];

      await tester.pumpWidget(
        _host(
          TeamStrip(
            teams: [_team(1), _team(2), _team(3)],
            selected: 'T01',
            onSelected: selections.add,
          ),
        ),
      );
      await tester.tap(_discs.at(2));
      await tester.tap(_discs.at(0));

      expect(selections, ['T03', 'T01']);
    });

    testWidgets('reaches a team that needs scrolling', (tester) async {
      final selections = <String>[];

      await tester.pumpWidget(
        _host(
          TeamStrip(
            teams: [for (var i = 0; i < 30; i++) _team(i)],
            selected: null,
            onSelected: selections.add,
          ),
        ),
      );
      await tester.drag(find.byType(ListView), Offset(-3000, 0));
      await tester.pumpAndSettle();
      await tester.tap(_discs.last);

      expect(selections, ['T29']);
    });
  });
}
