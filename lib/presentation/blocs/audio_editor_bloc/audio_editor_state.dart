part of 'audio_editor_bloc.dart';

abstract class AudioEditorState extends Equatable {
  const AudioEditorState();

  @override
  List<Object> get props => [];
}

class AudioEditorInitial extends AudioEditorState {}

class AudioEditorLoading extends AudioEditorState {
  final String operation;

  const AudioEditorLoading({this.operation = 'processing'});

  @override
  List<Object> get props => [operation];
}

class EffectApplied extends AudioEditorState {
  final List<AudioEffect> effects;
  final String effectName;

  const EffectApplied({required this.effects, required this.effectName});

  @override
  List<Object> get props => [effects, effectName];
}

class AudioPreviewReady extends AudioEditorState {
  final String previewPath;
  final List<AudioEffect> effects;

  const AudioPreviewReady({required this.previewPath, required this.effects});

  @override
  List<Object> get props => [previewPath, effects];
}

class AudioSaved extends AudioEditorState {
  final String savedPath;
  final List<AudioEffect> effects;

  const AudioSaved({required this.savedPath, required this.effects});

  @override
  List<Object> get props => [savedPath, effects];
}

class AudioEditorError extends AudioEditorState {
  final String message;

  const AudioEditorError({required this.message});

  @override
  List<Object> get props => [message];
}

class AudioAnalyzed extends AudioEditorState {
  final AudioProperties audioProperties;
  final List<AudioEffect> effects;

  const AudioAnalyzed({required this.audioProperties, required this.effects});

  @override
  List<Object> get props => [audioProperties, effects];
}

class AudioProperties {
  final double currentGain;
  final double currentPitch;
  final double noiseLevel;
  final double silenceThreshold;
  final double echoDelay;
  final double echoDecay;

  const AudioProperties({
    required this.currentGain,
    required this.currentPitch,
    required this.noiseLevel,
    required this.silenceThreshold,
    required this.echoDelay,
    required this.echoDecay,
  });
} 