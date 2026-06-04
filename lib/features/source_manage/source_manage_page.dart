import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/book_source.dart';
import '../bookshelf/bookshelf_provider.dart';

class SourceManagePage extends ConsumerWidget {
  const SourceManagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourcesAsync = ref.watch(sourceManageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('书源管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(context, ref),
          ),
        ],
      ),
      body: sourcesAsync.when(
        data: (sources) {
          if (sources.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.source_outlined, size: 64,
                      color: Theme.of(context).colorScheme.primary.withAlpha(100)),
                  const SizedBox(height: 12),
                  const Text('还没有书源'),
                  const SizedBox(height: 4),
                  const Text('点击右上角 + 导入书源'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showAddDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('导入书源'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sources.length,
            itemBuilder: (context, index) {
              final source = sources[index];
              return SwitchListTile(
                title: Text(source.bookSourceName),
                subtitle: Text(source.bookSourceUrl),
                value: source.enabled,
                onChanged: (v) {
                  ref.read(sourceManageProvider.notifier).toggle(
                    source.bookSourceName,
                    source.bookSourceUrl,
                    v,
                  );
                },
                secondary: Icon(
                  source.bookSourceType == 1 ? Icons.headphones : Icons.book,
                  color: source.enabled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withAlpha(80),
                ),
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(source.bookSourceName),
                      content: Text('URL: ${source.bookSourceUrl}\n类型: ${source.bookSourceType == 0 ? '文本' : '音频'}'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            ref.read(sourceManageProvider.notifier).remove(
                              source.bookSourceName,
                              source.bookSourceUrl,
                            );
                          },
                          child: const Text('删除', style: TextStyle(color: Colors.red)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('取消'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final urlController = TextEditingController();
    final jsonController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('导入书源', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'url', label: Text('从URL')),
                ButtonSegment(value: 'json', label: Text('粘贴JSON')),
                ButtonSegment(value: 'clipboard', label: Text('剪贴板')),
              ],
              selected: {'url'},
              onSelectionChanged: (_) {},
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: '书源URL',
                hintText: 'https://example.com/source.json',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final url = urlController.text.trim();
                if (url.isNotEmpty) {
                  // Fetch and import from URL
                  Navigator.pop(ctx);
                }
              },
              child: const Text('导入'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class SourceImportPage extends ConsumerStatefulWidget {
  const SourceImportPage({super.key});

  @override
  ConsumerState<SourceImportPage> createState() => _SourceImportPageState();
}

class _SourceImportPageState extends ConsumerState<SourceImportPage> {
  final _controller = TextEditingController();
  String _status = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('导入书源')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: '粘贴书源JSON',
                hintText: '支持单个书源或书源数组...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final text = _controller.text.trim();
                if (text.isEmpty) return;
                try {
                  final parsed = jsonDecode(text);
                  if (parsed is List) {
                    ref.read(sourceManageProvider.notifier).importList(text);
                    setState(() => _status = '成功导入 ${parsed.length} 个书源');
                  } else {
                    ref.read(sourceManageProvider.notifier).importFromJson(text);
                    setState(() => _status = '成功导入 1 个书源');
                  }
                } catch (e) {
                  setState(() => _status = 'JSON解析失败: $e');
                }
              },
              child: const Text('解析并导入'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                _controller.clear();
                setState(() => _status = '');
              },
              child: const Text('清空'),
            ),
            if (_status.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_status),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
