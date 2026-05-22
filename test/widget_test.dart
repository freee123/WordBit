import 'package:flutter_test/flutter_test.dart';
import 'package:wordbit/app.dart';

void main() {
  testWidgets('App renders home page', (WidgetTester tester) async {
    await tester.pumpWidget(const MemoryWordsApp());
    expect(find.text('我的词库'), findsOneWidget);
    expect(find.text('还没有单词，点击下方按钮添加'), findsOneWidget);
  });
}
