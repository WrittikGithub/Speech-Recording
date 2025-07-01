part of 'audio_editor_bloc.dart';

abstract class AudioEditorEvent extends Equatable {
  const AudioEditorEvent();

  @override
  List<Object> get props => [];
}

class ApplyEchoEvent extends AudioEditorEvent {
  final double delay;
  final double decay;

  const ApplyEchoEvent({required this.delay, required this.decay});

  @override
  List<Object> get props => [delay, decay];
}

class ApplyAmplifyEvent extends AudioEditorEvent {
  final double gain;

  const ApplyAmplifyEvent({required this.gain});

  @override
  List<Object> get props => [gain];
}

class ApplyNoiseReductionEvent extends AudioEditorEvent {
  final double strength;

  const ApplyNoiseReductionEvent({required this.strength});

  @override
  List<Object> get props => [strength];
}

class ApplyPitchEvent extends AudioEditorEvent {
  final double pitch;

  const ApplyPitchEvent({required this.pitch});

  @override
  List<Object> get props => [pitch];
}

class ApplySilenceRemoverEvent extends AudioEditorEvent {
  final double threshold;

  const ApplySilenceRemoverEvent({required this.threshold});

  @override
  List<Object> get props => [threshold];
}

class PreviewEffectsEvent extends AudioEditorEvent {
  const PreviewEffectsEvent();
}

class SaveEditedAudioEvent extends AudioEditorEvent {
  final bool isServerAudio;
  final String? serverId;

  const SaveEditedAudioEvent({this.isServerAudio = false, this.serverId});

  @override
  List<Object> get props => [isServerAudio, serverId ?? ''];
}

class ResetEffectsEvent extends AudioEditorEvent {
  const ResetEffectsEvent();
}

class InitializeAudioEvent extends AudioEditorEvent {
  final String audioPath;

  const InitializeAudioEvent({required this.audioPath});

  @override
  List<Object> get props => [audioPath];
}

class GetCurrentAudioValuesEvent extends AudioEditorEvent {
  const GetCurrentAudioValuesEvent();
} 