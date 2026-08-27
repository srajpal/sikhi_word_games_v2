import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/app/app.dart';

void main() {
  testWidgets('renders the foundation prototype', (tester) async {
    await tester.pumpWidget(const SikhiWordGamesApp());
    expect(find.text('Guess the Word'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Modern'), findsOneWidget);
  });
}
