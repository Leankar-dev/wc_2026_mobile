import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wc_2026_mobile/ui/sticker/widgets/sticker_desaturate.dart';

const _grayscale = ColorFilter.matrix([
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
]);

const _identity = ColorFilter.matrix([
  1, 0, 0, 0, 0, //
  0, 1, 0, 0, 0,
  0, 0, 1, 0, 0,
  0, 0, 0, 1, 0,
]);

Widget _host({required bool active, Widget? child}) => Directionality(
  textDirection: TextDirection.ltr,
  child: Center(
    child: StickerDesaturate(
      active: active,
      child: child ?? const SizedBox(width: 10, height: 10),
    ),
  ),
);

ColorFilter _filter(WidgetTester tester) =>
    tester.widget<ColorFiltered>(find.byType(ColorFiltered)).colorFilter;

Future<List<int>> _centerPixel(
  WidgetTester tester, {
  required bool active,
}) async {
  final key = GlobalKey();

  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: key,
        child: StickerDesaturate(
          active: active,
          child: const SizedBox(
            width: 10,
            height: 10,
            child: ColoredBox(color: Color(0xFFFF0000)),
          ),
        ),
      ),
    ),
  );

  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(key),
  );
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return data!.buffer.asUint8List();
  });

  const center = (5 * 10 + 5) * 4;
  final pixel = bytes as Uint8List;
  return [
    pixel[center],
    pixel[center + 1],
    pixel[center + 2],
    pixel[center + 3],
  ];
}

void main() {
  group('StickerDesaturate', () {
    testWidgets('applies the grayscale filter when active', (tester) async {
      await tester.pumpWidget(_host(active: true));

      expect(_filter(tester), _grayscale);
    });

    testWidgets('applies the identity filter when not active', (tester) async {
      await tester.pumpWidget(_host(active: false));

      expect(_filter(tester), _identity);
    });

    testWidgets('keeps the child in both states', (tester) async {
      const child = Text('flag');

      await tester.pumpWidget(_host(active: true, child: child));
      expect(find.text('flag'), findsOneWidget);

      await tester.pumpWidget(_host(active: false, child: child));
      expect(find.text('flag'), findsOneWidget);
    });

    testWidgets('switches the filter when the state changes', (tester) async {
      await tester.pumpWidget(_host(active: false));
      expect(_filter(tester), _identity);

      await tester.pumpWidget(_host(active: true));
      expect(_filter(tester), _grayscale);
    });

    testWidgets('does not change the size of the child', (tester) async {
      await tester.pumpWidget(_host(active: true));

      expect(tester.getSize(find.byType(SizedBox).first), Size(10, 10));
    });

    testWidgets('still builds a color filter layer when not active', (
      tester,
    ) async {
      await tester.pumpWidget(_host(active: false));

      expect(find.byType(ColorFiltered), findsOneWidget);
    });

    testWidgets('turns a red pixel into its luminance gray when active', (
      tester,
    ) async {
      final pixel = await _centerPixel(tester, active: true);

      expect(pixel[0], closeTo(54, 2));
      expect(pixel[1], closeTo(54, 2));
      expect(pixel[2], closeTo(54, 2));
      expect(pixel[3], 255);
    });

    testWidgets('keeps a red pixel red when not active', (tester) async {
      final pixel = await _centerPixel(tester, active: false);

      expect(pixel, [255, 0, 0, 255]);
    });
  });
}
