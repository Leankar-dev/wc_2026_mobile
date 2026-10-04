import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wc_2026_mobile/core/exceptions/app_exception.dart';
import 'package:wc_2026_mobile/core/result.dart';
import 'package:wc_2026_mobile/data/repositories/album/album_repository_remote.dart';
import 'package:wc_2026_mobile/data/services/api/album_api.dart';
import 'package:wc_2026_mobile/data/services/api/model/album/album_api_model.dart';
import 'package:wc_2026_mobile/data/services/api/model/album/album_position_api_model.dart';
import 'package:wc_2026_mobile/data/services/api/model/album/album_summary_api_model.dart';
import 'package:wc_2026_mobile/data/services/api/model/album/recent_sticker_api_model.dart';
import 'package:wc_2026_mobile/data/services/api/model/album/team_album_group_api_model.dart';
import 'package:wc_2026_mobile/data/services/api/model/team/team_api_model.dart';
import 'package:wc_2026_mobile/domain/models/album/album.dart';
import 'package:wc_2026_mobile/domain/models/album/album_position.dart';
import 'package:wc_2026_mobile/domain/models/album/album_summary.dart';
import 'package:wc_2026_mobile/domain/models/album/recent_sticker.dart';
import 'package:wc_2026_mobile/domain/models/album/sticker_status.dart';
import 'package:wc_2026_mobile/domain/models/album/team_album_group.dart';
import 'package:wc_2026_mobile/domain/models/team/team.dart';

class _FakeAlbumApi implements AlbumApi {
  Object? failure;
  AlbumApiModel album = const AlbumApiModel(teams: [], loose: []);
  AlbumSummaryApiModel summary = const AlbumSummaryApiModel(
    total: 980,
    missing: 300,
    repeated: 12,
  );
  RecentStickersApiModel recent = const RecentStickersApiModel(stickers: []);

  final albumCalls = <({String? status, String? team})>[];

  void _failIfNeeded() {
    if (failure case final failure?) throw failure;
  }

  @override
  Future<AlbumApiModel> getAlbum({String? status, String? team}) async {
    albumCalls.add((status: status, team: team));
    _failIfNeeded();
    return album;
  }

  @override
  Future<AlbumSummaryApiModel> getSummary() async {
    _failIfNeeded();
    return summary;
  }

  @override
  Future<RecentStickersApiModel> getRecent() async {
    _failIfNeeded();
    return recent;
  }
}

DioException _dioError(DioExceptionType type, {int? status}) => DioException(
  requestOptions: RequestOptions(path: '/v1/album'),
  type: type,
  response: status == null
      ? null
      : Response(
          requestOptions: RequestOptions(path: '/v1/album'),
          statusCode: status,
        ),
);

AppException _errorOf<T>(Result<T> result) => (result as Error<T>).error;

void main() {
  late _FakeAlbumApi api;
  late AlbumRepositoryRemote repository;

  setUp(() {
    api = _FakeAlbumApi();
    repository = AlbumRepositoryRemote(albumApi: api);
  });

  group('AlbumRepositoryRemote.getAlbum', () {
    test('maps the api album to the domain', () async {
      api.album = const AlbumApiModel(
        teams: [
          TeamAlbumGroupApiModel(
            team: TeamApiModel(
              code: 'BRA',
              name: 'Brazil',
              flagUrl: '/flags/bra.png',
              primaryColor: '#FFDF00',
            ),
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
        loose: [],
      );

      final result = await repository.getAlbum();

      expect(
        (result as Ok<Album>).value,
        const Album(
          teams: [
            TeamAlbumGroup(
              team: Team(
                code: 'BRA',
                name: 'Brazil',
                flagUrl: '/flags/bra.png',
                primaryColor: 0xFFFFDF00,
              ),
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
          loose: [],
        ),
      );
    });

    test('sends no filter when none is given', () async {
      await repository.getAlbum();

      expect(api.albumCalls, [(status: null, team: null)]);
    });

    test('sends the status name and the team code as filters', () async {
      await repository.getAlbum(status: StickerStatus.missing, team: 'BRA');
      await repository.getAlbum(status: StickerStatus.repeated);
      await repository.getAlbum(team: 'ARG');

      expect(api.albumCalls, [
        (status: 'missing', team: 'BRA'),
        (status: 'repeated', team: null),
        (status: null, team: 'ARG'),
      ]);
    });

    test('maps a connection failure to a network error', () async {
      api.failure = _dioError(DioExceptionType.connectionError);

      expect(_errorOf(await repository.getAlbum()), isA<NetworkException>());
    });

    test('maps a 401 to an unauthorized error', () async {
      api.failure = _dioError(DioExceptionType.badResponse, status: 401);

      expect(
        _errorOf(await repository.getAlbum()),
        isA<UnauthorizedException>(),
      );
    });

    test('maps a 500 to a server error', () async {
      api.failure = _dioError(DioExceptionType.badResponse, status: 500);

      expect(_errorOf(await repository.getAlbum()), isA<ServerException>());
    });
  });

  group('AlbumRepositoryRemote.getSummary', () {
    test('maps the summary to the domain', () async {
      final result = await repository.getSummary();

      expect(
        (result as Ok<AlbumSummary>).value,
        const AlbumSummary(total: 980, missing: 300, repeated: 12),
      );
    });

    test('maps a timeout to a network error', () async {
      api.failure = _dioError(DioExceptionType.receiveTimeout);

      expect(_errorOf(await repository.getSummary()), isA<NetworkException>());
    });
  });

  group('AlbumRepositoryRemote.getRecentStickers', () {
    test('maps the recent stickers with their team', () async {
      api.recent = const RecentStickersApiModel(
        stickers: [
          RecentStickerApiModel(
            code: 'BRA-1',
            number: 1,
            repeated: 2,
            team: TeamApiModel(
              code: 'BRA',
              name: 'Brazil',
              flagUrl: '/flags/bra.png',
              primaryColor: '#FFDF00',
            ),
          ),
          RecentStickerApiModel(code: 'FWC-9', number: 9, repeated: 0),
        ],
      );

      final result = await repository.getRecentStickers();
      final stickers = (result as Ok<List<RecentSticker>>).value;

      expect(stickers.map((s) => s.code), ['BRA-1', 'FWC-9']);
      expect(stickers.first.team?.name, 'Brazil');
      expect(stickers.last.team, isNull);
    });

    test('maps a 404 to a not found error', () async {
      api.failure = _dioError(DioExceptionType.badResponse, status: 404);

      expect(
        _errorOf(await repository.getRecentStickers()),
        isA<NotFoundException>(),
      );
    });
  });
}
