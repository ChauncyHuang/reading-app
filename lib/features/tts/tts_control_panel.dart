import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tts_provider.dart';

class TtsControlPanel extends ConsumerWidget {
  final String text;
  const TtsControlPanel({super.key, required this.text});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ttsState = ref.watch(ttsProvider);
    final ttsNotifier = ref.read(ttsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('朗读'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Book/chapter name
            Text('当前章节', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('正在朗读中...', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            )),

            const SizedBox(height: 48),

            // Playback controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  iconSize: 48,
                  icon: const Icon(Icons.skip_previous),
                  onPressed: () {},
                ),
                const SizedBox(width: 16),
                IconButton.filled(
                  iconSize: 64,
                  icon: Icon(ttsState.isSpeaking ? Icons.pause : Icons.play_arrow),
                  onPressed: () async {
                    if (ttsState.isSpeaking) {
                      await ttsNotifier.pause();
                    } else {
                      await ttsNotifier.speak(text);
                    }
                  },
                ),
                const SizedBox(width: 16),
                IconButton.filled(
                  iconSize: 48,
                  icon: const Icon(Icons.skip_next),
                  onPressed: () {},
                ),
              ],
            ),

            const SizedBox(height: 48),

            // Speed control
            Row(
              children: [
                const Icon(Icons.speed),
                Expanded(
                  child: Slider(
                    value: ttsState.speechRate,
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    label: '${ttsState.speechRate.toStringAsFixed(1)}x',
                    onChanged: (v) => ttsNotifier.setRate(v),
                  ),
                ),
                Text('${ttsState.speechRate.toStringAsFixed(1)}x'),
              ],
            ),

            // Pitch control
            Row(
              children: [
                const Icon(Icons.tune),
                Expanded(
                  child: Slider(
                    value: ttsState.pitch,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    label: '${ttsState.pitch.toStringAsFixed(1)}',
                    onChanged: (v) => ttsNotifier.setPitch(v),
                  ),
                ),
                Text('${ttsState.pitch.toStringAsFixed(1)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
