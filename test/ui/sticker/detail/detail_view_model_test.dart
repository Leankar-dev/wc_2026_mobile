import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wc_2026_mobile/core/exceptions/app_exception.dart';
import 'package:wc_2026_mobile/core/result.dart';
import 'package:wc_2026_mobile/data/repositories/album/album_repository.dart';
import 'package:wc_2026_mobile/domain/models/album/album.dart';
import 'package:wc_2026_mobile/domain/models/album/album_summary.dart';
import 'package:wc_2026_mobile/domain/models/album/recent_sticker.dart';
import 'package:wc_2026_mobile/domain/models/album/sticker_status.dart';
import 'package:wc_2026_mobile/ui/sticker/detail/detail_view_model.dart';

class _FakeAlbumRepository implements AlbumRepository {
  Result<void> registerResult = Result.done;
  Result<void> updateResult = Result.done;
  Result<void> removeResult = Result.done;
  Completer<void>? gate;

  final registered = <({String code, int quantity})>[];
  final updated = <({String code, int quantity})>[];
  final removed = <String>[];

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
  }) async {
    updated.add((code: code, quantity: quantity));
    await gate?.future;
    return updateResult;
  }

  @override
  Future<Result<void>> removeSticker(String code) async {
    removed.add(code);
    await gate?.future;
    return removeResult;
  }

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

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeAlbumRepository repository;
  late DetailViewModel viewModel;
  var disposed = false;

  DetailViewModel build({int count = 2}) =>
      DetailViewModel(albumRepository: repository, code: 'BRA-1', count: count);

  setUp(() {
    repository = _FakeAlbumRepository();
    viewModel = build();
    disposed = false;
  });

  tearDown(() {
    if (!disposed) viewModel.dispose();
  });

  group('DetailViewModel state', () {
    test('starts with the count it was given', () {
      expect(viewModel.count, 2);
      expect(viewModel.collected, isTrue);
      expect(viewModel.inAlbum, isTrue);
      expect(viewModel.busy, isFalse);
    });

    test('starts a missing sticker out of the album', () {
      viewModel.dispose();
      viewModel = build(count: 0);

      expect(viewModel.count, 0);
      expect(viewModel.collected, isFalse);
      expect(viewModel.inAlbum, isFalse);
    });

    test('changeCount updates the count and notifies', () {
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      viewModel.changeCount(5);

      expect(viewModel.count, 5);
      expect(notifications, 1);
    });

    test('changeCount ignores the same value', () {
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      viewModel.changeCount(2);

      expect(notifications, 0);
    });

    test('changeCount to zero marks the sticker as not collected', () {
      viewModel.changeCount(0);

      expect(viewModel.collected, isFalse);
      expect(viewModel.inAlbum, isTrue);
    });

    test('changeCount accepts a negative count without limits for now', () {
      viewModel.changeCount(-3);

      expect(viewModel.count, -3);
      expect(viewModel.collected, isFalse);
    });

    test('changeCount does not touch the repository', () async {
      viewModel.changeCount(9);
      await _settle();

      expect(repository.registered, isEmpty);
      expect(repository.updated, isEmpty);
      expect(repository.removed, isEmpty);
    });
  });

  group('DetailViewModel save', () {
    test('updates a sticker that is already in the album', () async {
      viewModel.changeCount(5);

      await viewModel.save.execute();

      expect(repository.updated, [(code: 'BRA-1', quantity: 5)]);
      expect(repository.registered, isEmpty);
    });

    test('registers a sticker that is not in the album yet', () async {
      viewModel.dispose();
      viewModel = build(count: 0);
      viewModel.changeCount(3);

      await viewModel.save.execute();

      expect(repository.registered, [(code: 'BRA-1', quantity: 3)]);
      expect(repository.updated, isEmpty);
    });

    test(
      'registers one copy when saving a missing sticker with zero',
      () async {
        viewModel.dispose();
        viewModel = build(count: 0);

        await viewModel.save.execute();

        expect(repository.registered, [(code: 'BRA-1', quantity: 1)]);
        expect(viewModel.count, 1);
      },
    );

    test('saves one copy instead of zero on a sticker in the album', () async {
      viewModel.changeCount(0);

      await viewModel.save.execute();

      expect(repository.updated, [(code: 'BRA-1', quantity: 1)]);
      expect(viewModel.count, 1);
    });

    test('saves one copy instead of a negative count', () async {
      viewModel.changeCount(-4);

      await viewModel.save.execute();

      expect(repository.updated, [(code: 'BRA-1', quantity: 1)]);
    });

    test('puts the sticker in the album after registering', () async {
      viewModel.dispose();
      viewModel = build(count: 0);
      viewModel.changeCount(2);

      await viewModel.save.execute();

      expect(viewModel.inAlbum, isTrue);
      expect(viewModel.collected, isTrue);
      expect(viewModel.count, 2);
    });

    test('updates instead of registering on the second save', () async {
      viewModel.dispose();
      viewModel = build(count: 0);
      viewModel.changeCount(2);
      await viewModel.save.execute();

      viewModel.changeCount(4);
      await viewModel.save.execute();

      expect(repository.registered, hasLength(1));
      expect(repository.updated, [(code: 'BRA-1', quantity: 4)]);
    });

    test('reports success', () async {
      await viewModel.save.execute();

      expect(viewModel.save.complete, isTrue);
      expect(viewModel.save.error, isFalse);
    });

    test('keeps the state when the save fails', () async {
      repository.updateResult = Result.error(const NetworkException());
      viewModel.changeCount(7);

      await viewModel.save.execute();

      expect(viewModel.save.error, isTrue);
      expect(viewModel.count, 7);
      expect(viewModel.inAlbum, isTrue);
    });

    test(
      'keeps a new sticker out of the album when the register fails',
      () async {
        repository.registerResult = Result.error(const ServerException());
        viewModel.dispose();
        viewModel = build(count: 0);
        viewModel.changeCount(3);

        await viewModel.save.execute();

        expect(viewModel.save.error, isTrue);
        expect(viewModel.inAlbum, isFalse);
      },
    );

    test('registers again after a failed register', () async {
      repository.registerResult = Result.error(const ServerException());
      viewModel.dispose();
      viewModel = build(count: 0);
      viewModel.changeCount(3);
      await viewModel.save.execute();

      repository.registerResult = Result.done;
      await viewModel.save.execute();

      expect(repository.registered, hasLength(2));
      expect(viewModel.inAlbum, isTrue);
    });

    test('exposes the error of a failed save', () async {
      repository.updateResult = Result.error(const UnauthorizedException());

      await viewModel.save.execute();

      expect(
        (viewModel.save.result as Error).error,
        isA<UnauthorizedException>(),
      );
    });

    test('notifies listeners when the save finishes', () async {
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      await viewModel.save.execute();

      expect(notifications, 1);
    });

    test('notifies listeners when the save fails', () async {
      repository.updateResult = Result.error(const NetworkException());
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      await viewModel.save.execute();

      expect(notifications, 1);
    });
  });

  group('DetailViewModel remove', () {
    test('removes the sticker by its code', () async {
      await viewModel.remove.execute();

      expect(repository.removed, ['BRA-1']);
    });

    test('takes the sticker out of the album', () async {
      await viewModel.remove.execute();

      expect(viewModel.count, 0);
      expect(viewModel.collected, isFalse);
      expect(viewModel.inAlbum, isFalse);
    });

    test('keeps the state when the removal fails', () async {
      repository.removeResult = Result.error(const NotFoundException());

      await viewModel.remove.execute();

      expect(viewModel.remove.error, isTrue);
      expect(viewModel.count, 2);
      expect(viewModel.inAlbum, isTrue);
    });

    test('registers again when saving after a removal', () async {
      await viewModel.remove.execute();

      await viewModel.save.execute();

      expect(repository.registered, [(code: 'BRA-1', quantity: 1)]);
      expect(repository.updated, isEmpty);
    });

    test('notifies listeners when the removal finishes', () async {
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      await viewModel.remove.execute();

      expect(notifications, 1);
    });
  });

  group('DetailViewModel busy', () {
    test('is busy while a save is running', () async {
      repository.gate = Completer<void>();

      final saving = viewModel.save.execute();
      await _settle();

      expect(viewModel.busy, isTrue);

      repository.gate!.complete();
      await saving;

      expect(viewModel.busy, isFalse);
    });

    test('is busy while a removal is running', () async {
      repository.gate = Completer<void>();

      final removing = viewModel.remove.execute();
      await _settle();

      expect(viewModel.busy, isTrue);

      repository.gate!.complete();
      await removing;

      expect(viewModel.busy, isFalse);
    });

    test('ignores a second save while one is running', () async {
      repository.gate = Completer<void>();

      final first = viewModel.save.execute();
      await _settle();
      await viewModel.save.execute();

      expect(repository.updated, hasLength(1));

      repository.gate!.complete();
      await first;
    });

    test('lets a removal start while a save is running for now', () async {
      repository.gate = Completer<void>();

      final saving = viewModel.save.execute();
      await _settle();
      final removing = viewModel.remove.execute();
      await _settle();

      expect(repository.updated, hasLength(1));
      expect(repository.removed, hasLength(1));

      repository.gate!.complete();
      await Future.wait([saving, removing]);
    });
  });

  group('DetailViewModel disposal', () {
    test('fails to notify when disposed during a save for now', () async {
      repository.gate = Completer<void>();

      final saving = viewModel.save.execute();
      await _settle();
      viewModel.dispose();
      disposed = true;
      repository.gate!.complete();

      await expectLater(saving, throwsA(isA<FlutterError>()));
    });
  });
}
