import 'package:flutter_test/flutter_test.dart';
import 'package:wc_2026_mobile/domain/models/album/sticker_status.dart';

void main() {
  group('StickerStatus', () {
    test('lists the statuses in order', () {
      expect(StickerStatus.values, [
        StickerStatus.missing,
        StickerStatus.owned,
        StickerStatus.repeated,
      ]);
    });

    test('exposes the status names', () {
      expect(StickerStatus.values.map((status) => status.name), [
        'missing',
        'owned',
        'repeated',
      ]);
    });
  });
}
