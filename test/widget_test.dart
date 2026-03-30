import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_automator/main.dart';
import 'package:attendance_automator/injection_container.dart' as di;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await di.init();

    // Build our app and trigger a frame.
    await tester.pumpWidget(const AttendanceAutomatorApp());

    // Verify that our app starts and shows the title.
    expect(find.text('Attendance Automator'), findsOneWidget);
    expect(find.text('Execute'), findsOneWidget);
  });
}
