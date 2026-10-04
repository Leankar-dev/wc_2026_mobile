import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wc_2026_mobile/core/command.dart';
import 'package:wc_2026_mobile/core/exceptions/app_exception.dart';
import 'package:wc_2026_mobile/core/result.dart';
import 'package:wc_2026_mobile/ui/core/share/app_loading.dart';
import 'package:wc_2026_mobile/ui/core/share/command_builder.dart';
import 'package:wc_2026_mobile/ui/core/share/error_indicator.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('CommandBuilder', () {
    testWidgets('shows the loader while the command is running', (
      tester,
    ) async {
      final completer = Completer<Result<void>>();
      final command = Command0<void>(() => completer.future);

      await tester.pumpWidget(
        _host(
          CommandBuilder<String>(
            asyncCommand: command,
            data: () => 'data',
            builder: Text.new,
          ),
        ),
      );
      unawaited(command.execute());
      await tester.pump();

      expect(find.byType(AppLoading), findsOneWidget);
      expect(find.text('data'), findsNothing);

      completer.complete(Result.done);
      await tester.pump();
    });

    testWidgets('uses the custom loading builder', (tester) async {
      final completer = Completer<Result<void>>();
      final command = Command0<void>(() => completer.future);

      await tester.pumpWidget(
        _host(
          CommandBuilder<String>(
            asyncCommand: command,
            data: () => 'data',
            builder: Text.new,
            loading: (context, loader) => SizedBox(height: 138, child: loader),
          ),
        ),
      );
      unawaited(command.execute());
      await tester.pump();

      final box = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(AppLoading),
          matching: find.byWidgetPredicate(
            (widget) => widget is SizedBox && widget.height == 138,
          ),
        ),
      );
      expect(box.height, 138);

      completer.complete(Result.done);
      await tester.pump();
    });

    testWidgets('builds the content when the command finishes', (tester) async {
      final command = Command0<void>(() async => Result.done);

      await tester.pumpWidget(
        _host(
          CommandBuilder<String>(
            asyncCommand: command,
            data: () => 'data',
            builder: Text.new,
          ),
        ),
      );
      await command.execute();
      await tester.pump();

      expect(find.text('data'), findsOneWidget);
      expect(find.byType(AppLoading), findsNothing);
    });

    testWidgets('renders nothing when there is no data', (tester) async {
      final command = Command0<void>(() async => Result.done);

      await tester.pumpWidget(
        _host(
          CommandBuilder<String>(
            asyncCommand: command,
            data: () => null,
            builder: Text.new,
          ),
        ),
      );
      await command.execute();
      await tester.pump();

      expect(find.byType(AppLoading), findsNothing);
      expect(find.byType(ErrorIndicator), findsNothing);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('shows the error message and retries on tap', (tester) async {
      var retries = 0;
      final command = Command0<void>(
        () async => Result.error(const NetworkException()),
      );

      await tester.pumpWidget(
        _host(
          CommandBuilder<String>(
            asyncCommand: command,
            data: () => 'data',
            builder: Text.new,
            retry: () => retries++,
          ),
        ),
      );
      await command.execute();
      await tester.pump();

      expect(find.byType(ErrorIndicator), findsOneWidget);
      expect(
        find.text('Sem conexão. Verifique sua internet e tente novamente.'),
        findsOneWidget,
      );
      expect(find.text('data'), findsNothing);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();

      expect(retries, 1);
    });

    testWidgets('does not fail when tapping retry without a callback', (
      tester,
    ) async {
      final command = Command0<void>(
        () async => Result.error(const ServerException()),
      );

      await tester.pumpWidget(
        _host(
          CommandBuilder<String>(
            asyncCommand: command,
            data: () => 'data',
            builder: Text.new,
          ),
        ),
      );
      await command.execute();
      await tester.pump();

      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();

      expect(find.byType(ErrorIndicator), findsOneWidget);
    });
  });
}
