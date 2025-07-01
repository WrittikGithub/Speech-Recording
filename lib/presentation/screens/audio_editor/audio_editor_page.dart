import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/presentation/blocs/audio_dashboard_bloc/audio_dashboard_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/audio_editor_bloc/audio_editor_bloc.dart';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AudioEditorPage extends StatefulWidget {
  final Recording recording;

  const AudioEditorPage({
    Key? key,
    required this.recording,
  }) : super(key: key);

  @override
  State<AudioEditorPage> createState() => _AudioEditorPageState();
}

class _AudioEditorPageState extends State<AudioEditorPage> {
  FlutterSoundPlayer? _player;
  bool _isPlaying = false;
  bool _isDownloading = false;
  bool _isDownloadComplete = false;
  String? _localAudioPath;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _downloadError;
  StreamSubscription? _progressSubscription;
  AudioEditorBloc? _audioEditorBloc;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _prepareAudio();
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _player?.closePlayer();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      _player = FlutterSoundPlayer();
      await _player!.openPlayer();
      await _player!.setSubscriptionDuration(const Duration(milliseconds: 100));
      print('[AudioEditor] Player initialized successfully with subscription duration');
    } catch (e) {
      print('[AudioEditor] Error initializing player: $e');
    }
  }

  Future<void> _prepareAudio() async {
    final audioPath = widget.recording.path;
    
    if (audioPath.startsWith('server://')) {
      await _downloadServerRecording(audioPath);
    } else {
      // Local file - just verify it exists
      final file = File(audioPath);
      if (await file.exists()) {
        setState(() {
          _localAudioPath = audioPath;
          _isDownloadComplete = true;
        });
        print('[AudioEditor] Local file ready: $audioPath');
      } else {
        setState(() {
          _downloadError = 'Local audio file not found';
        });
        print('[AudioEditor] Local file not found: $audioPath');
      }
    }
  }

  Future<void> _downloadServerRecording(String serverPath) async {
    if (!mounted) return;
    
    setState(() {
      _isDownloading = true;
      _downloadError = null;
    });

    try {
      print('[AudioEditor] Starting download for: $serverPath');
      final serverUrl = serverPath.replaceFirst('server://', 'https://');
      
      final response = await http.get(Uri.parse(serverUrl));
      
      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final fileName = p.basename(serverUrl);
        final localPath = p.join(directory.path, 'audio_editor_$fileName');
        
        final file = File(localPath);
        await file.writeAsBytes(response.bodyBytes, flush: true);
        
        final fileSize = await file.length();
        print('[AudioEditor] Downloaded file size: $fileSize bytes to: $localPath');
        
        if (fileSize == 0) {
          throw Exception('Downloaded file is empty');
        }
        
        if (mounted) {
          setState(() {
            _localAudioPath = localPath;
            _isDownloading = false;
            _isDownloadComplete = true;
          });
        }
        
        print('[AudioEditor] Download complete: $localPath');
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      print('[AudioEditor] Download error: $e');
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadError = 'Failed to download audio: ${e.toString()}';
        });
      }
    }
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor ?? Colors.blue,
        ),
      );
    }
  }

  Codec _getCodecFromExtension(String extension) {
    switch (extension) {
      case '.wav':
        return Codec.pcm16WAV;
      case '.mp3':
        return Codec.mp3;
      case '.aac':
        return Codec.aacADTS;
      case '.m4a':
        return Codec.aacMP4;
      default:
        return Codec.pcm16WAV; // Default to WAV
    }
  }

  Future<void> _playPause() async {
    if (_player == null || !_isDownloadComplete || _localAudioPath == null) {
      print('[AudioEditor] Cannot play: player not ready or audio not downloaded');
      return;
    }

    try {
      if (_isPlaying) {
        await _player!.pausePlayer();
        print('[AudioEditor] Audio paused');
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      } else {
        print('[AudioEditor] Playing audio: $_localAudioPath');
        
        // Determine codec based on file extension
        final extension = p.extension(_localAudioPath!).toLowerCase();
        final codec = _getCodecFromExtension(extension);
        
        // Cancel any existing subscription before starting
        _progressSubscription?.cancel();
        
        final duration = await _player!.startPlayer(
          fromURI: _localAudioPath!,
          codec: codec,
          whenFinished: () {
            print('[AudioEditor] Audio finished playing');
            if (mounted) {
              setState(() {
                _isPlaying = false;
                _position = Duration.zero;
              });
              _progressSubscription?.cancel();
            }
          },
        );
        
        // Set duration if we got it from startPlayer
        if (duration != null && mounted) {
          setState(() {
            _duration = duration;
          });
        }
        
        // Set up progress tracking with better error handling
        print('[AudioEditor] Setting up progress stream...');
        _progressSubscription = _player!.onProgress!.listen(
          (event) {
            print('[AudioEditor] Raw progress event: ${event.position.inSeconds}s / ${event.duration.inSeconds}s');
            if (mounted) {
              setState(() {
                _position = event.position;
                if (event.duration > Duration.zero) {
                  _duration = event.duration;
                }
              });
              print('[AudioEditor] UI updated - Position: ${_position.inSeconds}s, Duration: ${_duration.inSeconds}s');
            }
          },
          onError: (error) {
            print('[AudioEditor] Progress stream error: $error');
          },
          onDone: () {
            print('[AudioEditor] Progress stream completed');
          },
        );
        print('[AudioEditor] Progress stream subscription created');
        
        if (mounted) {
          setState(() {
            _isPlaying = true;
          });
        }
        
        print('[AudioEditor] Playback started successfully');
      }
    } catch (e) {
      print('[AudioEditor] Error in playPause: $e');
      _showSnackBar('Error playing audio: $e', backgroundColor: Colors.red);
    }
  }

  void _playPreviewAudio(BuildContext context, AudioPreviewReady state) async {
    if (_player == null || !mounted) return;
    
    try {
      // Stop current playback if any
      if (_isPlaying) {
        await _player!.stopPlayer();
      }
      
      // Play the preview file
      await _player!.startPlayer(
        fromURI: state.previewPath,
        codec: Codec.pcm16WAV,
        whenFinished: () {
          if (mounted) {
            setState(() {
              _isPlaying = false;
            });
          }
        },
      );
      
      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      print('[AudioEditor] Error playing preview: $e');
      _showSnackBar('Error playing preview: $e', backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Appcolors.kprimaryColor,
        title: const Text(
          'Audio Editor',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: BlocProvider(
        create: (context) {
          _audioEditorBloc = AudioEditorBloc();
          // Initialize with local audio path once it's ready
          if (_isDownloadComplete && _localAudioPath != null) {
            _audioEditorBloc!.add(InitializeAudioEvent(audioPath: _localAudioPath!));
          }
          return _audioEditorBloc!;
        },
        child: BlocConsumer<AudioEditorBloc, AudioEditorState>(
          listener: (context, state) {
            if (!mounted) return;
            
            if (state is EffectApplied) {
              _showSnackBar('${state.effectName} effect applied!', backgroundColor: Colors.green);
            } else if (state is AudioEditorError) {
              _showSnackBar(state.message, backgroundColor: Colors.red);
            } else if (state is AudioSaved) {
              _showSnackBar('Audio saved successfully!', backgroundColor: Colors.green);
            } else if (state is AudioPreviewReady) {
              _showSnackBar('Preview ready! Playing audio with ${state.effects.length} effects applied.', backgroundColor: Colors.blue);
              // Automatically start playing the preview
              _playPreviewAudio(context, state);
            }
          },
          builder: (context, state) {
            // Initialize audio analysis once download is complete
            if (_isDownloadComplete && _localAudioPath != null && state is AudioEditorInitial) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _audioEditorBloc != null) {
                  _audioEditorBloc!.add(InitializeAudioEvent(audioPath: _localAudioPath!));
                }
              });
            }
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Audio Info Card
                  _buildAudioInfoCard(),
                  const SizedBox(height: 20),
                  
                  // Audio Player Controls
                  _buildPlayerControls(),
                  
                  // Download status message
                  if (_isDownloading || _downloadError != null)
                    _buildDownloadStatus(),
                  
                  const SizedBox(height: 20),
                  
                  // Applied Effects Display
                  if (state is EffectApplied) 
                    _buildAppliedEffects(state.effects)
                  else if (state is AudioAnalyzed && state.effects.isNotEmpty)
                    _buildAppliedEffects(state.effects)
                  else if (state is AudioPreviewReady)
                    _buildAppliedEffects(state.effects),
                  
                  const SizedBox(height: 30),
                  
                  // Audio Effects Section
                  if (_isDownloadComplete && _localAudioPath != null)
                    _buildEffectsSection(context),
                  const SizedBox(height: 30),
                  
                  // Action Buttons
                  if (_isDownloadComplete && _localAudioPath != null)
                    _buildActionButtons(context, state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppliedEffects(List<AudioEffect> effects) {
    if (effects.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Applied Effects',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...effects.map((effect) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• ${effect.toString()}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green[700],
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildAudioInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Appcolors.kprimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.audiotrack,
              color: Appcolors.kprimaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.recording.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDuration(Duration(seconds: widget.recording.duration))} • ${widget.recording.date.toString().split(' ')[0]}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Progress Bar
          Row(
            children: [
              Text(_formatDuration(_position)),
              Expanded(
                child: Slider(
                  value: _duration.inMilliseconds > 0
                      ? _position.inMilliseconds / _duration.inMilliseconds
                      : 0.0,
                  onChanged: (value) {
                    if (_duration.inMilliseconds > 0) {
                      final newPosition = Duration(
                        milliseconds: (value * _duration.inMilliseconds).round(),
                      );
                      _player?.seekToPlayer(newPosition);
                      // Don't manually update _position here - let the stream handle it
                      print('[AudioEditor] Slider seek to: ${newPosition.inSeconds}s');
                    }
                  },
                  activeColor: Appcolors.kprimaryColor,
                ),
              ),
              Text(_formatDuration(_duration)),
            ],
          ),
          const SizedBox(height: 20),
          
          // Play/Pause Button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _isDownloadComplete ? () async {
                  if (_player != null && (_player!.isPlaying || _player!.isPaused)) {
                    final newPosition = _position - const Duration(seconds: 10);
                    final seekPosition = newPosition < Duration.zero ? Duration.zero : newPosition;
                    
                    try {
                      await _player!.seekToPlayer(seekPosition);
                      print('[AudioEditor] Seeked backward to: ${seekPosition.inSeconds}s');
                      // Small delay to allow stream to update
                      await Future.delayed(const Duration(milliseconds: 100));
                    } catch (e) {
                      print('[AudioEditor] Error seeking backward: $e');
                    }
                  }
                } : null,
                icon: const Icon(Icons.replay_10),
                iconSize: 32,
                color: _isDownloadComplete ? null : Colors.grey,
              ),
              const SizedBox(width: 20),
              Container(
                decoration: BoxDecoration(
                  color: _isDownloading || _downloadError != null 
                      ? Colors.grey 
                      : Appcolors.kprimaryColor,
                  shape: BoxShape.circle,
                ),
                child: _isDownloading
                    ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : _downloadError != null
                        ? IconButton(
                            onPressed: () => _prepareAudio(),
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                            ),
                            iconSize: 32,
                          )
                        : IconButton(
                            onPressed: _isDownloadComplete ? _playPause : null,
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            iconSize: 32,
                          ),
              ),
              const SizedBox(width: 20),
              IconButton(
                onPressed: _isDownloadComplete ? () async {
                  if (_player != null && (_player!.isPlaying || _player!.isPaused)) {
                    final newPosition = _position + const Duration(seconds: 10);
                    final seekPosition = newPosition > _duration ? _duration : newPosition;
                    
                    try {
                      await _player!.seekToPlayer(seekPosition);
                      print('[AudioEditor] Seeked forward to: ${seekPosition.inSeconds}s');
                      // Small delay to allow stream to update
                      await Future.delayed(const Duration(milliseconds: 100));
                    } catch (e) {
                      print('[AudioEditor] Error seeking forward: $e');
                    }
                  }
                } : null,
                icon: const Icon(Icons.forward_10),
                iconSize: 32,
                color: _isDownloadComplete ? null : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadStatus() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _downloadError != null ? Colors.red[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _downloadError != null ? Colors.red[200]! : Colors.blue[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _downloadError != null ? Icons.error_outline : Icons.download,
            color: _downloadError != null ? Colors.red[600] : Colors.blue[600],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _downloadError ?? 'Downloading audio file...',
              style: TextStyle(
                color: _downloadError != null ? Colors.red[700] : Colors.blue[700],
                fontSize: 14,
              ),
            ),
          ),
          if (_downloadError != null)
            TextButton(
              onPressed: () => _prepareAudio(),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  Widget _buildEffectsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Audio Effects',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Echo Effect
        _buildEffectTile(
          context: context,
          icon: Icons.graphic_eq,
          title: 'Echo',
          subtitle: 'Add echo effect to your audio',
          onTap: () => _showEchoDialog(context),
        ),
        
        // Amplify Effect
        _buildEffectTile(
          context: context,
          icon: Icons.volume_up,
          title: 'Amplify',
          subtitle: 'Increase or decrease volume',
          onTap: () => _showAmplifyDialog(context),
        ),
        
        // Noise Reduction
        _buildEffectTile(
          context: context,
          icon: Icons.noise_control_off,
          title: 'Noise Reduction',
          subtitle: 'Remove background noise',
          onTap: () => _showNoiseReductionDialog(context),
        ),
        
        // Pitch Adjustment
        _buildEffectTile(
          context: context,
          icon: Icons.tune,
          title: 'Pitch Adjustment',
          subtitle: 'Change audio pitch',
          onTap: () => _showPitchDialog(context),
        ),
        
        // Silence Remover
        _buildEffectTile(
          context: context,
          icon: Icons.content_cut,
          title: 'Silence Remover',
          subtitle: 'Remove silent parts',
          onTap: () => _showSilenceRemoverDialog(context),
        ),
      ],
    );
  }

  Widget _buildEffectTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Appcolors.kprimaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Appcolors.kprimaryColor,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        tileColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AudioEditorState state) {
    final isLoading = state is AudioEditorLoading;
    
    // Check for effects in multiple states
    final hasEffects = (state is EffectApplied && state.effects.isNotEmpty) ||
                      (state is AudioPreviewReady && state.effects.isNotEmpty) ||
                      (state is AudioAnalyzed && state.effects.isNotEmpty);
    
    final hasPreview = state is AudioPreviewReady;
    final isPreviewLoading = state is AudioEditorLoading && state.operation == 'preview';
    final isSaveLoading = state is AudioEditorLoading && state.operation == 'save';
    
    return Column(
      children: [
        // Horizontal row for Preview and Save buttons
        Row(
          children: [
            // Preview Button
            Expanded(
              child: OutlinedButton(
                onPressed: hasEffects && !isLoading ? () => _previewEffects(context) : null,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: hasEffects ? Appcolors.kprimaryColor : Colors.grey),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isPreviewLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        hasEffects ? 'Preview Effects' : 'Apply Effects First',
                        style: TextStyle(
                          color: hasEffects ? Appcolors.kprimaryColor : Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Save Button - Only enabled when user has applied effects and wants to save
            Expanded(
              child: ElevatedButton(
                onPressed: hasEffects && !isLoading ? () => _saveEffects(context) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasEffects ? Appcolors.kprimaryColor : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isSaveLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        hasEffects ? 'Save Effects' : 'No Effects to Save',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
        
        // Show preview status
        if (hasPreview)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.preview, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Preview is playing with modified audio (effects simulated)',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showEchoDialog(BuildContext context) {
    // Get current state to determine default values
    final bloc = context.read<AudioEditorBloc>();
    final currentState = bloc.state;
    
    double delay = 0.5;
    double decay = 0.5;
    
    if (currentState is AudioAnalyzed) {
      delay = currentState.audioProperties.echoDelay > 0 ? currentState.audioProperties.echoDelay : 0.5;
      decay = currentState.audioProperties.echoDecay > 0 ? currentState.audioProperties.echoDecay : 0.5;
    }
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setDialogState) => AlertDialog(
          title: const Text('Echo Effect'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Echo Delay: ${delay.toStringAsFixed(1)}s'),
              Slider(
                value: delay,
                min: 0.1,
                max: 2.0,
                divisions: 19,
                onChanged: (value) => setDialogState(() => delay = value),
                activeColor: Appcolors.kprimaryColor,
              ),
              const SizedBox(height: 16),
              Text('Current Echo Decay: ${(decay * 100).toInt()}%'),
              Slider(
                value: decay,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                onChanged: (value) => setDialogState(() => decay = value),
                activeColor: Appcolors.kprimaryColor,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<AudioEditorBloc>().add(
                  ApplyEchoEvent(delay: delay, decay: decay),
                );
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Appcolors.kprimaryColor,
              ),
              child: const Text('Apply', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAmplifyDialog(BuildContext context) {
    // Get current state to determine default values
    final bloc = context.read<AudioEditorBloc>();
    final currentState = bloc.state;
    
    double gain = 1.0;
    
    if (currentState is AudioAnalyzed) {
      gain = currentState.audioProperties.currentGain;
    }
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setDialogState) => AlertDialog(
          title: const Text('Amplify'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Gain: ${(gain * 100).toInt()}%'),
              Slider(
                value: gain,
                min: 0.1,
                max: 3.0,
                divisions: 29,
                onChanged: (value) => setDialogState(() => gain = value),
                activeColor: Appcolors.kprimaryColor,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<AudioEditorBloc>().add(
                  ApplyAmplifyEvent(gain: gain),
                );
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Appcolors.kprimaryColor,
              ),
              child: const Text('Apply', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoiseReductionDialog(BuildContext context) {
    // Get current state to determine default values
    final bloc = context.read<AudioEditorBloc>();
    final currentState = bloc.state;
    
    double strength = 0.5;
    
    if (currentState is AudioAnalyzed) {
      // Calculate current noise reduction strength based on noise level
      strength = (1.0 - currentState.audioProperties.noiseLevel).clamp(0.1, 1.0);
    }
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setDialogState) => AlertDialog(
          title: const Text('Noise Reduction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (currentState is AudioAnalyzed)
                Text('Current Noise Level: ${(currentState.audioProperties.noiseLevel * 100).toInt()}%'),
              const SizedBox(height: 8),
              Text('Reduction Strength: ${(strength * 100).toInt()}%'),
              Slider(
                value: strength,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                onChanged: (value) => setDialogState(() => strength = value),
                activeColor: Appcolors.kprimaryColor,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<AudioEditorBloc>().add(
                  ApplyNoiseReductionEvent(strength: strength),
                );
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Appcolors.kprimaryColor,
              ),
              child: const Text('Apply', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showPitchDialog(BuildContext context) {
    // Get current state to determine default values
    final bloc = context.read<AudioEditorBloc>();
    final currentState = bloc.state;
    
    double pitch = 1.0;
    
    if (currentState is AudioAnalyzed) {
      pitch = currentState.audioProperties.currentPitch;
    }
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setDialogState) => AlertDialog(
          title: const Text('Pitch Adjustment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Pitch: ${pitch.toStringAsFixed(1)}x'),
              Slider(
                value: pitch,
                min: 0.5,
                max: 2.0,
                divisions: 15,
                onChanged: (value) => setDialogState(() => pitch = value),
                activeColor: Appcolors.kprimaryColor,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<AudioEditorBloc>().add(
                  ApplyPitchEvent(pitch: pitch),
                );
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Appcolors.kprimaryColor,
              ),
              child: const Text('Apply', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSilenceRemoverDialog(BuildContext context) {
    // Get current state to determine default values
    final bloc = context.read<AudioEditorBloc>();
    final currentState = bloc.state;
    
    double threshold = 0.1;
    
    if (currentState is AudioAnalyzed) {
      threshold = currentState.audioProperties.silenceThreshold;
    }
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setDialogState) => AlertDialog(
          title: const Text('Silence Remover'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (currentState is AudioAnalyzed)
                Text('Current Silence Threshold: ${(currentState.audioProperties.silenceThreshold * 100).toInt()}%'),
              const SizedBox(height: 8),
              Text('New Threshold: ${(threshold * 100).toInt()}%'),
              Slider(
                value: threshold,
                min: 0.01,
                max: 0.5,
                divisions: 49,
                onChanged: (value) => setDialogState(() => threshold = value),
                activeColor: Appcolors.kprimaryColor,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<AudioEditorBloc>().add(
                  ApplySilenceRemoverEvent(threshold: threshold),
                );
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Appcolors.kprimaryColor,
              ),
              child: const Text('Apply', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _previewEffects(BuildContext context) {
    context.read<AudioEditorBloc>().add(PreviewEffectsEvent());
  }

  void _saveEffects(BuildContext context) {
    // Determine if this is a server audio by checking the recording path
    final isServerAudio = widget.recording.serverSaved;
    final serverId = widget.recording.serverId?.toString();
    
    context.read<AudioEditorBloc>().add(
      SaveEditedAudioEvent(
        isServerAudio: isServerAudio,
        serverId: serverId,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : ''}$twoDigitMinutes:$twoDigitSeconds';
  }
} 