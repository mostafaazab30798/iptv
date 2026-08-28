import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/features/live/live_controller.dart';
import 'package:iptv/features/movies/movies_controller.dart';
import 'package:iptv/features/search/search_controller.dart';
import 'package:iptv/features/series/series_controller.dart';

void main() {
  test(
    'catalog controllers dispose after their final listener closes',
    () async {
      final container = ProviderContainer(
        overrides: [
          liveRepositoryProvider.overrideWithValue(null),
          vodRepositoryProvider.overrideWithValue(null),
          seriesRepositoryProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      final subscriptions = <ProviderSubscription<Object?>>[
        container.listen(
          liveControllerProvider,
          (_, _) {},
          fireImmediately: true,
        ),
        container.listen(
          moviesControllerProvider,
          (_, _) {},
          fireImmediately: true,
        ),
        container.listen(
          seriesControllerProvider,
          (_, _) {},
          fireImmediately: true,
        ),
        container.listen(
          searchControllerProvider,
          (_, _) {},
          fireImmediately: true,
        ),
      ];

      container.read(liveControllerProvider.notifier).search('sports');
      container.read(moviesControllerProvider.notifier).search('action');
      container.read(seriesControllerProvider.notifier).search('drama');
      unawaited(
        container.read(searchControllerProvider.notifier).search('news'),
      );

      for (final subscription in subscriptions) {
        subscription.close();
      }
      await Future<void>.delayed(Duration.zero);

      expect(container.exists(liveControllerProvider), isFalse);
      expect(container.exists(moviesControllerProvider), isFalse);
      expect(container.exists(seriesControllerProvider), isFalse);
      expect(container.exists(searchControllerProvider), isFalse);
    },
  );
}
