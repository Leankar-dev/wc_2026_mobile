import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wc_2026_mobile/core/exceptions/app_exception.dart';
import 'package:wc_2026_mobile/core/result.dart';
import 'package:wc_2026_mobile/data/repositories/album/album_repository.dart';
import 'package:wc_2026_mobile/data/repositories/team/team_repository.dart';
import 'package:wc_2026_mobile/domain/models/album/album.dart';
import 'package:wc_2026_mobile/domain/models/album/album_summary.dart';
import 'package:wc_2026_mobile/domain/models/album/recent_sticker.dart';
import 'package:wc_2026_mobile/domain/models/album/sticker_status.dart';
import 'package:wc_2026_mobile/domain/models/team/team.dart';
import 'package:wc_2026_mobile/ui/core/theme/theme.dart';
import 'package:wc_2026_mobile/ui/sticker/register/sticker_register_view_model.dart';

class _FakeAlbumRepository implements AlbumRepository {
  Result<void> registerResult = Result.done;
  Completer<void>? gate;
  final registered = <({String code, int quantity})>[];

  @override
  Future<Result<void>> registerSticker({
    required String code,
    required int quantity,
  }) async {
    registered.add((code: code, quantity: quantity));
    await gate?.future;
    return registerResult;
  }

  @override
  Future<Result<void>> updateStickerQuantity({
    required String code,
    required int quantity,
  }) async => Result.done;

  @override
  Future<Result<void>> removeSticker(String code) async => Result.done;

  @override
  Future<Result<Album>> getAlbum({StickerStatus? status, String? team}) async =>
      Result.ok(const Album(teams: [], loose: []));

  @override
  Future<Result<AlbumSummary>> getSummary() async =>
      Result.ok(const AlbumSummary(total: 0, missing: 0, repeated: 0));

  @override
  Future<Result<List<RecentSticker>>> getRecentStickers() async =>
      Result.ok(const []);
}

class _FakeTeamRepository implements TeamRepository {
  Result<List<Team>> teams = Result.ok(const [_brazil, _argentina]);
  var calls = 0;

  @override
  Future<Result<List<Team>>> getTeams() async {
    calls++;
    return teams;
  }
}

const _brazil = Team(
  code: 'BRA',
  name: 'Brazil',
  flagUrl: '/flags/bra.png',
  primaryColor: 0xFFFFDF00,
);

