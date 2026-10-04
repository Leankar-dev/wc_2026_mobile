import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:wc_2026_mobile/ui/sticker/detail/detail_bindings.dart';
import 'package:wc_2026_mobile/ui/sticker/detail/detail_screen.dart';
import 'package:wc_2026_mobile/ui/sticker/detail/detail_view_model.dart';

const DetailArgs _args = (
  code: 'BRA-1',
  number: 1,
  team: 'Brazil',
  country: 'BRA',
  teamColor: Color(0xFFFFDF00),
  rare: false,
  count: 2,
);

void main() {
  group('DetailViewModel', () {
    test('can be listened to', () {
      final viewModel = DetailViewModel();
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      viewModel.notifyListeners();

      expect(notifications, 1);
      viewModel.dispose();
    });
  });

  group('DetailScreen', () {
    testWidgets('shows a placeholder for now', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: DetailScreen(sticker: _args)),
      );

      expect(find.byType(Placeholder), findsOneWidget);
    });

    testWidgets('keeps the sticker it was opened with', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: DetailScreen(sticker: _args)),
      );

      expect(
        tester.widget<DetailScreen>(find.byType(DetailScreen)).sticker,
        _args,
      );
    });
  });

  group('DetailBindings', () {
    testWidgets('builds the screen with the view model available', (
      tester,
    ) async {
      DetailViewModel? provided;

      await tester.pumpWidget(
        MaterialApp(
          home: DetailBindings(
            stickers: _args,
            screenBuilder: (context) {
              provided = context.read<DetailViewModel>();
              return Text('detail');
            },
          ),
        ),
      );

      expect(find.text('detail'), findsOneWidget);
      expect(provided, isA<DetailViewModel>());
    });

    testWidgets('keeps the same view model across rebuilds', (tester) async {
      final seen = <DetailViewModel>[];

      Widget app() => MaterialApp(
        home: DetailBindings(
          stickers: _args,
          screenBuilder: (context) {
            seen.add(context.read<DetailViewModel>());
            return Text('detail');
          },
        ),
      );

      await tester.pumpWidget(app());
      await tester.pumpWidget(app());

      expect(seen.toSet(), hasLength(1));
    });

    testWidgets('builds a different view model for each screen', (
      tester,
    ) async {
      final seen = <DetailViewModel>[];

      Widget app(Key key) => MaterialApp(
        home: DetailBindings(
          key: key,
          stickers: _args,
          screenBuilder: (context) {
            seen.add(context.read<DetailViewModel>());
            return Text('detail');
          },
        ),
      );

      await tester.pumpWidget(app(ValueKey('a')));
      await tester.pumpWidget(app(ValueKey('b')));

      expect(seen.toSet(), hasLength(2));
    });
  });
}
