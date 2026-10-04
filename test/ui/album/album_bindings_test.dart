import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:wc_2026_mobile/ui/album/album_bindings.dart';
import 'package:wc_2026_mobile/ui/album/album_view_model.dart';

void main() {
  group('AlbumBindings', () {
    testWidgets('provides the AlbumViewModel to the screen', (tester) async {
      AlbumViewModel? provided;

      await tester.pumpWidget(
        MaterialApp(
          home: AlbumBindings(
            screenBuilder: (context) {
              provided = context.read<AlbumViewModel>();
              return Text('screen');
            },
          ),
        ),
      );

      expect(find.text('screen'), findsOneWidget);
      expect(provided, isA<AlbumViewModel>());
    });

    testWidgets('keeps the same view model across rebuilds', (tester) async {
      final seen = <AlbumViewModel>[];

      Widget app() => MaterialApp(
        home: AlbumBindings(
          screenBuilder: (context) {
            seen.add(context.read<AlbumViewModel>());
            return Text('screen');
          },
        ),
      );

      await tester.pumpWidget(app());
      await tester.pumpWidget(app());

      expect(seen.toSet(), hasLength(1));
    });
  });

  group('AlbumViewModel', () {
    test('can be listened to', () {
      final viewModel = AlbumViewModel();
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      viewModel.notifyListeners();

      expect(notifications, 1);
      viewModel.dispose();
    });
  });
}