const _argentina = Team(
  code: 'ARG',
  name: 'Argentina',
  flagUrl: '/flags/arg.png',
  primaryColor: 0xFF6CACE4,
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeAlbumRepository albums;
  late _FakeTeamRepository teams;
  late StickerRegisterViewModel viewModel;
  var disposed = false;

  void typeAll(String text) => text.split('').forEach(viewModel.type);

  Future<void> start() async {
    viewModel.init();
    await _settle();
  }

  setUp(() {
    albums = _FakeAlbumRepository();
    teams = _FakeTeamRepository();
    viewModel = StickerRegisterViewModel(
      albumRepository: albums,
      teamRepository: teams,
    );
    disposed = false;
  });

  tearDown(() {
    if (!disposed) viewModel.dispose();
  });

  group('StickerRegisterViewModel state', () {
    test('starts empty with the code format', () {
      expect(viewModel.code, isEmpty);
      expect(viewModel.codeLength, 5);
      expect(viewModel.codeLetter, 3);
      expect(viewModel.changed, isFalse);
      expect(viewModel.match, isNull);
    });

    test('does not load the teams before init', () async {
      await _settle();

      expect(teams.calls, 0);
    });

    test('loads the teams on init and notifies', () async {
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      await start();

      expect(teams.calls, 1);
      expect(notifications, 1);
    });

    test('keeps working when the teams fail to load', () async {
      teams.teams = Result.error(const NetworkException());

      await start();
      typeAll('BRA01');

      expect(viewModel.code, 'BRA01');
      expect(viewModel.match, isNull);
    });
  });

  group('StickerRegisterViewModel typing', () {
    test('appends each character and notifies', () {
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      viewModel.type('B');
      viewModel.type('R');

      expect(viewModel.code, 'BR');
      expect(notifications, 2);
    });

    test('stops at the code length', () {
      typeAll('BRA0123');

      expect(viewModel.code, 'BRA01');
    });

    test('does not notify when the code is full', () {
      typeAll('BRA01');
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      viewModel.type('9');

      expect(notifications, 0);
    });

    test('accepts any character for now', () {
      typeAll('1-@x!');

      expect(viewModel.code, '1-@x!');
    });

    test('removes the last character and notifies', () {
      typeAll('BRA');
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      viewModel.backspace();

      expect(viewModel.code, 'BR');
      expect(notifications, 1);
    });

    test('ignores the backspace on an empty code', () {
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      viewModel.backspace();

      expect(viewModel.code, isEmpty);
      expect(notifications, 0);
    });

    test('lets the user type again after a backspace', () {
      typeAll('BRA01');
      viewModel.backspace();
      viewModel.type('2');

      expect(viewModel.code, 'BRA02');
    });
  });

  group('StickerRegisterViewModel match', () {
    test('is null until the code is complete', () async {
      await start();
      typeAll('BRA0');

      expect(viewModel.match, isNull);
    });

    test('identifies a team sticker', () async {
      await start();
      typeAll('BRA01');

      final match = viewModel.match!;

      expect(match.code, 'BRA-1');
      expect(match.label, 'BRA – 01');
      expect(match.team, 'Brazil');
      expect(match.number, '01');
      expect(match.color, Color(0xFFFFDF00));
      expect(match.flagPath, '/flags/bra.png');
    });

    test('drops the leading zero in the api code', () async {
      await start();
      typeAll('ARG07');

      expect(viewModel.match?.code, 'ARG-7');
      expect(viewModel.match?.number, '07');
    });

    test('keeps both digits of the api code from ten on', () async {
      await start();
      typeAll('BRA10');

      expect(viewModel.match?.code, 'BRA-10');
    });

    test('accepts the last sticker of the team', () async {
      await start();
      typeAll('BRA20');

      expect(viewModel.match?.code, 'BRA-20');
    });

    test('rejects a number above twenty', () async {
      await start();
      typeAll('BRA21');

      expect(viewModel.match, isNull);
    });

    test('rejects the number zero', () async {
      await start();
      typeAll('BRA00');

      expect(viewModel.match, isNull);
    });

    test('rejects the number zero of a special sticker too', () async {
      await start();
      typeAll('FWC00');

      expect(viewModel.match, isNull);
    });

    test('rejects a team that is not in the catalog', () async {
      await start();
      typeAll('XYZ05');

      expect(viewModel.match, isNull);
    });

    test('is case sensitive with the team code', () async {
      await start();
      typeAll('bra01');

      expect(viewModel.match, isNull);
    });

    test('is null before the teams are loaded', () {
      typeAll('BRA01');

      expect(viewModel.match, isNull);
    });

    test('identifies a special sticker', () async {
      await start();
      typeAll('FWC03');

      final match = viewModel.match!;

      expect(match.code, 'FWC-3');
      expect(match.label, 'FWC – 03');
      expect(match.team, 'ESPECIAL');
      expect(match.color, AppColors.ink);
      expect(match.flagPath, isNull);
    });

    test('identifies a special sticker without the teams loaded', () {
      typeAll('FWC01');

      expect(viewModel.match?.team, 'ESPECIAL');
    });

    test('does not limit the number of a special sticker for now', () async {
      await start();
      typeAll('FWC99');

      expect(viewModel.match?.code, 'FWC-99');
    });

    test('fails to parse a code with letters in the number for now', () async {
      await start();
      typeAll('BRAAB');

      expect(() => viewModel.match, throwsFormatException);
    });

    test('follows the backspace', () async {
      await start();
      typeAll('BRA01');
      expect(viewModel.match, isNotNull);

      viewModel.backspace();

      expect(viewModel.match, isNull);
    });
  });

  group('StickerRegisterViewModel register', () {
    Future<void> identify() async {
      await start();
      typeAll('BRA01');
    }

    test('registers one copy with the api code', () async {
      await identify();

      await viewModel.register.execute(viewModel.match!);

      expect(albums.registered, [(code: 'BRA-1', quantity: 1)]);
    });

    test('returns the registered sticker', () async {
      await identify();
      final match = viewModel.match!;

      await viewModel.register.execute(match);

      expect((viewModel.register.result as Ok<StickerMatch>).value, match);
    });

    test('clears the code and marks the album as changed', () async {
      await identify();

      await viewModel.register.execute(viewModel.match!);

      expect(viewModel.code, isEmpty);
      expect(viewModel.changed, isTrue);
      expect(viewModel.match, isNull);
    });

    test('keeps the code and does not mark a change when it fails', () async {
      albums.registerResult = Result.error(const NetworkException());
      await identify();

      await viewModel.register.execute(viewModel.match!);

      expect(viewModel.register.error, isTrue);
      expect(viewModel.code, 'BRA01');
      expect(viewModel.changed, isFalse);
    });

    test('reports the error of a failed registration', () async {
      albums.registerResult = Result.error(const ServerException());
      await identify();

      await viewModel.register.execute(viewModel.match!);

      expect(
        (viewModel.register.result as Error).error,
        isA<ServerException>(),
      );
    });

    test(
      'shows an unknown error when the sticker already exists for now',
      () async {
        albums.registerResult = Result.error(const UnknownException());
        await identify();

        await viewModel.register.execute(viewModel.match!);

        expect(
          (viewModel.register.result as Error).error,
          isA<UnknownException>(),
        );
      },
    );

    test('registers again after a failure', () async {
      albums.registerResult = Result.error(const NetworkException());
      await identify();
      await viewModel.register.execute(viewModel.match!);

      albums.registerResult = Result.done;
      await viewModel.register.execute(viewModel.match!);

      expect(albums.registered, hasLength(2));
      expect(viewModel.changed, isTrue);
    });

    test('keeps the change flag after a later failure', () async {
      await identify();
      await viewModel.register.execute(viewModel.match!);

      albums.registerResult = Result.error(const NetworkException());
      typeAll('ARG02');
      await viewModel.register.execute(viewModel.match!);

      expect(viewModel.changed, isTrue);
    });

    test('notifies listeners when the registration finishes', () async {
      await identify();
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      await viewModel.register.execute(viewModel.match!);

      expect(notifications, 1);
    });

    test('is running while the request is pending', () async {
      albums.gate = Completer<void>();
      await identify();

      final registering = viewModel.register.execute(viewModel.match!);
      await _settle();

      expect(viewModel.register.running, isTrue);

      albums.gate!.complete();
      await registering;

      expect(viewModel.register.running, isFalse);
    });

    test('ignores a second registration while one is running', () async {
      albums.gate = Completer<void>();
      await identify();
      final match = viewModel.match!;

      final first = viewModel.register.execute(match);
      await _settle();
      await viewModel.register.execute(match);

      expect(albums.registered, hasLength(1));

      albums.gate!.complete();
      await first;
    });

    test('lets the user type while the request is pending for now', () async {
      albums.gate = Completer<void>();
      await identify();

      final registering = viewModel.register.execute(viewModel.match!);
      await _settle();
      viewModel.backspace();
      expect(viewModel.code, 'BRA0');

      albums.gate!.complete();
      await registering;

      expect(viewModel.code, isEmpty);
    });

    test(
      'fails to notify when disposed during a registration for now',
      () async {
        albums.gate = Completer<void>();
        await identify();

        final registering = viewModel.register.execute(viewModel.match!);
        await _settle();
        viewModel.dispose();
        disposed = true;
        albums.gate!.complete();

        await expectLater(registering, throwsA(isA<FlutterError>()));
      },
    );
  });
}
