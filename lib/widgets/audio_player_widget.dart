import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../theme.dart';

class AudioPlayerWidget extends StatefulWidget {
  final int lyricId;
  const AudioPlayerWidget({super.key, required this.lyricId});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _player = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _playing = false;
  bool _loading = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _player.durationStream.listen((d) {
      if (mounted) setState(() => _duration = d ?? Duration.zero);
    });
    _player.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _playing = state.playing;
          _loading = state.processingState == ProcessingState.loading ||
              state.processingState == ProcessingState.buffering;
        });
        if (state.processingState == ProcessingState.completed) {
          _player.seek(Duration.zero);
          _player.pause();
        }
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_error) return;
    if (_player.processingState == ProcessingState.idle) {
      try {
        setState(() => _loading = true);
        // Audio files at audio/{id}.mp3 on your server
        await _player.setUrl('audio/${widget.lyricId}.mp3');
        await _player.play();
      } catch (_) {
        if (mounted) setState(() { _error = true; _loading = false; });
      }
    } else if (_playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final pct = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.greenPale,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.green.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎙 Audio Recitation',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.green,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onTap: _error ? null : _toggle,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _error ? AppTheme.textTertiary : AppTheme.green,
                    shape: BoxShape.circle,
                  ),
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          _error
                              ? Icons.error_outline
                              : _playing
                                  ? Icons.pause
                                  : Icons.play_arrow,
                          color: Colors.white,
                          size: 22,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        activeTrackColor: AppTheme.green,
                        inactiveTrackColor: AppTheme.green.withValues(alpha: 0.2),
                        thumbColor: AppTheme.green,
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                      ),
                      child: Slider(
                        value: pct.clamp(0.0, 1.0),
                        onChanged: _duration.inMilliseconds > 0
                            ? (v) {
                                _player.seek(Duration(
                                  milliseconds:
                                      (v * _duration.inMilliseconds).round(),
                                ));
                              }
                            : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _fmt(_position),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            _duration > Duration.zero
                                ? _fmt(_duration)
                                : '--:--',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_error)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Audio not available',
                style: TextStyle(fontSize: 12, color: AppTheme.errorRed),
              ),
            ),
        ],
      ),
    );
  }
}
