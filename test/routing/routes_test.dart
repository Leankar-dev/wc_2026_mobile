import 'package:flutter_test/flutter_test.dart';
import 'package:wc_2026_mobile/routing/routes.dart';

void main() {
  group('Routes', () {
    test('builds the detail location from the sticker code', () {
      expect(Routes.sticker('BRA-1'), '/sticker/BRA-1');
      expect(Routes.sticker('FWC-10'), '/sticker/FWC-10');
    });

    test('keeps the detail path pattern with the code parameter', () {
      expect(Routes.stickerPath, '/sticker/:code');
    });

    test('builds a location that matches the path pattern', () {
      final pattern = RegExp(
        '^${Routes.stickerPath.replaceAll(':code', '([^/]+)')}\$',
      );

      expect(pattern.hasMatch(Routes.sticker('BRA-1')), isTrue);
      expect(pattern.firstMatch(Routes.sticker('BRA-1'))?.group(1), 'BRA-1');
    });

    test('keeps the detail route private', () {
      expect(Routes.public, isNot(contains(Routes.stickerPath)));
      expect(Routes.public, isNot(contains(Routes.sticker('BRA-1'))));
    });

    test('keeps the public routes', () {
      expect(
        Routes.public,
        containsAll([
          Routes.splash,
          Routes.welcome,
          Routes.login,
          Routes.authRegister,
        ]),
      );
    });

    test('names the register location', () {
      expect(Routes.stickerRegister, '/sticker/register');
    });

    test('keeps the register route private', () {
      expect(Routes.public, isNot(contains(Routes.stickerRegister)));
    });

    test('lets the register location match the detail pattern too', () {
      final pattern = RegExp(
        '^${Routes.stickerPath.replaceAll(':code', '([^/]+)')}\$',
      );

      expect(pattern.hasMatch(Routes.stickerRegister), isTrue);
      expect(pattern.firstMatch(Routes.stickerRegister)?.group(1), 'register');
    });
  });
}
