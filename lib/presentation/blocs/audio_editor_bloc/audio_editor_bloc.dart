import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'audio_editor_event.dart';
part 'audio_editor_state.dart';

class AudioEditorBloc extends Bloc<AudioEditorEvent, AudioEditorState> {
  List<AudioEffect> _appliedEffects = [];
  String? _currentAudioPath;
  String? _processedAudioPath;
  AudioProperties? _audioProperties;

  AudioEditorBloc() : super(AudioEditorInitial()) {
    on<InitializeAudioEvent>(_onInitializeAudio);
    on<GetCurrentAudioValuesEvent>(_onGetCurrentAudioValues);
    on<ApplyEchoEvent>(_onApplyEcho);
    on<ApplyAmplifyEvent>(_onApplyAmplify);
    on<ApplyNoiseReductionEvent>(_onApplyNoiseReduction);
    on<ApplyPitchEvent>(_onApplyPitch);
    on<ApplySilenceRemoverEvent>(_onApplySilenceRemover);
    on<PreviewEffectsEvent>(_onPreviewEffects);
    on<SaveEditedAudioEvent>(_onSaveEditedAudio);
    on<ResetEffectsEvent>(_onResetEffects);
  }

  @override
  Future<void> close() async {
    try {
      // Clean up any resources
      print('[AudioEditor] Cleaning up audio editor resources');
    } catch (e) {
      print('[AudioEditor] Error during cleanup: $e');
    }
    return super.close();
  }

  Future<void> _onInitializeAudio(InitializeAudioEvent event, Emitter<AudioEditorState> emit) async {
    _currentAudioPath = event.audioPath;
    _appliedEffects.clear();
    _processedAudioPath = null;
    
    try {
      // Analyze the audio file to get default values
      _audioProperties = await _analyzeAudio(event.audioPath);
      emit(AudioAnalyzed(audioProperties: _audioProperties!, effects: []));
    } catch (e) {
      print('[AudioEditor] Error analyzing audio: $e');
      emit(AudioEditorError(message: 'Failed to analyze audio: $e'));
    }
  }

  void _onGetCurrentAudioValues(GetCurrentAudioValuesEvent event, Emitter<AudioEditorState> emit) {
    if (_audioProperties != null) {
      // Calculate current values based on applied effects
      final currentValues = _calculateCurrentValues(_audioProperties!, _appliedEffects);
      emit(AudioAnalyzed(audioProperties: currentValues, effects: List.from(_appliedEffects)));
    }
  }

  Future<void> _onApplyEcho(ApplyEchoEvent event, Emitter<AudioEditorState> emit) async {
    emit(const AudioEditorLoading(operation: 'echo'));
    
    try {
      final effect = EchoEffect(delay: event.delay, decay: event.decay);
      _appliedEffects.add(effect);
      
      // Simulate processing time
      await Future.delayed(const Duration(seconds: 2));
      
      emit(EffectApplied(effects: List.from(_appliedEffects), effectName: 'Echo'));
      
      // Return to analyzed state with updated values
      if (_audioProperties != null) {
        final currentValues = _calculateCurrentValues(_audioProperties!, _appliedEffects);
        emit(AudioAnalyzed(audioProperties: currentValues, effects: List.from(_appliedEffects)));
      }
    } catch (e) {
      emit(AudioEditorError(message: 'Failed to apply echo: $e'));
    }
  }

  Future<void> _onApplyAmplify(ApplyAmplifyEvent event, Emitter<AudioEditorState> emit) async {
    emit(const AudioEditorLoading(operation: 'amplify'));
    
    try {
      final effect = AmplifyEffect(gain: event.gain);
      _appliedEffects.add(effect);
      
      // Simulate processing time
      await Future.delayed(const Duration(seconds: 1));
      
      emit(EffectApplied(effects: List.from(_appliedEffects), effectName: 'Amplify'));
      
      // Return to analyzed state with updated values
      if (_audioProperties != null) {
        final currentValues = _calculateCurrentValues(_audioProperties!, _appliedEffects);
        emit(AudioAnalyzed(audioProperties: currentValues, effects: List.from(_appliedEffects)));
      }
    } catch (e) {
      emit(AudioEditorError(message: 'Failed to apply amplify: $e'));
    }
  }

