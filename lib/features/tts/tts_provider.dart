import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

final ttsProvider = StateNotifierProvider<TtsNotifier, TtsState>((ref) => TtsNotifier());

class TtsNotifier extends StateNotifier<TtsState> {
  final FlutterTts _tts = FlutterTts();

  TtsNotifier() : super(const TtsState()) {
    _init();
  }

  Future<void> _init() async {
    await _tts.setLanguage('zh-CN');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    _tts.setStartHandler(() {
      state = state.copyWith(isSpeaking: true);
    });
    _tts.setCompletionHandler(() {
      state = state.copyWith(isSpeaking: false);
    });
    _tts.setPauseHandler(() {
      state = state.copyWith(isSpeaking: false);
    });
    _tts.setContinueHandler(() {
      state = state.copyWith(isSpeaking: true);
    });
    _tts.setProgressHandler((text, startOffset, endOffset, word) {
      state = state.copyWith(currentOffset: startOffset);
    });
  }

  Future<void> speak(String text) async {
    await _tts.awaitSpeakCompletion(true);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    state = state.copyWith(isSpeaking: false);
  }

  Future<void> pause() async {
    await _tts.pause();
  }

  Future<void> resume() async {
    await _tts.speak('');
    // FlutterTts workaround for resume
  }

  Future<void> setRate(double rate) async {
    await _tts.setSpeechRate(rate);
    state = state.copyWith(speechRate: rate);
  }

  Future<void> setPitch(double pitch) async {
    await _tts.setPitch(pitch);
    state = state.copyWith(pitch: pitch);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}

class TtsState {
  final bool isSpeaking;
  final double speechRate;
  final double pitch;
  final int currentOffset;

  const TtsState({
    this.isSpeaking = false,
    this.speechRate = 0.5,
    this.pitch = 1.0,
    this.currentOffset = 0,
  });

  TtsState copyWith({
    bool? isSpeaking,
    double? speechRate,
    double? pitch,
    int? currentOffset,
  }) {
    return TtsState(
      isSpeaking: isSpeaking ?? this.isSpeaking,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      currentOffset: currentOffset ?? this.currentOffset,
    );
  }
}
