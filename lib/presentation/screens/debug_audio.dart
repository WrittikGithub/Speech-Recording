// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:sdcp_rebuild/presentation/blocs/audio_record_bloc/audio_record_bloc.dart';
// import 'package:path_provider/path_provider.dart';

// class DebugAudioPage extends StatefulWidget {
//   const DebugAudioPage({Key? key}) : super(key: key);

//   @override
//   _DebugAudioPageState createState() => _DebugAudioPageState();
// }

// class _DebugAudioPageState extends State<DebugAudioPage> {
//   String _status = "Idle";
//   String? _localFilePath;
//   String _remoteUrl = ""; // Replace with a valid remote audio URL
//   final _audioBloc = AudioRecordBloc();
  
//   @override
//   void initState() {
//     super.initState();
//     _checkFiles();
//   }
  
//   Future<void> _checkFiles() async {
//     final directory = await getApplicationDocumentsDirectory();
//     final recordingsDir = Directory('${directory.path}');
    
//     setState(() {
//       _status = "Checking files...";
//     });
    
//     if (await recordingsDir.exists()) {
//       final files = await recordingsDir.list().toList();
//       final audioFiles = files.where((file) => 
//         file.path.endsWith('.aac') || 
//         file.path.endsWith('.wav') || 
//         file.path.endsWith('.mp3')).toList();
      
//       if (audioFiles.isNotEmpty) {
//         setState(() {
//           _localFilePath = audioFiles.first.path;
//           _status = "Found audio file: ${audioFiles.first.path}";
//         });
//       } else {
//         setState(() {
//           _status = "No audio files found";
//         });
//       }
//     } else {
//       setState(() {
//         _status = "Recordings directory not found";
//       });
//     }
//   }
  
//   void _startRecording() {
//     _audioBloc.add(StartRecording());
//     setState(() {
//       _status = "Recording...";
//     });
//   }
  
//   void _stopRecording() {
//     _audioBloc.add(StopRecording());
//     setState(() {
//       _status = "Recording stopped";
//     });
    
//     // Refresh file list
//     Future.delayed(Duration(seconds: 1), () {
//       _checkFiles();
//     });
//   }
  
//   void _playLocalFile() {
//     if (_localFilePath != null) {
//       setState(() {
//         _status = "Attempting to play local file";
//       });
//       _audioBloc.add(PlayLocalFile(_localFilePath!));
//     } else {
//       setState(() {
//         _status = "No local file available";
//       });
//     }
//   }
  
//   void _playRemoteFile() {
//     if (_remoteUrl.isNotEmpty) {
//       setState(() {
//         _status = "Attempting to play remote URL";
//       });
//       _audioBloc.add(PlayRemoteAudio(_remoteUrl));
//     } else {
//       setState(() {
//         _status = "Remote URL not set";
//       });
//     }
//   }
  
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Audio Debug"),
//       ),
//       body: BlocProvider.value(
//         value: _audioBloc,
//         child: BlocListener<AudioRecordBloc, AudioRecordState>(
//           listener: (context, state) {
//             if (state is AudioRecording) {
//               setState(() {
//                 _status = "Recording in progress";
//               });
//             } else if (state is AudioRecordingStopped) {
//               setState(() {
//                 _status = "Recording stopped: ${state.path}";
//                 _localFilePath = state.path;
//               });
//             } else if (state is AudioPlaying) {
//               setState(() {
//                 _status = "Playing: ${state.path}";
//               });
//             } else if (state is AudioPlayingPaused) {
//               setState(() {
//                 _status = "Playback paused";
//               });
//             } else if (state is AudioRecordInitial) {
//               setState(() {
//                 _status = "Idle";
//               });
//             }
//           },
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 Text(
//                   "Status: $_status",
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(height: 20),
                
//                 // Local file info
//                 Text("Local File:", style: TextStyle(fontWeight: FontWeight.bold)),
//                 Text(_localFilePath ?? "No file selected"),
//                 SizedBox(height: 10),
                
//                 // Remote URL info
//                 Text("Remote URL:", style: TextStyle(fontWeight: FontWeight.bold)),
//                 TextFormField(
//                   initialValue: _remoteUrl,
//                   decoration: InputDecoration(
//                     hintText: "Enter a remote audio URL",
//                   ),
//                   onChanged: (value) => _remoteUrl = value,
//                 ),
//                 SizedBox(height: 20),
                
//                 // Recording controls
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     ElevatedButton.icon(
//                       icon: Icon(Icons.mic),
//                       label: Text("Start Recording"),
//                       onPressed: _startRecording,
//                     ),
//                     ElevatedButton.icon(
//                       icon: Icon(Icons.stop),
//                       label: Text("Stop Recording"),
//                       onPressed: _stopRecording,
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 20),
                
//                 // Playback controls
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     ElevatedButton.icon(
//                       icon: Icon(Icons.play_arrow),
//                       label: Text("Play Local"),
//                       onPressed: _localFilePath != null ? _playLocalFile : null,
//                     ),
//                     ElevatedButton.icon(
//                       icon: Icon(Icons.play_circle),
//                       label: Text("Play Remote"),
//                       onPressed: _remoteUrl.isNotEmpty ? _playRemoteFile : null,
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 20),
                
//                 // List available files
//                 ElevatedButton(
//                   child: Text("List Audio Files"),
//                   onPressed: _checkFiles,
//                 ),
                
//                 // Refresh screen
//                 SizedBox(height: 10),
//                 BlocBuilder<AudioRecordBloc, AudioRecordState>(
//                   builder: (context, state) {
//                     return Text(
//                       "Current State: ${state.runtimeType}",
//                       style: TextStyle(fontStyle: FontStyle.italic),
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
  
//   @override
//   void dispose() {
//     _audioBloc.close();
//     super.dispose();
//   }
// } 