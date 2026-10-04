import 'package:flutter_test/flutter_test.dart';
import 'package:wc_2026_mobile/data/services/api/model/album/album_api_model.dart';
import 'package:wc_2026_mobile/data/services/api/model/album/album_position_api_model.dart';
import 'package:wc_2026_mobile/data/services/api/model/album/team_album_group_api_model.dart';
import 'package:wc_2026_mobile/data/services/api/model/team/team_api_model.dart';
import 'package:wc_2026_mobile/domain/models/album/sticker_status.dart';

Map<String, dynamic> _albumJson() => {
  'teams': [
    {
      'team': {
        'code': 'BRA',
        'name': 'Brazil',
        'flag_url': '/flags/bra.png',
        'primary_color': '#FFDF00',
      },
      'stickers': [
        {'code': 'BRA-1', 'number': 1, 'status': 'owned', 'repeated': 0},
        {'code': 'BRA-2', 'number': 2, 'status': 'repeated', 'repeated': 2},
        {'code': 'BRA-3', 'number': 3, 'status': 'missing', 'repeated': 0},
      ],
    },
  ],
  'loose': [
    {'code': 'FWC-1', 'number': 1, 'status': 'missing', 'repeated': 0},
  ],
};

void main() {
  group('AlbumPositionApiModel', () {
    test('reads a position and its status by name', () {
      final model = AlbumPositionApiModel.fromJson({
        'code': 'BRA-2',
        'number': 2,
        'status': 'repeated',
        'repeated': 2,
      });

      expect(model.code, 'BRA-2');
      expect(model.number, 2);
      expect(model.status, StickerStatus.repeated);
      expect(model.repeated, 2);
    });

    test('reads every status', () {
      final statuses = ['missing', 'owned', 'repeated'].map(
        (name) => AlbumPositionApiModel.fromJson({
          'code': 'BRA-1',
          'number': 1,
          'status': name,
          'repeated': 0,
        }).status,
      );

      expect(statuses, StickerStatus.values);
    });

    test('writes the status by name', () {
      const model = AlbumPositionApiModel(
        code: 'BRA-1',
        number: 1,
        status: StickerStatus.owned,
        repeated: 0,
      );

      expect(model.toJson(), {
        'code': 'BRA-1',
        'number': 1,
        'status': 'owned',
        'repeated': 0,
      });
    });

    test('fails when the backend sends an unknown status', () {
      expect(
        () => AlbumPositionApiModel.fromJson({
          'code': 'BRA-1',
          'number': 1,
          'status': 'reserved',
          'repeated': 0,
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fails when a required field is missing', () {
      expect(
        () => AlbumPositionApiModel.fromJson({
          'code': 'BRA-1',
          'status': 'owned',
          'repeated': 0,
        }),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('TeamAlbumGroupApiModel', () {
    test('reads the team and its stickers', () {
      final model = TeamAlbumGroupApiModel.fromJson(
        (_albumJson()['teams'] as List).first as Map<String, dynamic>,
      );

      expect(model.team.code, 'BRA');
      expect(model.stickers, hasLength(3));
      expect(model.stickers.map((s) => s.status), [
        StickerStatus.owned,
        StickerStatus.repeated,
        StickerStatus.missing,
      ]);
    });

    test('accepts a team without stickers', () {
      final model = TeamAlbumGroupApiModel.fromJson({
        'team': {
          'code': 'BRA',
          'name': 'Brazil',
          'flag_url': '/flags/bra.png',
          'primary_color': '#FFDF00',
        },
        'stickers': <dynamic>[],
      });

      expect(model.stickers, isEmpty);
    });
  });

  group('AlbumApiModel', () {
    test('reads the teams and the loose stickers', () {
      final model = AlbumApiModel.fromJson(_albumJson());

      expect(model.teams, hasLength(1));
      expect(model.teams.single.team.name, 'Brazil');
      expect(model.loose.single.code, 'FWC-1');
    });

    test('accepts an empty album', () {
      final model = AlbumApiModel.fromJson({
        'teams': <dynamic>[],
        'loose': <dynamic>[],
      });

      expect(model.teams, isEmpty);
      expect(model.loose, isEmpty);
    });

    test('round trips through json', () {
      final model = AlbumApiModel.fromJson(_albumJson());

      expect(AlbumApiModel.fromJson(model.toJson()), model);
      expect(model.toJson(), _albumJson());
    });

    test('compares by value', () {
      final one = AlbumApiModel.fromJson(_albumJson());
      final other = AlbumApiModel.fromJson(_albumJson());

      expect(one, other);
      expect(
        one,
        isNot(
          AlbumApiModel(
            teams: const <TeamAlbumGroupApiModel>[],
            loose: one.loose,
          ),
        ),
      );
    });

    test('keeps the team model type', () {
      final model = AlbumApiModel.fromJson(_albumJson());

      expect(model.teams.single.team, isA<TeamApiModel>());
    });
  });
}
