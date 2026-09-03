import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/shared/focus/focusable_card.dart';
import 'package:iptv/shared/focus/remote_focus.dart';
import 'package:iptv/shared/focus/tv_focusable.dart';
import 'package:iptv/shared/widgets/favorite_toggle_button.dart';

Widget _tvApp({required Widget home}) {
  return RemoteFocusScope(
    child: MaterialApp(
      builder: Dpad.wrap(),
      home: home,
    ),
  );
}

void main() {
  setUp(RemoteFocus.reset);
  tearDown(RemoteFocus.reset);

  testWidgets('D-pad select activates FocusableCard', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      _tvApp(
        home: Scaffold(
          body: FocusableCard(
            autofocus: true,
            onTap: () => tapped = true,
            child: const SizedBox(
              width: 120,
              height: 80,
              child: Text('Card'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('arrow keys move focus between TvFocusable items', (tester) async {
    var selected = '';

    await tester.pumpWidget(
      _tvApp(
        home: Scaffold(
          body: Row(
            children: [
              TvFocusable(
                autofocus: true,
                onSelect: () => selected = 'left',
                child: const SizedBox(
                  width: 80,
                  height: 40,
                  child: Text('Left'),
                ),
              ),
              TvFocusable(
                onSelect: () => selected = 'right',
                child: const SizedBox(
                  width: 80,
                  height: 40,
                  child: Text('Right'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();

    expect(selected, 'right');
  });

  testWidgets('focus ring stays off until a remote key is pressed', (
    tester,
  ) async {
    await tester.pumpWidget(
      _tvApp(
        home: Scaffold(
          body: FocusableCard(
            autofocus: true,
            onTap: () {},
            child: const SizedBox(
              width: 120,
              height: 80,
              child: Text('Card'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(RemoteFocus.armed.value, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(RemoteFocus.armed.value, isTrue);
  });

  testWidgets('left from a poster focuses the favorite heart', (tester) async {
    await tester.pumpWidget(
      _tvApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 220,
            child: PosterHeartCard(
              autofocus: true,
              onTap: () {},
              favorite: (heartFocus, onHeartDirection) => TvFocusable(
                focusNode: heartFocus,
                onDirection: onHeartDirection,
                onSelect: () {},
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: Text('Heart'),
                ),
              ),
              child: const SizedBox.expand(child: Text('Poster')),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'poster');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'favorite');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'poster');
  });

  testWidgets('rtl poster keeps heart at start opposite the rating end',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 180,
                height: 220,
                child: PosterHeartCard(
                  onTap: () {},
                  favorite: (heartFocus, onHeartDirection) => SizedBox(
                    key: const Key('heart'),
                    width: 28,
                    height: 28,
                    child: Focus(focusNode: heartFocus, child: const Text('H')),
                  ),
                  child: const Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: Colors.grey),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: PosterTopActions(compact: true, rating: '8.5'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cardBox = tester.getTopLeft(find.byType(PosterHeartCard));
    final cardSize = tester.getSize(find.byType(PosterHeartCard));
    final heartCenter = tester.getCenter(find.byKey(const Key('heart')));
    final ratingCenter = tester.getCenter(find.text('8.5'));

    // In RTL, start is the right edge — heart must sit on that side.
    expect(heartCenter.dx, greaterThan(cardBox.dx + cardSize.width / 2));
    // Rating stays on the end (left) side.
    expect(ratingCenter.dx, lessThan(cardBox.dx + cardSize.width / 2));
  });
}
