import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/search_result.dart';
import 'discovery_provider.dart';

class DiscoveryPage extends ConsumerWidget {
  const DiscoveryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(exploreSectionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('发现'),
      ),
      body: sectionsAsync.when(
        data: (sections) => sections.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.explore_off, size: 64,
                        color: Theme.of(context).colorScheme.primary.withAlpha(100)),
                    const SizedBox(height: 12),
                    Text('还没有书源', style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 4),
                    Text('导入书源后即可浏览发现内容', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
                    )),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => context.push('/source-manage'),
                      icon: const Icon(Icons.add),
                      label: const Text('导入书源'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: sections.length,
                itemBuilder: (context, index) {
                  final section = sections[index];
                  return _DiscoverSection(section: section);
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }
}

class _DiscoverSection extends ConsumerWidget {
  final ExploreSection section;
  const _DiscoverSection({required this.section});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(discoveryProvider(section.sourceIndex));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(section.title, style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton(onPressed: () {}, child: const Text('更多')),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: resultsAsync.when(
            data: (results) => results.isEmpty
                ? Center(child: Text('暂无内容', style: Theme.of(context).textTheme.bodySmall))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: results.length,
                    itemBuilder: (context, index) => _DiscoveryBookCard(result: results[index]),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('加载失败')),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _DiscoveryBookCard extends StatelessWidget {
  final SearchResult result;
  const _DiscoveryBookCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/book-detail?bookId=new&name=${Uri.encodeComponent(result.name)}&author=${Uri.encodeComponent(result.author)}&source=${Uri.encodeComponent(result.sourceName)}&detailUrl=${Uri.encodeComponent(result.detailUrl ?? '')}&coverUrl=${Uri.encodeComponent(result.coverUrl ?? '')}');
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: result.coverUrl != null
                  ? CachedNetworkImage(imageUrl: result.coverUrl!, width: 100, height: 140, fit: BoxFit.cover)
                  : Container(
                      width: 100, height: 140,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.book, color: Theme.of(context).colorScheme.primary, size: 32),
                    ),
            ),
            const SizedBox(height: 4),
            Text(result.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall),
            Text(result.author, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                )),
          ],
        ),
      ),
    );
  }
}
