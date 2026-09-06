import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/bootstrap.dart';
import 'package:iptv/core/storage/database/app_database.dart' hide Channel;
import 'package:iptv/core/storage/secure_storage.dart';
import 'package:iptv/features/catalog_filter/excluded_live_categories_policy.dart';
import 'package:iptv/features/kids_mode/kids_content_policy.dart';
import 'package:iptv/features/kids_mode/kids_mode_controller.dart';
import 'package:iptv/features/kids_mode/kids_mode_state.dart';
import 'package:iptv/features/kids_mode/kids_mode_storage.dart';

final secureStorageProvider = Provider<SecureStorage>(
  (_) => SecureStorage.instance,
);

final kidsModeProvider =
    StateNotifierProvider<KidsModeController, KidsModeState>((ref) {
      return KidsModeController(
        SecureKidsModeStorage(ref.watch(secureStorageProvider)),
      );
    });

final kidsContentPolicyProvider = Provider<KidsContentPolicy>(
  (_) => const KidsContentPolicy(),
);

final excludedLiveCategoriesPolicyProvider =
    Provider<ExcludedLiveCategoriesPolicy>(
  (_) => const ExcludedLiveCategoriesPolicy(),
);

final databaseProvider = Provider<AppDatabase>(
  (ref) => ref.watch(appDatabaseProvider),
);