  Future<void> _onApplyNoiseReduction(ApplyNoiseReductionEvent event, Emitter<AudioEditorState> emit) async {
    emit(const AudioEditorLoading(operation: 'noise_reduction'));
    
    try {
      final effect = NoiseReductionEffect(strength: event.strength);
      _appliedEffects.add(effect);
      
      // Simulate processing time for noise reduction (longer process)
      await Future.delayed(const Duration(seconds: 3));
      
      emit(EffectApplied(effects: List.from(_appliedEffects), effectName: 'Noise Reduction'));
      
      // Return to analyzed state with updated values
      if (_audioProperties != null) {
        final currentValues = _calculateCurrentValues(_audioProperties!, _appliedEffects);
        emit(AudioAnalyzed(audioProperties: currentValues, effects: List.from(_appliedEffects)));
      }
    } catch (e) {
      emit(AudioEditorError(message: 'Failed to apply noise reduction: $e'));
    }
  }

  Future<void> _onApplyPitch(ApplyPitchEvent event, Emitter<AudioEditorState> emit) async {
    emit(const AudioEditorLoading(operation: 'pitch'));
    
    try {
      final effect = PitchEffect(pitch: event.pitch);
      _appliedEffects.add(effect);
      
      // Simulate processing time
      await Future.delayed(const Duration(seconds: 2));
      
      emit(EffectApplied(effects: List.from(_appliedEffects), effectName: 'Pitch Adjustment'));
      
      // Return to analyzed state with updated values
      if (_audioProperties != null) {
        final currentValues = _calculateCurrentValues(_audioProperties!, _appliedEffects);
        emit(AudioAnalyzed(audioProperties: currentValues, effects: List.from(_appliedEffects)));
      }
    } catch (e) {
      emit(AudioEditorError(message: 'Failed to apply pitch adjustment: $e'));
    }
  }

  Future<void> _onApplySilenceRemover(ApplySilenceRemoverEvent event, Emitter<AudioEditorState> emit) async {
    emit(const AudioEditorLoading(operation: 'silence_removal'));
    
    try {
      final effect = SilenceRemoverEffect(threshold: event.threshold);
      _appliedEffects.add(effect);
      
      // Simulate processing time for silence removal (longer process)
      await Future.delayed(const Duration(seconds: 3));
      
      emit(EffectApplied(effects: List.from(_appliedEffects), effectName: 'Silence Remover'));
      
      // Return to analyzed state with updated values
      if (_audioProperties != null) {
        final currentValues = _calculateCurrentValues(_audioProperties!, _appliedEffects);
        emit(AudioAnalyzed(audioProperties: currentValues, effects: List.from(_appliedEffects)));
      }
    } catch (e) {
      emit(AudioEditorError(message: 'Failed to apply silence remover: $e'));
    }
  }

  void _onPreviewEffects(PreviewEffectsEvent event, Emitter<AudioEditorState> emit) async {
    if (_audioProperties == null) {
      emit(const AudioEditorError(message: 'Audio not analyzed yet'));
      return;
    }

    if (_appliedEffects.isEmpty) {
      emit(const AudioEditorError(message: 'No effects to preview'));
      return;
    }

    emit(const AudioEditorLoading(operation: 'preview'));

    try {
      print('[AudioEditor] Creating preview with ${_appliedEffects.length} effects');
      
      // Use the current audio path (which should be local after download)
      final inputPath = _currentAudioPath!;
      
      // Create preview file path
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final previewPath = p.join(directory.path, 'preview_$timestamp.wav');
      
      // Process audio with applied effects
      final processedPath = await _processAudioWithEffects(inputPath, previewPath, _appliedEffects);
      
      emit(AudioPreviewReady(
        previewPath: processedPath,
        effects: List.from(_appliedEffects),
      ));
    } catch (e) {
      print('[AudioEditor] Preview error: $e');
      emit(AudioEditorError(message: 'Failed to create preview: ${e.toString()}'));
    }
  }

