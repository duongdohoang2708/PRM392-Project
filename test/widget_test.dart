import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_flow/main.dart';
import 'package:task_flow/providers/settings_provider.dart';
import 'package:task_flow/providers/user_provider.dart';

void main() {
  testWidgets('TaskFlow app smoke test', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    final settingsProvider = SettingsProvider();
    final userProvider = UserProvider();
    await settingsProvider.load();
    await userProvider.load();

    await tester.pumpWidget(
      MyApp(
        settingsProvider: settingsProvider,
        userProvider: userProvider,
      ),
    );

    expect(find.text('TaskFlow'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
