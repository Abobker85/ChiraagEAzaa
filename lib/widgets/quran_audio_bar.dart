import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/quran_models.dart';
import '../services/quran_audio_service.dart';
import '../services/quran_service.dart';
import '../theme.dart';

/// Bottom audio recitation & on-device voice recording bar for QuranReaderScreen.
class QuranAudioBar extends StatefulWidget {
  final QuranSurah surah;

  const QuranAudioBar({super.key, required this.surah});

  @override
  State<QuranAudioBar> createState() => _QuranAudioBarState();
}

class _QuranAudioBarState extends State<QuranAudioBar> {
  final _audio = QuranAudioService.instance;
  List<QuranRecording> _recordings = const [];

  @override
  void initState() {
    super.initState();
    _refreshRecordings();
  }

  @override
  void didUpdateWidget(covariant QuranAudioBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surah.number != widget.surah.number) {
      _refreshRecordings();
    }
  }

  Future<void> _refreshRecordings() async {
    final list = await _audio.listRecordings(widget.surah.number);
    if (mounted) setState(() => _recordings = list);
  }

  Future<void> _toggleRecord() async {
    HapticFeedback.mediumImpact();
    if (_audio.isRecording) {
      final saved = await _audio.stopRecording();
      await _refreshRecordings();
      if (saved != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recitation recording saved locally on device'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      final started = await _audio.startRecording(widget.surah.number);
      if (!started && _audio.lastError != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_audio.lastError!)),
        );
      }
    }
  }

  void _showRecordingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return AnimatedBuilder(
          animation: _audio,
          builder: (context, _) {
            final colors = AppColors.of(context);
            return Container(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: colors.separator)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.separator,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'My Recordings · ${widget.surah.englishName}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stored privately on this device only',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    if (_recordings.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'No recordings for this Surah yet.\nTap the Mic button to record your recitation.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: colors.textSecondary),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 260),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _recordings.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: colors.separator),
                          itemBuilder: (_, i) {
                            final rec = _recordings[i];
                            final isThisPlaying =
                                _audio.playingLocalPath == rec.path && _audio.isPlaying;
                            final ts =
                                '${rec.createdAt.year}-${rec.createdAt.month.toString().padLeft(2, '0')}-${rec.createdAt.day.toString().padLeft(2, '0')} '
                                '${rec.createdAt.hour.toString().padLeft(2, '0')}:${rec.createdAt.minute.toString().padLeft(2, '0')}';
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: IconButton(
                                icon: Icon(
                                  isThisPlaying
                                      ? Icons.pause_circle_filled_rounded
                                      : Icons.play_circle_filled_rounded,
                                  color: colors.accent,
                                  size: 32,
                                ),
                                onPressed: () => _audio.playLocalRecording(rec.path),
                              ),
                              title: Text(
                                'Recording ${_recordings.length - i}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                ts,
                                style: TextStyle(fontSize: 12, color: colors.textSecondary),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppTheme.errorRed,
                                ),
                                onPressed: () async {
                                  await _audio.deleteRecording(rec.path);
                                  await _refreshRecordings();
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReciterPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colors = AppColors.of(ctx);
        final current = QuranService.instance.selectedReciter.id;
        return Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Qari Reciter',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                ...QuranService.reciters.map((r) {
                  final selected = r.id == current;
                  return ListTile(
                    leading: Icon(
                      selected ? Icons.check_circle_rounded : Icons.record_voice_over_rounded,
                      color: selected ? colors.accent : colors.textSecondary,
                    ),
                    title: Text(
                      r.name,
                      style: TextStyle(
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                    subtitle: Text(r.style, style: TextStyle(color: colors.textSecondary)),
                    onTap: () async {
                      await QuranService.instance.setReciter(r.id);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatSeconds(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([_audio, QuranService.instance]),
      builder: (context, _) {
        final isPlayingThisSurah =
            _audio.isPlaying && _audio.playingSurahNumber == widget.surah.number && _audio.playingLocalPath == null;
        final isRec = _audio.isRecording;

        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            decoration: BoxDecoration(
              color: colors.card,
              border: Border(top: BorderSide(color: colors.separator)),
            ),
            child: Row(
              children: [
                // Play/Pause Surah Qari Recitation
                Material(
                  color: colors.accent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _audio.playSurah(widget.surah.number),
                    child: SizedBox(
                      width: 42,
                      height: 42,
                      child: _audio.isLoadingAudio
                          ? const Padding(
                              padding: EdgeInsets.all(11),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              isPlayingThisSurah
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _showReciterPicker,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isRec
                                ? 'Recording · ${_formatSeconds(_audio.recordingSeconds)}'
                                : QuranService.instance.selectedReciter.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isRec ? AppTheme.errorRed : colors.textPrimary,
                            ),
                          ),
                          Text(
                            isRec
                                ? 'Tap Stop to save on device'
                                : 'Tap to change Qari',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Saved Recordings list button
                IconButton(
                  tooltip: 'My Recordings',
                  onPressed: _showRecordingsSheet,
                  icon: Badge(
                    isLabelVisible: _recordings.isNotEmpty,
                    label: Text('${_recordings.length}'),
                    child: Icon(
                      Icons.library_music_rounded,
                      color: colors.accent,
                      size: 22,
                    ),
                  ),
                ),
                // Record / Stop Mic button
                Material(
                  color: isRec ? AppTheme.errorRed : colors.accentSoft,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    key: const Key('quran_record_button'),
                    borderRadius: BorderRadius.circular(20),
                    onTap: _toggleRecord,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isRec ? Icons.stop_rounded : Icons.mic_rounded,
                            size: 18,
                            color: isRec ? Colors.white : colors.accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isRec ? 'Stop' : 'Rec',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isRec ? Colors.white : colors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
