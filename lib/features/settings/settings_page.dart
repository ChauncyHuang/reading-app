import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/database.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Reading settings
          _SectionHeader(title: '阅读'),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('阅读偏好'),
            subtitle: const Text('字体大小、背景、翻页模式'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.headphones),
            title: const Text('朗读设置'),
            subtitle: const Text('默认语速、音调'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),

          const Divider(),
          _SectionHeader(title: '书源'),
          ListTile(
            leading: const Icon(Icons.source),
            title: const Text('书源管理'),
            subtitle: const Text('导入、启用/禁用书源'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/source-manage'),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('导入书源'),
            subtitle: const Text('从URL或JSON导入'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/source-import'),
          ),

          const Divider(),
          _SectionHeader(title: '本地书籍'),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('导入本地书籍'),
            subtitle: const Text('支持 TXT / EPUB'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/import-books'),
          ),

          const Divider(),
          _SectionHeader(title: '数据'),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('备份数据'),
            subtitle: const Text('导出书架、设置和缓存'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _backup(context),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('恢复数据'),
            subtitle: const Text('从备份文件恢复'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('清除缓存'),
            subtitle: const Text('清理缓存的章节内容'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _clearCache(context),
          ),

          const Divider(),
          _SectionHeader(title: '关于'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于'),
            subtitle: const Text('Reading v1.0.0'),
          ),
        ],
      ),
    );
  }

  Future<void> _backup(BuildContext context) async {
    try {
      final db = AppDatabase.instance;
      final books = await db.getAllBooks();
      final sources = await db.getAllSources();
      final groups = await db.getAllGroups();

      final backupData = {
        'version': '1.0.0',
        'timestamp': DateTime.now().toIso8601String(),
        'books': books.map((b) => {
              'id': b.id,
              'name': b.name,
              'author': b.author,
              'origin': b.origin,
              'readChapterIndex': b.readChapterIndex,
              'readChapterPos': b.readChapterPos,
              'isLocal': b.isLocal,
              'localFilePath': b.localFilePath,
            }).toList(),
        'sources': sources.map((s) => s.toJson()).toList(),
        'groups': groups,
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(backupData);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('备份数据已生成 (${jsonStr.length} 字符)')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('备份失败: $e')),
        );
      }
    }
  }

  Future<void> _clearCache(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除缓存'),
        content: const Text('确定要清除所有已缓存的章节内容吗？这将释放存储空间，但需要重新下载。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final db = AppDatabase.instance;
                final books = await db.getAllBooks();
                for (final book in books) {
                  await db.clearChapterContent(book.id);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('缓存已清除')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('清除失败: $e')),
                  );
                }
              }
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          )),
    );
  }
}
