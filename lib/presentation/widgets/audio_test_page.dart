import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sdcp_rebuild/presentation/widgets/audio_player_service.dart';
import 'package:sdcp_rebuild/presentation/widgets/direct_audio_player.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioTestPage extends StatefulWidget {
  const AudioTestPage({super.key});

  @override
  State<AudioTestPage> createState() => _AudioTestPageState();
}

class _AudioTestPageState extends State<AudioTestPage> {
  String _statusMessage = 'Audio Test Page';
  String? _testAudioPath;
  String? _downloadedAudioPath;
  final String _testUrl = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3";
  FlutterSoundPlayer? _player;
  bool _isPlaying = false;
  
  @override
  void initState() {
    super.initState();
    _initTestAudio();
  }
  
  @override
  void dispose() {
    _player?.closePlayer();
    super.dispose();
  }
  
  Future<void> _initTestAudio() async {
    setState(() {
      _statusMessage = 'Initializing...';
    });
    
    try {
      // Create a test audio path
      final tempDir = await getTemporaryDirectory();
      _testAudioPath = '${tempDir.path}/test_audio.mp3';
      
      setState(() {
        _statusMessage = 'Test paths created';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error initializing: $e';
      });
    }
  }
  
  Future<void> _downloadTestAudio() async {
    setState(() {
      _statusMessage = 'Downloading test audio...';
    });
    
    try {
      _downloadedAudioPath = await AudioPlayerService.downloadAndCacheAudio(_testUrl);
      
      if (_downloadedAudioPath != null) {
        final file = File(_downloadedAudioPath!);
        if (await file.exists()) {
          final size = await file.length();
          setState(() {
            _statusMessage = 'Downloaded to: $_downloadedAudioPath\nSize: $size bytes';
          });
        } else {
          setState(() {
            _statusMessage = 'Download reported success but file not found!';
          });
        }
      } else {
        setState(() {
          _statusMessage = 'Download failed!';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Download error: $e';
      });
    }
  }
  
  Future<void> _playWithService() async {
    if (_downloadedAudioPath == null) {
      setState(() {
        _statusMessage = 'No audio file downloaded yet!';
      });
      return;
    }
    
    setState(() {
      _statusMessage = 'Attempting to play with AudioPlayerService...';
    });
    
    try {
      final success = await AudioPlayerService.playAudio(_downloadedAudioPath!, onComplete: () {
        setState(() {
          _statusMessage = 'Playback completed!';
        });
      });
      
      if (success) {
        setState(() {
          _statusMessage = 'Playback started successfully!';
        });
      } else {
        setState(() {
          _statusMessage = 'Failed to start playback!';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Playback error: $e';
      });
    }
  }
  
  Future<void> _playWithDirectPlayer() async {
    if (_downloadedAudioPath == null) {
      setState(() {
        _statusMessage = 'No audio file downloaded yet!';
      });
      return;
    }
    
    setState(() {
      _statusMessage = 'Attempting to play with direct FlutterSoundPlayer...';
    });
    
    try {
      // Check permissions first
      if (Platform.isAndroid) {
        final status = await Permission.storage.status;
        if (status.isDenied) {
          final result = await Permission.storage.request();
          if (!result.isGranted) {
            setState(() {
              _statusMessage = 'Storage permission denied!';
            });
            return;
          }
        }
      }
      
      // Initialize player if needed
      if (_player == null) {
        _player = FlutterSoundPlayer();
        await _player!.openPlayer();
      }
      
      if (_isPlaying) {
        await _player!.stopPlayer();
        setState(() {
          _isPlaying = false;
          _statusMessage = 'Playback stopped';
        });
        return;
      }
      
      // Play the file
      await _player!.startPlayer(
        fromURI: _downloadedAudioPath,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
            _statusMessage = 'Direct playback completed!';
          });
        }
      );
      
      setState(() {
        _isPlaying = true;
        _statusMessage = 'Direct playback started!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Direct playback error: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Test Page'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_statusMessage),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _downloadTestAudio,
              child: const Text('Download Test Audio'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _playWithService,
              child: const Text('Play with AudioPlayerService'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _playWithDirectPlayer,
              child: const Text('Play with DirectPlayer'),
            ),
            const SizedBox(height: 24),
            if (_downloadedAudioPath != null) ...[
              const Text('DirectAudioPlayer Widget Test:'),
              const SizedBox(height: 8),
              Center(
                child: DirectAudioPlayer(
                  contentId: 'test',
                  audioPath: _downloadedAudioPath,
                  size: 64,
                  backgroundColor: Colors.blue,
                  iconColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 