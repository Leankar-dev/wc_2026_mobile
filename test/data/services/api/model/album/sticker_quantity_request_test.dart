import 'package:flutter_test/flutter_test.dart';
import 'package:wc_2026_mobile/data/services/api/model/album/sticker_quantity_request.dart';

void main() {
  group('StickerQuantityRequest', () {
    test('writes the code and the quantity', () {
      const request = StickerQuantityRequest(code: 'BRA-1', quantity: 3);

      expect(request.toJson(), {'code': 'BRA-1', 'quantity': 3});
    });

    test('reads the code and the quantity', () {
      final request = StickerQuantityRequest.fromJson({
        'code': 'ARG-10',
        'quantity': 2,
      });

      expect(request.code, 'ARG-10');
      expect(request.quantity, 2);
    });

    test('round trips through json', () {
      const request = StickerQuantityRequest(code: 'FWC-1', quantity: 1);

      expect(StickerQuantityRequest.fromJson(request.toJson()), request);
    });

    test('compares by value', () {
      const one = StickerQuantityRequest(code: 'BRA-1', quantity: 3);
      const same = StickerQuantityRequest(code: 'BRA-1', quantity: 3);

      expect(one, same);
      expect(one.hashCode, same.hashCode);
    });

    test('differs when the code or the quantity differs', () {
      const request = StickerQuantityRequest(code: 'BRA-1', quantity: 3);

      expect(
        request,
        isNot(const StickerQuantityRequest(code: 'BRA-2', quantity: 3)),
      );
      expect(
        request,
        isNot(const StickerQuantityRequest(code: 'BRA-1', quantity: 4)),
      );
    });

    test('accepts a quantity of zero or a negative one without limits', () {
      expect(
        const StickerQuantityRequest(code: 'BRA-1', quantity: 0).toJson(),
        {'code': 'BRA-1', 'quantity': 0},
      );
      expect(
        const StickerQuantityRequest(code: 'BRA-1', quantity: -1).toJson(),
        {'code': 'BRA-1', 'quantity': -1},
      );
    });

    test('fails when a field is missing', () {
      expect(
        () => StickerQuantityRequest.fromJson({'code': 'BRA-1'}),
        throwsA(isA<TypeError>()),
      );
    });

    test('fails when the quantity is not a number', () {
      expect(
        () => StickerQuantityRequest.fromJson({
          'code': 'BRA-1',
          'quantity': 'many',
        }),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