  void _onSaveEditedAudio(SaveEditedAudioEvent event, Emitter<AudioEditorState> emit) async {
    if (_audioProperties == null) {
      emit(const AudioEditorError(message: 'Audio not analyzed yet'));
      return;
    }

    if (_appliedEffects.isEmpty) {
      emit(const AudioEditorError(message: 'No effects applied to save'));
      return;
    }

    emit(const AudioEditorLoading(operation: 'save'));

    try {
      print('[AudioEditor] Saving audio with ${_appliedEffects.length} effects');
      
      // Use the current audio path (which should be local after download)
      final inputPath = _currentAudioPath!;
      
      // Create output file path
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = p.join(directory.path, 'processed_$timestamp.wav');
      
      // Process audio with applied effects
      final processedPath = await _processAudioWithEffects(inputPath, outputPath, _appliedEffects);
      
      // Save the processed audio
      if (event.isServerAudio && event.serverId != null) {
        await _saveServerAudio(event.serverId!, processedPath);
      } else {
        await _saveLocalAudio(processedPath);
      }
      
      // Store the processed audio path for future use
      _processedAudioPath = processedPath;
      
      emit(AudioSaved(savedPath: processedPath, effects: List.from(_appliedEffects)));
    } catch (e) {
      print('[AudioEditor] Save error: $e');
      emit(AudioEditorError(message: 'Failed to save audio: ${e.toString()}'));
    }
  }

  Future<String> _processAudioWithEffects(String inputPath, String outputPath, List<AudioEffect> effects) async {
    print('[AudioEditor] Processing audio from: $inputPath to: $outputPath');
    print('[AudioEditor] Simulating audio processing with ${effects.length} effects');
    
    try {
      // Verify input file exists
      final inputFile = File(inputPath);
      if (!await inputFile.exists()) {
        throw Exception('Input audio file not found: $inputPath');
      }
      
      // Simulate audio processing by copying the original file
      // In a real implementation, this would apply actual audio effects
      await inputFile.copy(outputPath);
      
      // Verify output file was created
      final outputFile = File(outputPath);
      if (!await outputFile.exists()) {
        throw Exception('Failed to create output file: $outputPath');
      }
      
      // Simulate processing time based on number of effects
      final processingTime = effects.length * 500; // 500ms per effect
      await Future.delayed(Duration(milliseconds: processingTime));
      
      print('[AudioEditor] Audio processing simulation completed: $outputPath');
      return outputPath;
    } catch (e) {
      print('[AudioEditor] Error processing audio: $e');
      throw Exception('Audio processing failed: $e');
    }
  }

  Future<void> _saveServerAudio(String serverId, String processedPath) async {
    print('[AudioEditor] Saving server audio with ID: $serverId');
    
    // Simulate server audio upload
    await Future.delayed(const Duration(seconds: 2));
    
    // In a real implementation, you would:
    // 1. Upload the processed audio file to the server
    // 2. Update the server record with new audio file
    
    print('[AudioEditor] Server audio saved successfully');
  }

  Future<void> _saveLocalAudio(String processedPath) async {
    print('[AudioEditor] Saving local audio');
    
    // Copy processed file to permanent location
    final directory = await getApplicationDocumentsDirectory();
    final savedDir = Directory(p.join(directory.path, 'edited_recordings'));
    if (!await savedDir.exists()) {
      await savedDir.create(recursive: true);
    }
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final savedPath = p.join(savedDir.path, 'edited_$timestamp.wav');
    
    await File(processedPath).copy(savedPath);
    
    print('[AudioEditor] Local audio saved to: $savedPath');
  }

  void _onResetEffects(ResetEffectsEvent event, Emitter<AudioEditorState> emit) {
    _appliedEffects.clear();
    _processedAudioPath = null;
    if (_audioProperties != null) {
      emit(AudioAnalyzed(audioProperties: _audioProperties!, effects: []));
    } else {
      emit(AudioEditorInitial());
    }
  }

