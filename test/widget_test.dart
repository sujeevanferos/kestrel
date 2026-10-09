import 'package:flutter_test/flutter_test.dart';
import 'package:kestrel/main.dart';
import 'package:kestrel/canvas/whiteboard_canvas.dart';

void main() {
  testWidgets('Kestrel app launches directly into whiteboard canvas', (WidgetTester tester) async {
    await tester.pumpWidget(const KestrelApp());
    await tester.pumpAndSettle();

    // Verify whiteboard canvas is present immediately on launch
    expect(find.byType(WhiteboardCanvas), findsOneWidget);
    expect(find.text('KESTREL'), findsOneWidget);
  });
}
