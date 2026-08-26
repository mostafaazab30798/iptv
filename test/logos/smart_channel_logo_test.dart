import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/shared/widgets/smart_channel_logo.dart';

void main() {
  group('SmartChannelLogo Widget', () {
    testWidgets('Renders Image.asset for matched beIN Sports channel', (tester) async {
      const channel = Channel(
        id: 1,
        serverId: 1,
        streamId: 101,
        name: 'beIN Sports 1 HD',
        streamIcon: 'http://blocked-image.com/1.png',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartChannelLogo(channel: channel, width: 44, height: 44),
          ),
        ),
      );

      // Should contain an Image widget with AssetImage
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final imageWidget = tester.widget<Image>(imageFinder);
      expect(imageWidget.image, isA<AssetImage>());
      final assetImage = imageWidget.image as AssetImage;
      expect(assetImage.assetName, 'assets/logos/bein/bein_sports_1.webp');
    });

    testWidgets('Renders fallback initials when no logo is available', (tester) async {
      const channel = Channel(
        id: 2,
        serverId: 1,
        streamId: 201,
        name: 'National Geographic',
        streamIcon: null,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartChannelLogo(channel: channel, width: 44, height: 44),
          ),
        ),
      );

      expect(find.text('NG'), findsOneWidget);
    });

    testWidgets('Never crashes with empty channel or invalid data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartChannelLogo(channelName: '', width: 44, height: 44),
          ),
        ),
      );

      expect(find.byType(SmartChannelLogo), findsOneWidget);
    });
  });
}
