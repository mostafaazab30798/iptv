import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/player/handoff/application/companion_input_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CompanionInputManager Unit Tests', () {
    late CompanionInputManager inputManager;

    setUp(() {
      inputManager = CompanionInputManager();
      inputManager.updateScreenSize(const Size(1920, 1080));
    });

    tearDown(() {
      inputManager.dispose();
    });

    test('Initial state starts centered with cursor hidden', () {
      expect(inputManager.state.cursorPosition, const Offset(960, 540));
      expect(inputManager.state.isCursorVisible, isFalse);
      expect(inputManager.state.isMouseDown, isFalse);
      expect(inputManager.state.sensitivity, 1.0);
    });

    test('handleMouseMove moves cursor position and sets visible', () {
      inputManager.handleMouseMove(50, -30);

      expect(inputManager.state.cursorPosition, const Offset(1010, 510));
      expect(inputManager.state.isCursorVisible, isTrue);
      expect(inputManager.state.lastAction, 'move');
    });

    test('Cursor position is clamped within screen boundary limits', () {
      // Move way beyond bottom-right
      inputManager.handleMouseMove(5000, 5000);
      expect(inputManager.state.cursorPosition.dx, 1920.0);
      expect(inputManager.state.cursorPosition.dy, 1080.0);

      // Move way beyond top-left
      inputManager.handleMouseMove(-10000, -10000);
      expect(inputManager.state.cursorPosition.dx, 0.0);
      expect(inputManager.state.cursorPosition.dy, 0.0);
    });

    test('Sensitivity scales cursor movement deltas', () {
      inputManager.setSensitivity(2.0);
      expect(inputManager.state.sensitivity, 2.0);

      final prevPos = inputManager.state.cursorPosition; // (960, 540)
      inputManager.handleMouseMove(10, 20);
      final newPos = inputManager.state.cursorPosition;

      expect(newPos.dx - prevPos.dx, 20.0); // 10 * 2.0
      expect(newPos.dy - prevPos.dy, 40.0); // 20 * 2.0
    });


    test('handleMouseTap sets isMouseDown and records lastClickEpoch', () async {
      inputManager.handleMouseTap();

      expect(inputManager.state.isMouseDown, isTrue);
      expect(inputManager.state.isCursorVisible, isTrue);
      expect(inputManager.state.lastAction, 'tap');
      expect(inputManager.state.lastClickEpoch, greaterThan(0));

      // Wait for release
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(inputManager.state.isMouseDown, isFalse);
    });

    test('handleMouseClick down and up updates state properly', () {
      inputManager.handleMouseClick(button: 'left', down: true);
      expect(inputManager.state.isMouseDown, isTrue);
      expect(inputManager.state.lastAction, 'click_down');

      inputManager.handleMouseClick(button: 'left', down: false);
      expect(inputManager.state.isMouseDown, isFalse);
      expect(inputManager.state.lastAction, 'click_up');
    });

    test('handleMouseScroll updates action state', () {
      inputManager.handleMouseScroll(0, -50);
      expect(inputManager.state.isCursorVisible, isTrue);
      expect(inputManager.state.lastAction, 'scroll');
    });

    test('updateScreenGeometry maps overlay origin independently of cursor', () {
      inputManager.handleMouseMove(10, 0);
      final local = inputManager.state.cursorPosition;

      inputManager.updateScreenGeometry(
        const Size(1920, 1080),
        const Offset(24, 48),
      );

      expect(inputManager.state.cursorPosition, local);
    });
  });

  group('Companion Text Injection Widget Test', () {
    testWidgets('handleTypeText inserts text into focused EditableText / TextField',
        (tester) async {
      final inputManager = CompanionInputManager();
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              controller: controller,
              autofocus: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify TextField has focus
      expect(FocusManager.instance.primaryFocus, isNotNull);

      // Inject text remotely from companion
      inputManager.handleTypeText('Interstellar');
      await tester.pump();

      expect(controller.text, 'Interstellar');

      // Append more text
      inputManager.handleTypeText(' 4K');
      await tester.pump();

      expect(controller.text, 'Interstellar 4K');

      // Backspace
      inputManager.handleKeyPress('backspace');
      await tester.pump();

      expect(controller.text, 'Interstellar 4');

      // Replace text
      inputManager.handleTypeText('Dune 2', replace: true);
      await tester.pump();

      expect(controller.text, 'Dune 2');

      inputManager.dispose();
      controller.dispose();
    });
  });
}
