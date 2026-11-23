import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../models/quran_models.dart';
import 'quran_service.dart';

/// Manages both Qari Quran recitation playback (via `just_audio`) and
/// local on-device personal recitation voice recordings (via `record`).
class QuranAudioService extends ChangeNotifier {
  QuranAudioService._();
  static final QuranAudioService instance = QuranAudioService._();

  AudioPlayer? _player;
  AudioRecorder? _recorder;
  StreamSubscription<PlayerState>? _playerStateSub;
  Timer? _recordTimer;

  bool _isPlaying = false;
  bool _isLoadingAudio = false;
  bool _isRecording = false;
  int _recordingSeconds = 0;
  int? _playingSurahNumber;
  int? _playingAyahGlobal;
  String? _playingLocalPath;
  String? _lastError;

  bool get isPlaying => _isPlaying;
  bool get isLoadingAudio => _isLoadingAudio;
  bool get isRecording => _isRecording;
  int get recordingSeconds => _recordingSeconds;
  int? get playingSurahNumber => _playingSurahNumber;
  int? get playingAyahGlobal => _playingAyahGlobal;
  String? get playingLocalPath => _playingLocalPath;
  String? get lastError => _lastError;

  AudioPlayer _ensurePlayer() {
    if (_player != null) return _player!;
    final player = AudioPlayer();
    _player = player;
    _playerStateSub = player.playerStateStream.listen((state) {
      final playing = state.playing && state.processingState != ProcessingState.completed;
      final loading = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      if (state.processingState == ProcessingState.completed) {
        _playingAyahGlobal = null;
        _playingLocalPath = null;
      }
      _isPlaying = playing;
      _isLoadingAudio = loading;
      notifyListeners();
    });
    return player;
  }

  Future<void> playSurah(int surahNumber) async {
    _lastError = null;
    if (_isRecording) await stopRecording();
    final player = _ensurePlayer();
    final url = QuranService.instance.selectedReciter.surahAudioUrl(surahNumber);

    try {
      if (_playingSurahNumber == surahNumber &&
          _playingAyahGlobal == null &&
          _playingLocalPath == null &&
          _isPlaying) {
        await player.pause();
        return;
      }
      _playingSurahNumber = surahNumber;
      _playingAyahGlobal = null;
      _playingLocalPath = null;
      _isLoadingAudio = true;
      notifyListeners();

      await player.setUrl(url);
      await player.play();
    } catch (e) {
      _isLoadingAudio = false;
      _isPlaying = false;
      _lastError = 'Unable to stream recitation. Check your internet connection.';
      notifyListeners();
    }
  }

  Future<void> playAyah(QuranAyah ayah) async {
    _lastError = null;
    if (_isRecording) await stopRecording();
    final player = _ensurePlayer();
    final url = QuranService.instance.selectedReciter.ayahAudioUrl(ayah.globalNumber);

    try {
      if (_playingAyahGlobal == ayah.globalNumber && _isPlaying) {
        await player.pause();
        return;
      }
      _playingSurahNumber = ayah.surahNumber;
      _playingAyahGlobal = ayah.globalNumber;
      _playingLocalPath = null;
      _isLoadingAudio = true;
      notifyListeners();

      await player.setUrl(url);
      await player.play();
    } catch (e) {
      _isLoadingAudio = false;
      _isPlaying = false;
      _lastError = 'Unable to stream ayah audio. Check your internet connection.';
      notifyListeners();
    }
  }

  Future<void> playLocalRecording(String path) async {
    _lastError = null;
    if (_isRecording) await stopRecording();
    final player = _ensurePlayer();
    try {
      if (_playingLocalPath == path && _isPlaying) {
        await player.pause();
        return;
      }
      _playingLocalPath = path;
      _playingAyahGlobal = null;
      _isLoadingAudio = true;
      notifyListeners();

      await player.setFilePath(path);
      await player.play();
    } catch (e) {
      _isLoadingAudio = false;
      _isPlaying = false;
      _lastError = 'Unable to play recording.';
      notifyListeners();
    }
  }

  Future<void> stopPlayback() async {
    if (_player == null) return;
    try {
      await _player!.stop();
    } catch (_) {}
    _isPlaying = false;
    _isLoadingAudio = false;
    _playingAyahGlobal = null;
    _playingLocalPath = null;
    notifyListeners();
  }

  // ── Personal On-Device Voice Recording ────────────────────────────────────

  Future<Directory> _recordingsDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'quran_recordings'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<List<QuranRecording>> listRecordings(int surahNumber) async {
    if (kIsWeb) return const [];
    try {
      final dir = await _recordingsDir();
      final prefix = 'surah_${surahNumber}_';
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => p.basename(f.path).startsWith(prefix))
          .toList();
      final items = <QuranRecording>[];
      for (final f in files) {
        final stat = f.statSync();
        items.add(QuranRecording(
          path: f.path,
          surahNumber: surahNumber,
          createdAt: stat.modified,
        ));
      }
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (_) {
      return const [];
    }
  }

  Future<bool> startRecording(int surahNumber) async {
    _lastError = null;
    if (kIsWeb) {
      _lastError = 'Voice recording is available on iOS and Android devices.';
      notifyListeners();
      return false;
    }
    await stopPlayback();

    _recorder ??= AudioRecorder();
    try {
      final hasPerm = await _recorder!.hasPermission();
      if (!hasPerm) {
        _lastError = 'Microphone permission is required to record your recitation.';
        notifyListeners();
        return false;
      }
      final dir = await _recordingsDir();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final filePath = p.join(dir.path, 'surah_${surahNumber}_$ts.m4a');

      await _recorder!.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
        path: filePath,
      );
      _isRecording = true;
      _recordingSeconds = 0;
      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _recordingSeconds++;
        notifyListeners();
      });
      notifyListeners();
      return true;
    } catch (e) {
      _isRecording = false;
      _lastError = 'Could not start recording.';
      notifyListeners();
      return false;
    }
  }

  Future<String?> stopRecording() async {
    _recordTimer?.cancel();
    _recordTimer = null;
    if (!_isRecording || _recorder == null) return null;
    try {
      final path = await _recorder!.stop();
      _isRecording = false;
      notifyListeners();
      return path;
    } catch (_) {
      _isRecording = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteRecording(String path) async {
    if (_playingLocalPath == path) {
      await stopPlayback();
    }
    try {
      final f = File(path);
      if (f.existsSync()) await f.delete();
    } catch (_) {}
    notifyListeners();
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _playerStateSub?.cancel();
    _player?.dispose();
    _recorder?.dispose();
    super.dispose();
  }
}
