import '../../features/game_library/domain/game_launch_options.dart';
import 'key_value_store.dart';

/// A separate marker per game avoids read/modify/write races between routes.
class GameGuideRepository {
  const GameGuideRepository(this._store);

  final KeyValueStore _store;

  bool hasSeen(GameKind game) =>
      _store.getString('gameGuide.v1.${game.name}') == 'seen';

  Future<void> markSeen(GameKind game) => KeyValueStoreWrites.setString(
    _store,
    'gameGuide.v1.${game.name}',
    'seen',
  );

  Future<void> resetAll() async {
    for (final game in GameKind.values) {
      await KeyValueStoreWrites.remove(_store, 'gameGuide.v1.${game.name}');
    }
  }
}
