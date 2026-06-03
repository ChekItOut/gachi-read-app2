import 'package:flutter_test/flutter_test.dart';
import 'package:gachi_read_app/data/services/bible_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    expect(true, isTrue);
  });

  test('chapter reading plan returns all daily chapters', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final bibleService = BibleService.instance;
    await bibleService.loadBible();

    final reading = bibleService.calculateTodayReading(
      startBook: '레',
      startChapter: 1,
      startVerse: 1,
      dailyChapters: 3,
      dailyVerses: 0,
      planStartDate: DateTime.now(),
    );

    final passages = reading['passages'] as List;
    expect(passages, hasLength(3));
    expect(reading['rangeText'], '레위기 1:1-3:17');
    expect(bibleService.getReadingVerses(reading), hasLength(50));
  });
}
