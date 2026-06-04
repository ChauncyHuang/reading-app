import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/search_result.dart';
import 'search_provider.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _search() {
    ref.read(searchQueryProvider.notifier).state = _controller.text.trim();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final hotKeywords = ref.watch(hotKeywordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: '搜索书名或作者',
            border: InputBorder.none,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                  )
                : null,
          ),
          onSubmitted: (_) => _search(),
          textInputAction: TextInputAction.search,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _search),
        ],
      ),
      body: query.isEmpty
          ? _buildHotSearch(hotKeywords)
          : resultsAsync.when(
              data: (results) => results.isEmpty
                  ? const Center(child: Text('没有找到结果'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: results.length,
                      itemBuilder: (context, index) => _SearchResultItem(result: results[index]),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('搜索出错: $e')),
            ),
    );
  }

  Widget _buildHotSearch(AsyncValue<List<String>> hotKeywords) {
    return hotKeywords.when(
      data: (keywords) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('热门搜索', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: keywords.map((kw) => ActionChip(
              label: Text(kw),
              onPressed: () {
                _controller.text = kw;
                _search();
              },
            )).toList(),
          ),
        ],
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SearchResultItem extends StatelessWidget {
  final SearchResult result;
  const _SearchResultItem({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: result.coverUrl != null
              ? CachedNetworkImage(imageUrl: result.coverUrl!, width: 48, height: 64, fit: BoxFit.cover)
              : Container(
                  width: 48,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.book, color: Theme.of(context).colorScheme.primary),
                ),
        ),
        title: Text(result.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${result.author}  ${result.sourceName}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to book detail with search result info
          context.push('/book-detail?bookId=new&name=${Uri.encodeComponent(result.name)}&author=${Uri.encodeComponent(result.author)}&source=${Uri.encodeComponent(result.sourceName)}&detailUrl=${Uri.encodeComponent(result.detailUrl ?? '')}&coverUrl=${Uri.encodeComponent(result.coverUrl ?? '')}');
        },
      ),
    );
  }
}
