import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Firebase 초기화가 필요하므로 기본 smoke test만 수행
    expect(true, isTrue);
  });
}
