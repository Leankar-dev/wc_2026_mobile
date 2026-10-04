import 'package:flutter_test/flutter_test.dart';
import 'package:wc_2026_mobile/domain/models/album/album.dart';
import 'package:wc_2026_mobile/domain/models/album/album_position.dart';
import 'package:wc_2026_mobile/domain/models/album/sticker_status.dart';
import 'package:wc_2026_mobile/domain/models/album/team_album_group.dart';
import 'package:wc_2026_mobile/domain/models/team/team.dart';

const _team = Team(
  code: 'BRA',
  name: 'Brazil',
  flagUrl: '/flags/bra.png',
  primaryColor: 0xFFFFDF00,
);

AlbumPosition _position({
  String code = 'BRA-1',
  int number = 1,
  StickerStatus status = StickerStatus.owned,
  int repeated = 0,
}) => AlbumPosition(
  code: code,
  number: number,
  status: status,
  repeated: repeated,
);

Album _album({List<AlbumPosition> stickers = const []}) => Album(
  teams: [TeamAlbumGroup(team: _team, stickers: stickers)],
  loose: [_position(code: 'FWC-1')],
);

void main() {
  group('AlbumPosition', () {
    test('compares by value', () {
      expect(_position(), _position());
    });

    test('differs when any field differs', () {
      expect(_position(), isNot(_position(code: 'BRA-9')));
      expect(_position(), isNot(_position(number: 2)));
      expect(_position(), isNot(_position(status: StickerStatus.missing)));
      expect(_position(), isNot(_position(repeated: 1)));
    });
  });

  group('TeamAlbumGroup', () {
    test('compares by value', () {
      expect(
        TeamAlbumGroup(team: _team, stickers: [_position()]),
        TeamAlbumGroup(team: _team, stickers: [_position()]),
      );
    });

    test('differs when the stickers differ', () {
      expect(
        TeamAlbumGroup(team: _team, stickers: [_position()]),
        isNot(TeamAlbumGroup(team: _team, stickers: [_position(number: 2)])),
      );
    });
  });

  group('Album', () {
    test('compares the lists by content', () {
      expect(_album(stickers: [_position()]), _album(stickers: [_position()]));
    });

    test('differs when a sticker changes', () {
      expect(
        _album(stickers: [_position()]),
        isNot(_album(stickers: [_position(repeated: 2)])),
      );
    });

    test('differs when the loose stickers change', () {
      expect(
        Album(teams: const [], loose: [_position()]),
        isNot(const Album(teams: [], loose: [])),
      );
    });
  });
}
