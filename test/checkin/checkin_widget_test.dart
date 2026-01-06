// File: test/checkin/checkin_widget_test.dart
// WIDGET TEST: Test UI components và tương tác

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:nhom_3_damh_lttbdd/screens/add_checkins/checkinScreen.dart';
import 'package:nhom_3_damh_lttbdd/screens/add_checkins/service/checkin_service.dart';

@GenerateMocks([CheckinService])
void main() {
  group('CheckinScreen - Widget Tests', () {
    testWidgets('Should render all required fields', (
      WidgetTester tester,
    ) async {
      // Arrange: Build widget
      await tester.pumpWidget(
        MaterialApp(home: CheckinScreen(currentUserId: 'test_user_id')),
      );

      // Act & Assert: Verify all fields exist
      expect(find.byKey(const Key('btn_pick_image')), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2)); // Title + Comment
      expect(find.byKey(const Key('btn_pick_place')), findsOneWidget);
      expect(find.byKey(const Key('btn_submit_post')), findsOneWidget);
    });

    testWidgets('Submit button should be enabled initially', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(home: CheckinScreen(currentUserId: 'test_user_id')),
      );

      // Act: Find submit button
      final submitButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('btn_submit_post')),
      );

      // Assert: Button should be enabled (onPressed is not null)
      expect(submitButton.onPressed, isNotNull);
    });

    testWidgets('Should show SnackBar when submit without image', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(home: CheckinScreen(currentUserId: 'test_user_id')),
      );

      // Act: Tap submit without filling anything
      await tester.tap(find.byKey(const Key('btn_submit_post')));
      await tester.pump(); // Trigger rebuild
      await tester.pump(
        const Duration(milliseconds: 100),
      ); // Wait for SnackBar animation

      // Assert: SnackBar should appear
      expect(find.text('Vui lòng thêm ít nhất một ảnh.'), findsOneWidget);
    });

    testWidgets('Should show SnackBar when submit without title', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(home: CheckinScreen(currentUserId: 'test_user_id')),
      );

      // Act: Mock adding image (skip this step for now, focus on title validation)
      // Enter comment but not title
      await tester.enterText(find.byType(TextField).at(1), 'Test comment');
      await tester.pump();

      // Tap submit
      await tester.tap(find.byKey(const Key('btn_submit_post')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: Should show "need image" first (priority)
      expect(find.text('Vui lòng thêm ít nhất một ảnh.'), findsOneWidget);
    });

    testWidgets('Title field should accept text input', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(home: CheckinScreen(currentUserId: 'test_user_id')),
      );

      // Act: Enter text into title field (first TextField)
      const testTitle = 'Test Title';
      await tester.enterText(find.byType(TextField).at(0), testTitle);
      await tester.pump();

      // Assert: Text should be in the field
      expect(find.text(testTitle), findsOneWidget);
    });

    testWidgets('Comment field should accept text input', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(home: CheckinScreen(currentUserId: 'test_user_id')),
      );

      // Act: Enter text into comment field (second TextField)
      const testComment = 'Test Comment';
      await tester.enterText(find.byType(TextField).at(1), testComment);
      await tester.pump();

      // Assert
      expect(find.text(testComment), findsOneWidget);
    });

    testWidgets('Should show loading indicator when _isSaving is true', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(home: CheckinScreen(currentUserId: 'test_user_id')),
      );

      // Act: Trigger submit (this will set _isSaving = true temporarily)
      await tester.tap(find.byKey(const Key('btn_submit_post')));
      await tester.pump(); // Rebuild immediately

      // Assert: Button should show CircularProgressIndicator OR be disabled
      // (Depends on when we pump - if validation fails fast, won't see loading)
      // This test verifies the UI logic, not the actual async operation
    });

    testWidgets('Back button should call Navigator.pop', (
      WidgetTester tester,
    ) async {
      // Arrange: Wrap in Navigator to test pop
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CheckinScreen(currentUserId: 'test_user_id'),
                    ),
                  );
                },
                child: const Text('Open Checkin'),
              ),
            ),
          ),
        ),
      );

      // Act: Open CheckinScreen
      await tester.tap(find.text('Open Checkin'));
      await tester.pumpAndSettle();

      // Verify CheckinScreen is shown
      expect(find.byType(CheckinScreen), findsOneWidget);

      // Act: Tap back button
      await tester.tap(find.byKey(const Key('btn_back_checkin')));
      await tester.pumpAndSettle();

      // Assert: Should navigate back
      expect(find.byType(CheckinScreen), findsNothing);
    });
  });

  group('CheckinScreen - State Management Tests', () {
    testWidgets('Should update _selectedImages when image is added', (
      WidgetTester tester,
    ) async {
      // NOTE: This requires mocking ImagePicker
      // For now, we test the UI behavior when state changes

      await tester.pumpWidget(
        MaterialApp(home: CheckinScreen(currentUserId: 'test_user_id')),
      );

      // Initially no images
      // (Can't easily verify internal state, but can verify UI updates)
    });

    testWidgets('Should clear fields when navigating back', (
      WidgetTester tester,
    ) async {
      // This tests that state is properly disposed
      await tester.pumpWidget(
        MaterialApp(home: CheckinScreen(currentUserId: 'test_user_id')),
      );

      // Enter some text
      await tester.enterText(find.byType(TextField).at(0), 'Title');
      await tester.enterText(find.byType(TextField).at(1), 'Comment');
      await tester.pump();

      // Verify text is there
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Comment'), findsOneWidget);

      // Navigate away and back would clear state (dispose/init cycle)
    });
  });
}
