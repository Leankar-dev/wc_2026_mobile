import 'package:flutter_test/flutter_test.dart';
import 'package:wc_2026_mobile/data/services/api/mappers/album_api_model_mapper.dart';
import 'package:wc_2026_mobile/data/services/api/mappers/album_position_api_model_mapper.dart';
import 'package:wc_2026_mobile/data/services/api/mappers/team_album_group_api_model_mapper.dart';
import 'package:wc_2026_mobile/data/services/api/model/album/album_api_model.dart';
import 'package:wc_2026_mobile/data/services/api/model/album/album_position_api_model.dart';
import 'package:wc_2026_mobile/data/services/api/model/album/team_album_group_api_model.dart';
import 'package:wc_2026_mobile/data/services/api/model/team/team_api_model.dart';
import 'package:wc_2026_mobile/domain/models/album/album.dart';
import 'package:wc_2026_mobile/domain/models/album/album_position.dart';
import 'package:wc_2026_mobile/domain/models/album/sticker_status.dart';
import 'package:wc_2026_mobile/domain/models/album/team_album_group.dart';
import 'package:wc_2026_mobile/domain/models/team/team.dart';

const _teamApi = TeamApiModel(
  code: 'BRA',
  name: 'Brazil',
  flagUrl: '/flags/bra.png',
  primaryColor: '#FFDF00',
);

const _team = Team(
  code: 'BRA',
  name: 'Brazil',
  flagUrl: '/flags/bra.png',
  primaryColor: 0xFFFFDF00,
);

void main() {
  group('AlbumPositionApiModelMapper', () {
    test('maps every field of the position', () {
      const model = AlbumPositionApiModel(
        code: 'BRA-2',
        number: 2,
        status: StickerStatus.repeated,
        repeated: 2,
      );

      expect(
        model.toDomain(),
        const AlbumPosition(
          code: 'BRA-2',
          number: 2,
          status: StickerStatus.repeated,
          repeated: 2,
        ),
      );
    });

    test('keeps each status', () {
      final statuses = StickerStatus.values.map(
        (status) => AlbumPositionApiModel(
          code: 'BRA-1',
          number: 1,
          status: status,
          repeated: 0,
        ).toDomain().status,
      );

      expect(statuses, StickerStatus.values);
    });
  });

  group('TeamAlbumGroupApiModelMapper', () {
    test('maps the team and keeps the order of the stickers', () {
      const model = TeamAlbumGroupApiModel(
        team: _teamApi,
        stickers: [
          AlbumPositionApiModel(
            code: 'BRA-1',
            number: 1,
            status: StickerStatus.owned,
            repeated: 0,
          ),
          AlbumPositionApiModel(
            code: 'BRA-2',
            number: 2,
            status: StickerStatus.missing,
            repeated: 0,
          ),
        ],
      );

      final group = model.toDomain();

      expect(group.team, _team);
      expect(group.stickers.map((s) => s.number), [1, 2]);
      expect(group.stickers.map((s) => s.status), [
        StickerStatus.owned,
        StickerStatus.missing,
      ]);
    });

    test('maps a team without stickers', () {
      const model = TeamAlbumGroupApiModel(team: _teamApi, stickers: []);

      expect(model.toDomain(), const TeamAlbumGroup(team: _team, stickers: []));
    });
  });

  group('AlbumApiModelMapper', () {
    test('maps the teams and the loose stickers', () {
      const model = AlbumApiModel(
        teams: [
          TeamAlbumGroupApiModel(
            team: _teamApi,
            stickers: [
              AlbumPositionApiModel(
                code: 'BRA-1',
                number: 1,
                status: StickerStatus.owned,
                repeated: 0,
              ),
            ],
          ),
        ],
        loose: [
          AlbumPositionApiModel(
            code: 'FWC-1',
            number: 1,
            status: StickerStatus.repeated,
            repeated: 3,
          ),
        ],
      );

      expect(
        model.toDomain(),
        const Album(
          teams: [
            TeamAlbumGroup(
              team: _team,
              stickers: [
                AlbumPosition(
                  code: 'BRA-1',
                  number: 1,
                  status: StickerStatus.owned,
                  repeated: 0,
                ),
              ],
            ),
          ],
          loose: [
            AlbumPosition(
              code: 'FWC-1',
              number: 1,
              status: StickerStatus.repeated,
              repeated: 3,
            ),
          ],
        ),
      );
    });

    test('maps an empty album', () {
      const model = AlbumApiModel(teams: [], loose: []);

      expect(model.toDomain(), const Album(teams: [], loose: []));
    });
  });
}
