import 'package:flutter_test/flutter_test.dart';
import 'package:wc_2026_mobile/data/services/api/mappers/recent_sticker_api_model_mapper.dart';
import 'package:wc_2026_mobile/data/services/api/model/album/recent_sticker_api_model.dart';
import 'package:wc_2026_mobile/data/services/api/model/team/team_api_model.dart';
import 'package:wc_2026_mobile/domain/models/album/recent_sticker.dart';
import 'package:wc_2026_mobile/domain/models/team/team.dart';

void main() {
  group('RecentStickerApiModelMapper', () {
    test('maps the sticker with its team', () {
      const model = RecentStickerApiModel(
        code: 'BRA-1',
        number: 1,
        repeated: 2,
        team: TeamApiModel(
          code: 'BRA',
          name: 'Brazil',
          flagUrl: '/flags/bra.png',
          primaryColor: '#FFDF00',
        ),
      );

      expect(
        model.toDomain(),
        const RecentSticker(
          code: 'BRA-1',
          number: 1,
          repeated: 2,
          team: Team(
            code: 'BRA',
            name: 'Brazil',
            flagUrl: '/flags/bra.png',
            primaryColor: 0xFFFFDF00,
          ),
        ),
      );
    });

    test('maps the sticker without a team', () {
      const model = RecentStickerApiModel(
        code: 'FWC-9',
        number: 9,
        repeated: 0,
      );

      expect(
        model.toDomain(),
        const RecentSticker(code: 'FWC-9', number: 9, repeated: 0),
      );
    });
  });
}