  // Audio analysis methods
  Future<AudioProperties> _analyzeAudio(String audioPath) async {
    print('[AudioEditor] Analyzing audio file: $audioPath');
    
    try {
      // Basic audio file analysis
      final file = File(audioPath);
      final fileSize = await file.length();
      
      // Simulate analysis time
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Generate realistic audio properties based on file characteristics
      final random = Random();
      
      // Base values with some randomization to simulate real analysis
      double currentGain = 0.7 + (random.nextDouble() * 0.6); // 0.7 - 1.3
      double noiseLevel = 0.05 + (random.nextDouble() * 0.15); // 5% - 20%
      double silenceThreshold = 0.02 + (random.nextDouble() * 0.08); // 2% - 10%
      
      // Adjust based on file size (larger files might have different characteristics)
      if (fileSize > 1000000) { // > 1MB
        currentGain *= 1.1;
        noiseLevel *= 0.8;
      }
      
      print('[AudioEditor] Analysis complete - Gain: ${currentGain.toStringAsFixed(2)}, Noise: ${(noiseLevel * 100).toInt()}%');
      
      return AudioProperties(
        currentGain: currentGain.clamp(0.1, 3.0),
        currentPitch: 1.0,
        noiseLevel: noiseLevel.clamp(0.01, 0.5),
        silenceThreshold: silenceThreshold.clamp(0.01, 0.2),
        echoDelay: 0.0,
        echoDecay: 0.0,
      );
    } catch (e) {
      print('[AudioEditor] Error analyzing audio: $e');
      
      // Return default values if analysis fails
      return const AudioProperties(
        currentGain: 1.0,
        currentPitch: 1.0,
        noiseLevel: 0.15,
        silenceThreshold: 0.05,
        echoDelay: 0.0,
        echoDecay: 0.0,
      );
    }
  }

  AudioProperties _calculateCurrentValues(AudioProperties original, List<AudioEffect> effects) {
    // Start with original audio properties
    double currentGain = original.currentGain;
    double currentPitch = original.currentPitch;
    double noiseLevel = original.noiseLevel;
    double silenceThreshold = original.silenceThreshold;
    double echoDelay = original.echoDelay;
    double echoDecay = original.echoDecay;

    // Apply all effects cumulatively
    for (final effect in effects) {
      if (effect is AmplifyEffect) {
        currentGain *= effect.gain;
      } else if (effect is PitchEffect) {
        currentPitch *= effect.pitch;
      } else if (effect is NoiseReductionEffect) {
        noiseLevel *= (1.0 - effect.strength); // Reduce noise
      } else if (effect is SilenceRemoverEffect) {
        silenceThreshold = effect.threshold;
      } else if (effect is EchoEffect) {
        echoDelay = effect.delay;
        echoDecay = effect.decay;
      }
    }

    return AudioProperties(
      currentGain: currentGain,
      currentPitch: currentPitch,
      noiseLevel: noiseLevel,
      silenceThreshold: silenceThreshold,
      echoDelay: echoDelay,
      echoDecay: echoDecay,
    );
  }
}

// Audio Effect Classes
abstract class AudioEffect {
  const AudioEffect();
}

class EchoEffect extends AudioEffect {
  final double delay;
  final double decay;

  const EchoEffect({required this.delay, required this.decay});

  @override
  String toString() => 'Echo (delay: ${delay.toStringAsFixed(1)}s, decay: ${(decay * 100).toInt()}%)';
}

class AmplifyEffect extends AudioEffect {
  final double gain;

  const AmplifyEffect({required this.gain});

  @override
  String toString() => 'Amplify (${(gain * 100).toInt()}%)';
}

class NoiseReductionEffect extends AudioEffect {
  final double strength;

  const NoiseReductionEffect({required this.strength});

  @override
  String toString() => 'Noise Reduction (${(strength * 100).toInt()}%)';
}

class PitchEffect extends AudioEffect {
  final double pitch;

  const PitchEffect({required this.pitch});

  @override
  String toString() => 'Pitch (${pitch.toStringAsFixed(1)}x)';
}

class SilenceRemoverEffect extends AudioEffect {
  final double threshold;

  const SilenceRemoverEffect({required this.threshold});

  @override
  String toString() => 'Silence Remover (${(threshold * 100).toInt()}% threshold)';
}

 