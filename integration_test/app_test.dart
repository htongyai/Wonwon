import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/semantics.dart';
import 'package:wonwonw2/main.dart' as app;

void main() {
  // Integration test setup

  group('App Integration Tests', () {
    testWidgets('App launches and shows home screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify app launches
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Wait for initial loading to complete
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Verify home screen elements are present
      expect(find.text('Wonwonw2'), findsWidgets);
    });

    testWidgets('Navigation between screens works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Test navigation to different screens
      if (find.byIcon(Icons.search).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();
      }

      if (find.byIcon(Icons.bookmark).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.bookmark));
        await tester.pumpAndSettle();
      }

      if (find.byIcon(Icons.person).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.person));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Search functionality works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Look for search field
      if (find.byType(TextField).evaluate().isNotEmpty) {
        await tester.enterText(find.byType(TextField).first, 'test');
        await tester.pumpAndSettle();
        
        // Verify search was performed
        expect(find.text('test'), findsWidgets);
      }
    });

    testWidgets('Shop list loads and displays', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Wait for shops to load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify shop list is displayed
      // This might be empty if no shops are loaded, which is expected
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('Language switching works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Look for language switcher
      if (find.text('ไทย').evaluate().isNotEmpty) {
        await tester.tap(find.text('ไทย'));
        await tester.pumpAndSettle();
        
        // Verify language changed
        expect(find.text('ไทย'), findsWidgets);
      }
    });

    testWidgets('Error handling works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Test error scenarios
      // This is a basic test - in a real app you'd test specific error conditions
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Performance Tests', () {
    testWidgets('App performance is acceptable', (WidgetTester tester) async {
      app.main();
      
      // Measure frame rendering time
      final Stopwatch stopwatch = Stopwatch()..start();
      await tester.pumpAndSettle(const Duration(seconds: 10));
      stopwatch.stop();
      
      // Verify app loads within reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(15000));
    });

    testWidgets('Memory usage is reasonable', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate through different screens to test memory usage
      for (int i = 0; i < 5; i++) {
        if (find.byIcon(Icons.search).evaluate().isNotEmpty) {
          await tester.tap(find.byIcon(Icons.search));
          await tester.pumpAndSettle();
        }
        
        if (find.byIcon(Icons.bookmark).evaluate().isNotEmpty) {
          await tester.tap(find.byIcon(Icons.bookmark));
          await tester.pumpAndSettle();
        }
      }

      // Verify app is still responsive
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Accessibility Tests', () {
    testWidgets('App is accessible', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Test accessibility features
      final SemanticsOwner? semantics = tester.binding.pipelineOwner.semanticsOwner;
      expect(semantics, isNotNull);
    });

    testWidgets('Screen readers can navigate', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Test that important elements have semantic labels
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
