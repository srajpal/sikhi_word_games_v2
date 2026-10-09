enum GameArtworkKind { deduction, search, garden, bridges, letters, scramble }

/// Bundled artwork keeps the same tactile setting available offline.
abstract final class PaperAssets {
  static const texture = 'assets/artwork/paper_play/paper.webp';
  static String scene(GameArtworkKind kind) =>
      'assets/artwork/paper_play/${switch (kind) {
        GameArtworkKind.deduction => 'bujho',
        GameArtworkKind.search => 'khoj',
        GameArtworkKind.garden => 'quest',
        GameArtworkKind.bridges => 'jodo',
        GameArtworkKind.letters => 'letters',
        GameArtworkKind.scramble => 'scramble',
      }}.webp';
}
