import 'package:flutter/material.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/features/catalog/catalog_controller.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/widgets/category_card.dart';
import 'package:iptv/shared/widgets/empty_state.dart';
import 'package:iptv/shared/widgets/error_view.dart';
import 'package:iptv/shared/widgets/skeleton_loaders.dart';

/// Shared categories-hub skeleton: loading → error/empty → "All" + category list.
class CatalogCategoriesHub<TItem, TLeading> extends StatelessWidget {
  const CatalogCategoriesHub({
    super.key,
    required this.state,
    required this.hubKey,
    required this.allTitle,
    required this.itemCountLabel,
    required this.emptyIcon,
    required this.onRetry,
    required this.onSelectAll,
    required this.onSelectCategory,
    this.leadingUrlOf,
  });

  final CatalogState<TItem, TLeading> state;
  final Key hubKey;
  final String allTitle;
  final String itemCountLabel;
  final List<List<dynamic>> emptyIcon;
  final VoidCallback onRetry;
  final VoidCallback onSelectAll;
  final ValueChanged<Category> onSelectCategory;

  /// Optional map from leading value → logo URL (Live uses Channel.streamIcon).
  final String? Function(TLeading leading)? leadingUrlOf;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.categories.isEmpty) {
      return const CategoryListSkeleton();
    }

    final categories = state.categories;

    return KeyedSubtree(
      key: hubKey,
      child: categories.isEmpty
          ? (state.error != null
                ? ErrorView(
                    message: context.l10n.homeCheckConnection,
                    eyebrow: context.l10n.labelNoResults,
                    onRetry: onRetry,
                  )
                : EmptyState(
                    title: context.l10n.labelNoResults,
                    subtitle: context.l10n.homeCheckConnection,
                    icon: emptyIcon,
                  ))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              cacheExtent: 350,
              itemCount: categories.length + 1,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return CategoryCard(
                    title: allTitle,
                    itemCount: state.totalCount,
                    itemCountLabel: itemCountLabel,
                    isAllCard: true,
                    onTap: onSelectAll,
                  );
                }

                final category = categories[index - 1];
                final count = state.categoryCounts[category.id] ?? 0;
                final leading = state.categoryLeading[category.id];
                final logoUrl = leading == null
                    ? null
                    : (leadingUrlOf?.call(leading) ??
                        (leading is String ? leading : null));

                return CategoryCard(
                  title: category.name,
                  itemCount: count,
                  itemCountLabel: itemCountLabel,
                  logoUrl: logoUrl,
                  onTap: () => onSelectCategory(category),
                );
              },
            ),
    );
  }
}
