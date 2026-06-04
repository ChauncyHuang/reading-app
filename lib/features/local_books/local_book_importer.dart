import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'local_books_provider.dart';

class LocalBookImporter extends ConsumerWidget {
  const LocalBookImporter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('导入本地书籍')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.upload_file, size: 80,
                color: Theme.of(context).colorScheme.primary.withAlpha(100)),
            const SizedBox(height: 16),
            Text('支持 TXT / EPUB 格式', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text('自动检测编码（UTF-8 / GBK）', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
            )),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _pickFile(context, ref),
              icon: const Icon(Icons.file_open),
              label: const Text('选择文件'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _pickDirectory(context, ref),
              icon: const Icon(Icons.folder_open),
              label: const Text('批量导入文件夹'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'epub'],
      );
      if (result?.files.single.path != null) {
        final path = result!.files.single.path!;
        if (path.endsWith('.txt')) {
          await ref.read(localBooksProvider.notifier).importTxt(path);
        } else if (path.endsWith('.epub')) {
          await ref.read(localBooksProvider.notifier).importEpub(path);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('导入成功！')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  Future<void> _pickDirectory(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        final dir = Directory(result);
        final files = dir.listSync().whereType<File>();
        int count = 0;
        for (final file in files) {
          final ext = file.path.split('.').last.toLowerCase();
          if (ext == 'txt') {
            await ref.read(localBooksProvider.notifier).importTxt(file.path);
            count++;
          } else if (ext == 'epub') {
            await ref.read(localBooksProvider.notifier).importEpub(file.path);
            count++;
          }
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('导入完成，共 $count 本书')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }
}
