import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/presentation/screens/login_page/loginpage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sdcp_rebuild/presentation/blocs/bottom_navigation/bottom_navigationbar_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/audio_dashboard_bloc/audio_dashboard_bloc.dart';
import 'package:sdcp_rebuild/presentation/screens/decibel_meter_page.dart';
import 'package:sdcp_rebuild/presentation/screens/profile_page/profilepage.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_snakebar.dart';
import 'dart:io';
import 'package:sdcp_rebuild/presentation/blocs/login_bloc/login_bloc.dart';
import 'package:dio/dio.dart'; 
import 'package:flutter/services.dart'; // Needed for Clipboard
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart'; // Added import for openAppSettings
import 'package:flutter/services.dart'; // Added for SystemNavigator
import 'package:shared_preferences/shared_preferences.dart'; // Added for SharedPreferences
import 'package:sdcp_rebuild/domain/controllers/notification_service.dart';
import 'package:sdcp_rebuild/presentation/screens/audio_editor/audio_editor_page.dart';

/* Commenting out the global dio instance for troubleshooting
// Create a single dio instance
final dio = Dio(BaseOptions(
  baseUrl: 'YOUR_API_BASE_URL', // Replace with your API base URL
  connectTimeout: const Duration(seconds: 5),
  receiveTimeout: const Duration(seconds: 3),
  headers: {
    'Accept': 'application/json',
  },
));
*/

// Define a class property to store the numeric server ID
// Use the existing Recording class from audio_dashboard_state.dart

const String _serverRecordingsKey = 'server_recordings_cache';
const String _localRecordingsKey = 'local_recordings_cache';

class AudioDashboard extends StatefulWidget {
  final VoidCallback? onSwitchToTask;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  const AudioDashboard({super.key, this.onSwitchToTask, required this.scaffoldMessengerKey});

  @override
  State<AudioDashboard> createState() => _AudioDashboardState();
}

class _AudioDashboardState extends State<AudioDashboard> with WidgetsBindingObserver, TickerProviderStateMixin { // Added TickerProviderStateMixin
  String? _signupApp;
  bool _permissionsGranted = false;
  bool _isCheckingPermissions = true; // Start by checking permissions
  // bool _storagePermissionDeniedOnce = false; // Track if storage permission was denied once
  
  // Audio Player related state (for saved recordings list item)
  String? _currentPlayingPath;
  Timer? _playbackTimer;
  // int _playbackDuration = 0; // Now handled by BLoC for active playback
  // double _currentSliderValue = 0.0; // Now handled by BLoC state
  // Duration _currentTotalDuration = Duration.zero; // Now handled by BLoC state
  bool _isSeeking = false;
  late AudioDashboardBloc _audioDashboardBloc; // Added to hold bloc instance

  // Visualizer Animation
  late AnimationController _animationController;
  int _currentRecordingDurationSeconds = 0; // Tracks duration for UI and saving

  // Add missing field declarations
  bool _showRecordingsList = false;
  int _selectedSavedTab = 0;
  List<Recording> _cachedRecordings = [];
  TabController? _savedTabController;
  
  // Playback state
  bool _showPlayerWithoutAudio = false;
  int _currentPlaybackPositionSeconds = 0;
  int _pausedPositionSeconds = 0;
  int _totalDurationSeconds = 0;
  Timer? _playerPositionTimer;

  // Add state variable for playback speed
  double _currentPlaybackSpeed = 1.0;  // Default speed is 1.0x

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _audioDashboardBloc = context.read<AudioDashboardBloc>();
    NotificationService().initialize();
    _loadSignupAppValue();
    _checkAndSetSignupApp(); // Make sure this method is called to load and set the value
    _checkAndRequestPermissions(); // Call the new permission method
    
    // Load recordings on app start
    _audioDashboardBloc.add(LoadRecordingsEvent(forceRemote: false));
    
    // Try to load server recordings on app start (with delay to allow local recordings to load first)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _audioDashboardBloc.add(const LoadServerRecordingsEvent());
      }
    });
    
    // Initialize the TabController for the saved recordings tabs
    _savedTabController = TabController(length: 2, vsync: this);
    
    // Add listener to update _selectedSavedTab when tab changes
    _savedTabController!.addListener(() {
      if (!_savedTabController!.indexIsChanging) {
        setState(() {
          _selectedSavedTab = _savedTabController!.index;
        });
        
        // Load server recordings when switching to server tab
        if (_selectedSavedTab == 1) {
          _audioDashboardBloc.add(const LoadServerRecordingsEvent());
        }
      }
    });
    
    // Listen to BLoC state for recording duration updates
    // This might be redundant if _buildTimer correctly uses BLoC state.
    // However, keeping _currentRecordingDurationSeconds for saving logic.
    _audioDashboardBloc.stream.listen((state) {
      if (!mounted) return; // Prevent calling setState on unmounted widget
      if (state is RecordingInProgress) {
        if (mounted) {
          setState(() {
            _currentRecordingDurationSeconds = state.duration;
          });
        }
      } else if (state is RecordingPaused) {
         if (mounted) {
          setState(() {
            _currentRecordingDurationSeconds = state.duration;
          });
        }
      } else if (state is RecordingStopped) {
        // _currentRecordingDurationSeconds should already be set by the time it stops or pauses.
        // No explicit action here, but good to be aware.
      } else if (state is AudioDashboardInitial || state is RecordingSubmitted) {
        // Reset local duration tracker when recording is fully reset or submitted
        if (mounted) {
          setState(() {
            _currentRecordingDurationSeconds = 0;
          });
        }
      }
      // Handle _currentPlayingPath for saved recordings list
      if (state is PlaybackInProgress) {
        if (mounted) {
          // This _currentPlayingPath is for the list items, not the unsaved recording playback
          // The unsaved recording playback will be identified by _audioDashboardBloc.currentRecordingPath
          // setState(() {
          //  _currentPlayingPath = state.filePath;
          // });
        }
      } else if (state is PlaybackPaused) { // Removed PlaybackEnded check
         if (mounted) {
          // setState(() {
          //   if (_currentPlayingPath == state.filePath) { // Check if it's the same file
          //     // Potentially clear _currentPlayingPath or set a flag
          //   }
          // });
         }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    // Dispose the tab controller to prevent memory leaks
    _savedTabController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _audioDashboardBloc.setBackgroundState(true, context);
        break;
      case AppLifecycleState.resumed:
        _audioDashboardBloc.setBackgroundState(false, context);
        break;
      default:
        break;
    }
  }

  Future<void> _checkAndRequestPermissions() async {
    if (!mounted || _isCheckingPermissions) return;

    debugPrint("[AudioDashboard] Starting permission check...");
    try {
      _isCheckingPermissions = true;

      // Request all necessary permissions at once
      Map<Permission, PermissionStatus> statuses = await [
        Permission.microphone,
        Permission.storage,
        Permission.audio,
        Permission.mediaLibrary,
        Permission.manageExternalStorage,
      ].request();  // This will show the system permission dialog

      bool allGranted = true;
      String deniedPermissions = "";

      // Check each permission
      if (statuses[Permission.microphone] != PermissionStatus.granted) {
        allGranted = false;
        deniedPermissions += "Microphone, ";
      }
      if (statuses[Permission.storage] != PermissionStatus.granted &&
          statuses[Permission.audio] != PermissionStatus.granted &&
          statuses[Permission.mediaLibrary] != PermissionStatus.granted &&
          statuses[Permission.manageExternalStorage] != PermissionStatus.granted) {
        allGranted = false;
        deniedPermissions += "Storage/Audio, ";
      }

      if (!allGranted) {
        debugPrint("[AudioDashboard] Some permissions were denied: $deniedPermissions");
        if (mounted) {
          _showPermissionGuidanceDialog(
            "The following permissions are required: ${deniedPermissions.substring(0, deniedPermissions.length - 2)}. "
            "Please grant them in settings."
          );
        }
      } else {
        debugPrint("[AudioDashboard] All permissions granted successfully");
        if (mounted) {
          setState(() {
            _permissionsGranted = true;
          });
        }
      }
    } catch (e) {
      debugPrint("[AudioDashboard] Error during permission check: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingPermissions = false;
        });
      }
    }
  }

  Future<void> _showPermissionGuidanceDialog(String message) async {
    if (!mounted) return;
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions Required'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
            ),
            TextButton(
              child: const Text('Try Again'),
              onPressed: () {
                Navigator.of(context).pop();
                _checkAndRequestPermissions();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadSignupAppValue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final signupAppValue = prefs.getString('SIGNUP_APP');
      print("Loading SIGNUP_APP value from SharedPreferences: '$signupAppValue'");
      
      if (mounted) {
        setState(() {
          _signupApp = signupAppValue;
          print("Updated _signupApp state value to: '$_signupApp'");
        });
      }
    } catch (e) {
      print("Error loading SIGNUP_APP value: $e");
    }
  }

  // Debug method to check and set the _signupApp value
  Future<void> _checkAndSetSignupApp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentValue = prefs.getString('SIGNUP_APP');
      print("DEBUG: Current SIGNUP_APP value in SharedPreferences: '$currentValue'");
      
      // Ensure a default value is set if null
      if (currentValue == null) {
        // For debugging, you can set a default value
        await prefs.setString('SIGNUP_APP', "0");
        print("DEBUG: Set default SIGNUP_APP value to '0'");
      }
      
      // Update UI with current value
      if (mounted) {
        setState(() {
          _signupApp = currentValue;
          print("DEBUG: _signupApp state updated to: '$_signupApp'");
        });
      }
    } catch (e) {
      print("DEBUG: Error checking/setting SIGNUP_APP value: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug print to check _signupApp value
    print("Current _signupApp value in build method: '$_signupApp'");
    
    return WillPopScope(
      onWillPop: () async {
        // If signup_app is "1", exit the app instead of navigating back
        if (_signupApp == "1") {
          print("Back button pressed with signup_app = 1, exiting app");
          await SystemNavigator.pop();
          return false; // Prevent default back behavior
        }
        // For signup_app = "0" or any other value, allow normal back navigation
        print("Back button pressed with signup_app = $_signupApp, allowing navigation");
        return true; // Allow default back behavior
      },
      child: BlocProvider.value(
        value: _audioDashboardBloc,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: GestureDetector(
            // Add a tap handler to close the player when tapping outside
            onTap: () {
              // If audio is playing, stop it and hide the player UI
              if (_currentPlayingPath != null || _showPlayerWithoutAudio) {
                _stopAndHidePlayerUI();
              }
            },
            // Make the gesture detector transparent so it doesn't affect child widgets
            behavior: HitTestBehavior.translucent,
            child: Column(
              children: [
                // Replace the simple text header with a row containing title and menu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Make a record...',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Appcolors.kprimaryColor,
                      ),
                    ),
                    // Add the 3-dot menu from the shared code
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Appcolors.kprimaryColor),
                      onSelected: (value) async {
                        if (value == 'logout') {
                          // Perform logout operations
                          final preferences = await SharedPreferences.getInstance();
                          await preferences.clear();
                          
                          // Navigate to login page
                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/login',
                              (Route<dynamic> route) => false,
                            );
                          }
                        } else if (value == 'switchToTask') {
                          widget.onSwitchToTask?.call();
                        } else if (value == 'Option 1') {
                          // Handle notification option
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notifications feature coming soon'))
                          );
                        } else if (value == 'Option 2') {
                          // Handle report option
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reports feature coming soon'))
                          );
                        } else if (value == 'Option 3') {
                          // Handle clear local data option
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Clear Local Data'),
                              content: const Text('Are you sure you want to clear all local data?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Local data cleared'))
                                    );
                                  },
                                  child: const Text('Clear'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        List<PopupMenuEntry<String>> items = [];
                        
                        // Print the current _signupApp value when building menu
                        print("Building menu items with _signupApp value: '$_signupApp'");
                        
                        // Check if signup_app value is 0 (regular user)
                        if (_signupApp == "0") {
                          // Add full menu options for regular users
                          items.addAll([
                            const PopupMenuItem<String>(
                              value: 'Option 1',
                              child: Row(
                                children: [
                                  Icon(Icons.notifications, color: Colors.black),
                                  SizedBox(width: 8),
                                  Text('Notification'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'Option 2',
                              child: Row(
                                children: [
                                  Icon(Icons.report, color: Colors.black),
                                  SizedBox(width: 8),
                                  Text('Report'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'Option 3',
                              child: Row(
                                children: [
                                  Icon(Icons.cleaning_services, color: Colors.black),
                                  SizedBox(width: 8),
                                  Text('Clear local data'),
                                ],
                              ),
                            ),
                          ]);
                          
                          // Add Task Dashboard option if onSwitchToTask is available
                          if (widget.onSwitchToTask != null) {
                            items.add(
                              const PopupMenuItem<String>(
                                value: 'switchToTask',
                                child: Row(
                                  children: [
                                    Icon(Icons.dashboard, color: Colors.black),
                                    SizedBox(width: 8),
                                    Text('Task Dashboard'),
                                  ],
                                ),
                              ),
                            );
                          }
                        }
                        
                        // Always add logout option for all users
                        items.add(
                          const PopupMenuItem<String>(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout, color: Colors.black),
                                SizedBox(width: 8),
                                Text('Logout'),
                              ],
                            ),
                          ),
                        );
                        
                        return items;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                BlocBuilder<AudioDashboardBloc, AudioDashboardState>(
                  builder: (context, state) {
                    if (state is! RecordingInProgress && 
                        state is! RecordingPaused && 
                        state is! PlaybackStarted) { // PlaybackStarted is an old event, consider removing or mapping to new states
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                          _buildTabButton(
                            label: 'Record',
                            isSelected: !_showRecordingsList,
                            onTap: () => setState(() => _showRecordingsList = false),
                          ),
                          const SizedBox(width: 20),
                          _buildTabButton(
                            label: 'Saved',
                            isSelected: _showRecordingsList,
                            onTap: () {
                              setState(() {
                                _showRecordingsList = true;
                                
                                // If TabController was disposed or not initialized, create it again
                                if (_savedTabController == null || !_savedTabController!.hasListeners) {
                                  _savedTabController = TabController(length: 2, vsync: this);
                                  _savedTabController!.addListener(() {
                                    if (!_savedTabController!.indexIsChanging) {
                                      setState(() {
                                        _selectedSavedTab = _savedTabController!.index;
                                      });
                                      
                                      // Load server recordings when switching to server tab
                                      if (_selectedSavedTab == 1) {
                                        _audioDashboardBloc.add(const LoadServerRecordingsEvent());
                                      }
                                    }
                                  });
                                }
                              });
                              
                              // Load recordings after state is updated
                              _audioDashboardBloc.add(LoadRecordingsEvent());
                              
                              // Also load server recordings when viewing Saved tab
                              if (_selectedSavedTab == 1) {
                                _audioDashboardBloc.add(const LoadServerRecordingsEvent());
                              }
                            },
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                
                const SizedBox(height: 15),
                
                Expanded(
                  child: BlocConsumer<AudioDashboardBloc, AudioDashboardState>(
                    listener: (context, state) {
                      if (state is AudioDashboardError) {
                        // Only show permission dialog for permission-related errors
                        if (state.message.toLowerCase().contains('permission')) {
                          _showPermissionDialog(context, state.message);
                        } else {
                          // For other errors, just show a snackbar
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.message),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    },
                    builder: (context, state) {
                      if (state is AudioDashboardError) {
                        // Only show permission UI for permission-related errors
                        if (state.message.toLowerCase().contains('permission')) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(state.message),
                                ElevatedButton(
                                  onPressed: () => _requestPermissions(), // Removed context argument
                                  child: const Text('Grant Permissions'),
                                ),
                              ],
                            ),
                          );
                        } else {
                          // For other errors, show normal UI with error message
                          // This prevents the UI from being completely blocked by non-permission errors
                          print("Non-permission error: ${state.message}");
                          // Continue with normal UI rendering
                        }
                      }
                      if (_showRecordingsList) {
                        return _buildSavedRecordingsList();
                      }
                      
                      return Column(
                        children: [
                          _buildVisualization(),
                          const SizedBox(height: 20),
                          _buildTimer(),
                          const SizedBox(height: 20),
                          _buildControls(),
                        ],
                      );
                    },
                  ),
                ),
                
                // Show playback interface at the bottom when playing a saved recording
                // The condition for showing this is now _currentPlayingPath != null OR _showPlayerWithoutAudio
                if (_currentPlayingPath != null || _showPlayerWithoutAudio)
                  GestureDetector(
                        // Stop propagation of taps to parent (to prevent closing when tapping on player UI)
                        onTap: () => {}, 
                    child: _buildPlayingInterface(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Appcolors.kprimaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildVisualization() {
    return BlocConsumer<AudioDashboardBloc, AudioDashboardState>(
      listenWhen: (previous, current) {
        return current is RecordingInProgress || 
               current is RecordingPaused || 
               current is RecordingStopped ||
               current is PlaybackInProgress ||
               current is PlaybackPaused;
      },
      listener: (context, state) {
        if (state is RecordingInProgress || (state is PlaybackInProgress && state.filePath == _currentPlayingPath)) {
          if (!_animationController.isAnimating) {
            _animationController.repeat(reverse: true);
          }
        } else {
          if (_animationController.isAnimating) {
            _animationController.stop();
          }
        }
      },
      builder: (context, state) {
        Color barColor = Colors.grey.shade300;
        
        if (state is RecordingInProgress) {
          barColor = Appcolors.kredColor;
        } else if (state is RecordingPaused) {
          barColor = Appcolors.kredColor.withOpacity(0.5);
        } else if (state is PlaybackInProgress && state.filePath == _currentPlayingPath) {
          barColor = Appcolors.kprimaryColor;
        } else if (state is PlaybackPaused && state.filePath == _currentPlayingPath) {
          barColor = Appcolors.kprimaryColor.withOpacity(0.5);
        }
        
        return Container(
          height: 120,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(
                  32,
                  (i) {
                    // Create a more dynamic wave pattern
                    final double phase = i / 32 * 2 * 3.14159;
                    final double wave1 = sin(phase + _animationController.value * 2 * 3.14159);
                    final double wave2 = sin(2 * phase + _animationController.value * 4 * 3.14159);
                    final double combinedWave = (wave1 + wave2) / 2;
                    
                    // Add some randomness for a more natural look
                    final double randomFactor = 0.2 + (Random().nextDouble() * 0.3);
                    
                    double barHeight = 20.0 + (60.0 * combinedWave.abs() * (1 + randomFactor));
                    
                    // If recording is paused, reduce the height
                    if (state is RecordingPaused || state is PlaybackPaused) {
                      barHeight *= 0.5;
                    }
                    
                    return Container(
                      width: 3.0,
                      height: barHeight.clamp(10.0, 80.0),
                      margin: const EdgeInsets.symmetric(horizontal: 1.0),
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTimer() {
    // AudioDashboardState? previousState; // Not used
    
    return BlocConsumer<AudioDashboardBloc, AudioDashboardState>(
      listenWhen: (previous, current) {
        // previousState = previous; // Not used
        return current is RecordingInProgress || 
               current is RecordingPaused || // Listen for RecordingPaused as well
               current is PlaybackInProgress || // Also listen for PlaybackInProgress
               current is PlaybackPaused || // And PlaybackPaused
               current is PlaybackStarted; // Simplified: listen for active states
      },
      listener: (context, state) {
        if (state is RecordingInProgress) {
          print("Recording in progress: ${state.duration} seconds");
        } else if (state is RecordingPaused) {
          print("Recording paused at: ${state.duration} seconds");
        } else if (state is PlaybackInProgress) {
          print("Playback in progress: ${state.position.inSeconds}/${state.duration.inSeconds} seconds");
        } else if (state is PlaybackPaused) {
          print("Playback paused at: ${state.position.inSeconds}/${state.duration.inSeconds} seconds");
        } else if (state is PlaybackStarted) {
          // Old state, keep for compatibility
        } 
      },
      builder: (context, state) {
        int duration = 0;
        if (state is RecordingInProgress) {
          duration = state.duration;
        } else if (state is RecordingPaused) { // Correctly handle RecordingPaused state
          duration = state.duration;
        } else if (state is PlaybackStarted) { // Old event, for compatibility during transition
           if (state.playingPath == _currentPlayingPath) { // Try to use UI current position for this old event
             duration = _currentPlaybackPositionSeconds;
           }
        } else if (state is PlaybackInProgress) {
          if (state.filePath == _currentPlayingPath) { // Only update for the currently playing track in UI
          duration = state.position.inSeconds;
          } else { // Otherwise, use the UI's timer value for the current path
            duration = _currentPlaybackPositionSeconds;
          }
        } else if (state is PlaybackPaused) {
          if (state.filePath == _currentPlayingPath) { // Only update for the currently paused track in UI
          duration = state.position.inSeconds;
          } else {
            duration = _currentPlaybackPositionSeconds;
          }
        } else if (_currentPlayingPath != null) {
            // If player UI is visible but BLoC is in other state (e.g. initial, loaded)
            // show the UI's current position for that path
            duration = _currentPlaybackPositionSeconds;
        }
        
        final minutes = (duration ~/ 60).toString().padLeft(2, '0');
        final seconds = (duration % 60).toString().padLeft(2, '0');
        
        print("Building timer with UI duration: $duration seconds, BLoC State: ${state.runtimeType}, Current UI Path: $_currentPlayingPath");
        
        bool isActiveStateForTimerDisplay = (state is RecordingInProgress) ||
                                           (state is RecordingPaused) || // Added RecordingPaused
                                           (state is PlaybackInProgress && state.filePath == _currentPlayingPath) ||
                                           (state is PlaybackPaused && state.filePath == _currentPlayingPath) ||
                                           (state is PlaybackStarted && state.playingPath == _currentPlayingPath);


        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isActiveStateForTimerDisplay
                ? Appcolors.kprimaryColor.withOpacity(0.1) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$minutes:$seconds',
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.bold,
              color: isActiveStateForTimerDisplay 
                  ? Appcolors.kprimaryColor 
                  : Colors.black54,
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return BlocConsumer<AudioDashboardBloc, AudioDashboardState>(
      listenWhen: (previous, current) {
        // Listen for relevant state changes
        return current is AudioDashboardError || 
               current is RecordingSubmitted;
      },
      listener: (context, state) {
        if (state is AudioDashboardError) {
          CustomSnackBar.show(
            context: context,
            title: 'Error',
            message: state.message,
            contentType: ContentType.failure,
          );
        } else if (state is RecordingSubmitted) {
          // Save the recording duration for future use
          final actualDuration = _currentRecordingDurationSeconds;
          if (actualDuration > 0) {
            print("Saving actual duration of $actualDuration seconds for recording: ${state.savedPath}");
            _saveRecordingDuration(state.savedPath, actualDuration);
          }
          
          // Show success notification
          CustomSnackBar.show(
            context: context,
            title: 'Success',
            // message: 'Recording saved successfully (${_formatDurationTime(actualDuration)})',
            message: 'Recording saved successfully',
            contentType: ContentType.success,
          );
          
          // Reset to initial state to show "Start Recording" button again
          Future.microtask(() {
            _audioDashboardBloc.add(ResetRecordingEvent());
          });
          _cleanupPlayback(force: true);
        }
        
        print("AudioDashboardBloc state changed to: ${state.runtimeType}");
      },
      buildWhen: (previous, current) {
        // Build for state changes that affect the controls UI
        return true;
      },
      builder: (context, state) {
        print("Building controls with state: ${state.runtimeType}");
        
        // Check if audio is currently playing/paused
        final bool isAudioCurrentlyPlaying = state is PlaybackInProgress || state is PlaybackPaused;
        
        // If audio is playing/paused, always show the playback controls
        if (isAudioCurrentlyPlaying) {
          // For currently playing audio, show the same controls as for RecordingStopped
          final String? filePath = (state is PlaybackInProgress) ? state.filePath : 
                                (state is PlaybackPaused) ? state.filePath : null;
          
          if (filePath != null) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIconOnlyListenButton(filePath), // Pass the path of the playing file
                const SizedBox(width: 30),
                FloatingActionButton(
                  heroTag: "rerecord_button",
                  tooltip: null, // Disabled tooltip
                  backgroundColor: Appcolors.kprimaryColor,
                  child: const Icon(Icons.refresh, color: Colors.white, size: 30),
                  onPressed: () => _audioDashboardBloc.add(ResetRecordingEvent()),
                ),
                const SizedBox(width: 30),
                FloatingActionButton(
                  heroTag: "save_recording_button", // Different from "save_button" during recording
                  tooltip: null, // Disabled tooltip
                  backgroundColor: Appcolors.kgreenColor,
                  child: const Icon(Icons.upload_file, color: Colors.white, size: 30), // Suggests "save" or "submit"
                  onPressed: () => _audioDashboardBloc.add(SubmitRecordingEvent()),
                ),
              ],
            );
          }
        }
        
        if (state is AudioDashboardInitial || state is RecordingsLoaded || state is RecordingSubmitted) {
          // Show record button if BLoC is in a "ready" state (not active recording or playback)
          if (!(state is RecordingInProgress || state is RecordingPaused || state is RecordingStopped)) {
             return Center(
                child: FloatingActionButton(
                  heroTag: "start_recording_button", // Added unique heroTag
                  tooltip: "Start Recording", // Restored tooltip for accessibility
                  elevation: 4,
                  backgroundColor: Appcolors.kprimaryColor,
                  child: const Icon(Icons.mic, size: 36, color: Colors.white),
                  onPressed: () {
                    print(">>> RECORD BUTTON PRESSED <<<");
                    _audioDashboardBloc.add(StartRecordingEvent(context: context));
                  },
                ),
              );
          }
        }
        
        if (state is RecordingInProgress || state is RecordingStarted) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                heroTag: "pause_recording_button",
                tooltip: "Pause Recording", // Restored tooltip
                elevation: 4,
                backgroundColor: Appcolors.kprimaryColor,
                child: const Icon(Icons.pause, size: 36, color: Colors.white),
                onPressed: () {
                  _audioDashboardBloc.add(PauseRecordingEvent());
                },
              ),
              const SizedBox(width: 30),
              FloatingActionButton(
                heroTag: "stop_recording_button_from_in_progress", // Made unique
                tooltip: "Stop Recording", // Restored tooltip
                elevation: 4,
                backgroundColor: Appcolors.kredColor,
                child: const Icon(Icons.stop, size: 36, color: Colors.white),
                onPressed: () {
                  _audioDashboardBloc.add(StopRecordingEvent());
                },
              ),
            ],
          );
        }
        
        if (state is RecordingPaused) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                heroTag: "resume_recording_button",
                tooltip: "Resume Recording", // Restored tooltip
                elevation: 4,
                backgroundColor: Appcolors.kprimaryColor,
                child: const Icon(Icons.mic, size: 36, color: Colors.white),
                onPressed: () {
                  _audioDashboardBloc.add(ResumeRecordingEvent());
                },
              ),
              const SizedBox(width: 30),
              FloatingActionButton(
                heroTag: "stop_recording_button_from_paused", // Made unique
                tooltip: "Stop Recording", // Restored tooltip
                elevation: 4,
                backgroundColor: Appcolors.kredColor,
                child: const Icon(Icons.stop, size: 36, color: Colors.white),
                onPressed: () {
                  _audioDashboardBloc.add(StopRecordingEvent());
                },
              ),
            ],
          );
        }
        
        // Handle both RecordingStopped and PlaybackStarted (old event)
        // This section is for the audio recorded in *this session* but not yet saved.
        if (state is RecordingStopped) { 
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIconOnlyListenButton(state.filePath), // Pass the path of the stopped recording
              const SizedBox(width: 30),
              FloatingActionButton(
                heroTag: "rerecord_button",
                tooltip: null, // Disabled tooltip
                backgroundColor: Appcolors.kprimaryColor,
                child: const Icon(Icons.refresh, color: Colors.white, size: 30),
                onPressed: () => _audioDashboardBloc.add(ResetRecordingEvent()),
              ),
              const SizedBox(width: 30),
              FloatingActionButton(
                heroTag: "save_recording_button", // Different from "save_button" during recording
                tooltip: null, // Disabled tooltip
                backgroundColor: Appcolors.kgreenColor,
                child: const Icon(Icons.upload_file, color: Colors.white, size: 30), // Suggests "save" or "submit"
                onPressed: () => _audioDashboardBloc.add(SubmitRecordingEvent()),
              ),
            ],
          );
        }
        
        return const SizedBox.shrink(); // Default for other states e.g. PlaybackInProgress, PlaybackPaused if not covered
      },
    );
  }

  Widget _buildIconOnlyListenButton(String? unsavedRecordingPath) { // Accept the path
    // This button is for the just-recorded, unsaved audio.
    
    return BlocConsumer<AudioDashboardBloc, AudioDashboardState>(
      listenWhen: (previous, current) {
        // Listen for states relevant to playing the passed unsavedRecordingPath.
        return (current is PlaybackInProgress && current.filePath == unsavedRecordingPath) ||
               (current is PlaybackPaused && current.filePath == unsavedRecordingPath) ||
               (current is RecordingStopped && current.filePath == unsavedRecordingPath) || // React if this specific recording stopped
               (current is RecordingStopped && unsavedRecordingPath == null) || // Also react if recording stopped and we didn't have a path (e.g. initial build)
               (current is AudioDashboardInitial); // Reset button if BLoC resets
      },
      listener: (context, state) {
        // Ensure the player interface is shown when playback starts
        if (state is PlaybackInProgress && state.filePath == unsavedRecordingPath) {
          if (mounted) {
            setState(() {
              _currentPlayingPath = state.filePath;
              _showPlayerWithoutAudio = true;
            });
          }
        } else if (state is PlaybackPaused && state.filePath == unsavedRecordingPath) {
          if (mounted) {
            setState(() {
              _currentPlayingPath = state.filePath;
              _showPlayerWithoutAudio = true;
            });
          }
        }
      },
      builder: (context, state) {
        bool isPlayingThisUnsavedRecording = false;
        if (unsavedRecordingPath != null) {
        if (state is PlaybackInProgress && state.filePath == unsavedRecordingPath) {
            isPlayingThisUnsavedRecording = true;
          }
        }
        
        // Enable play button if we have an unsavedRecordingPath and BLoC is in RecordingStopped (for that path) or Initial
        bool canPlayThisUnsavedRecording = unsavedRecordingPath != null && 
                                          ((state is RecordingStopped && state.filePath == unsavedRecordingPath) || state is AudioDashboardInitial);
                                          
        // If BLoC is paused for this specific unsaved recording, treat as "can play" (will resume)
        if (unsavedRecordingPath != null && state is PlaybackPaused && state.filePath == unsavedRecordingPath) {
            canPlayThisUnsavedRecording = true; // Allow resume
            // isPlayingThisUnsavedRecording will be false, so icon will be 'play'
        }

        return FloatingActionButton(
          heroTag: "listen_button_unsaved", // Ensure unique heroTag
          tooltip: null, // Disabled tooltip
          backgroundColor: Appcolors.kprimaryColor,
          onPressed: (canPlayThisUnsavedRecording || isPlayingThisUnsavedRecording) ? () {
            if (isPlayingThisUnsavedRecording) {
              print("IconOnlyListenButton: PAUSE unsaved recording ($unsavedRecordingPath)");
              _audioDashboardBloc.add(const PausePlaybackEvent()); 
            } else if (canPlayThisUnsavedRecording && unsavedRecordingPath != null) {
              // Set UI state to show player before dispatching event
              setState(() {
                _currentPlayingPath = unsavedRecordingPath;
                _showPlayerWithoutAudio = true;
              });
              
              // If BLoC is paused for this path, ResumePlaybackEvent will handle it.
              // If it's RecordingStopped or Initial, PlayRecordingEvent plays BLoC's internally stored _currentPath.
              // We need to ensure BLoC's _currentPath IS unsavedRecordingPath before PlayRecordingEvent.
              // The BLoC sets _currentPath upon RecordingStopped.
              // So, if state is RecordingStopped for this path, BLoC's internal path is already set.
              // If state is PlaybackPaused for this path, we want to resume.

              if (state is PlaybackPaused && state.filePath == unsavedRecordingPath) {
              print("IconOnlyListenButton: RESUME unsaved recording ($unsavedRecordingPath)");
              _audioDashboardBloc.add(const ResumePlaybackEvent());
              } else {
              print("IconOnlyListenButton: PLAY unsaved recording ($unsavedRecordingPath). Current BLoC state: ${state.runtimeType}");
                // This event tells BLoC to play its internally stored last recorded file path.
                // It's crucial that this internal path matches `unsavedRecordingPath` if we just stopped this one.
              _audioDashboardBloc.add(PlayRecordingEvent()); 
            }
            }
          } : null,
          child: Icon(
            isPlayingThisUnsavedRecording ? Icons.pause : Icons.play_arrow, 
            color: Colors.white, 
            size: 30
          ), 
        );
      },
    );
  }

  Widget _buildSavedRecordingsList() {
    // AudioDashboardState? previousState; // Not used
    
    return BlocConsumer<AudioDashboardBloc, AudioDashboardState>(
      listenWhen: (previous, current) {
        // previousState = previous; // Not used
        // Rebuild list if recordings are loaded, or if playback state changes for a list item
        return current is RecordingsLoaded || 
               current is PlaybackInProgress || 
               current is PlaybackPaused ||
               current is AudioDashboardError;
      },
      listener: (context, state) {
        // Existing listener code...
      },
      buildWhen: (previous, current) {
        // Rebuild for most state changes to ensure UI stays updated
        return true;
      },
      builder: (context, state) {
        if (state is AudioDashboardInitial && !(_showRecordingsList)) { // Only show loading if list is meant to be visible
          // This condition might be too aggressive. If _showRecordingsList is true, we expect data.
        }
        if (_showRecordingsList && !(state is RecordingsLoaded || state is PlaybackInProgress || state is PlaybackPaused)) {
            // If saved list is active but no relevant data state, show loader or trigger load
            // This indicates a potential state mismatch if we reach here after initial load.
             print("SavedRecordingsList: In unexpected state ${state.runtimeType} while list is visible. Triggering load.");
            _audioDashboardBloc.add(LoadRecordingsEvent()); // Load local
            if(_selectedSavedTab == 1) _audioDashboardBloc.add(const LoadServerRecordingsEvent()); // Load server if on server tab
            return const Center(child: CircularProgressIndicator());
        }

        
        List<Recording> allRecordings = [];
        
        if (state is RecordingsLoaded) {
          allRecordings = state.recordings;
          _cachedRecordings = state.recordings; // Update cache
        } else if (state is PlaybackInProgress) { // If playing, list might not have been reloaded yet
          allRecordings = _cachedRecordings; // Use cache
        } else if (state is PlaybackPaused) { // If paused, use cache
          allRecordings = _cachedRecordings;
        } else {
          // Use cached recordings for all other states if _showRecordingsList is true
          if(_showRecordingsList) allRecordings = _cachedRecordings;
        }
        
        // Filter recordings based on selected tab
        List<Recording> localRecordings = allRecordings.where((rec) => !rec.serverSaved).toList();
        List<Recording> serverRecordings = allRecordings.where((rec) => rec.serverSaved).toList();
        
        // Debug logs to diagnose server recordings issue
        print("=== RECORDINGS DEBUG (Builder: ${state.runtimeType}) ===");
        print("Total cached recordings: ${_cachedRecordings.length}");
        print("Local recordings (from allRecordings): ${localRecordings.length}");
        print("Server recordings (from allRecordings): ${serverRecordings.length}");
        
        // if (serverRecordings.isEmpty && _selectedSavedTab == 1) { // This might re-trigger load too often
        //   print("No server recordings found, explicitly loading server recordings");
        //   _audioDashboardBloc.add(const LoadServerRecordingsEvent());
        // }
        
        List<Recording> currentTabRecordings = _selectedSavedTab == 0 ? localRecordings : serverRecordings;
        
        print("Current tab: ${_selectedSavedTab == 0 ? 'Local' : 'Server'} with ${currentTabRecordings.length} recordings");
        print("=== END DEBUG ===");
        
        return Column(
          children: [
            // Tab bar for Local/Server
            DefaultTabController(
              length: 2,
              child: TabBar(
                controller: _savedTabController,
                tabs: const [
                  Tab(text: 'Local Recordings'),
                  Tab(text: 'On Cloud'),
                ],
                labelColor: Appcolors.kprimaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Appcolors.kprimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            
            // Add refresh button for server tab
            if (_selectedSavedTab == 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        print("Manual refresh - loading server recordings");
                        _audioDashboardBloc.add(const LoadServerRecordingsEvent());
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Refresh'),
                      style: TextButton.styleFrom(
                        foregroundColor: Appcolors.kprimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Tab content
            Expanded(
              child: currentTabRecordings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selectedSavedTab == 0 ? Icons.mic_off : Icons.cloud_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedSavedTab == 0
                                ? 'No local recordings saved yet'
                                : 'No recordings saved to server yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (_selectedSavedTab == 1) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                print("Refresh button pressed - loading server recordings");
                                _audioDashboardBloc.add(const LoadServerRecordingsEvent());
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Appcolors.kprimaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: currentTabRecordings.length,
                      itemBuilder: (context, index) {
                        final recording = currentTabRecordings[index];
                        // Determine if this specific recording is playing based on BLoC state and path
                        bool isThisRecordingPlaying = false;
                        final currentBlocState = _audioDashboardBloc.state; // get BLoC state directly in builder
                        if (currentBlocState is PlaybackInProgress && currentBlocState.filePath == recording.path) {
                          isThisRecordingPlaying = true;
                        }
                        // Optionally, consider PlaybackPaused as "active" for UI highlighting
                         else if (currentBlocState is PlaybackPaused && currentBlocState.filePath == recording.path) {
                           // isThisRecordingPlaying = true; // Or a different visual state for paused
                        }
                        
                        // Debug logging
                        // print('Recording ${recording.name} has duration: ${recording.duration} seconds');
                        
                        // Custom styled list item to match reference image
                        return InkWell(
                          onTap: () {
                            if (isThisRecordingPlaying) { // if BLoC says PlaybackInProgress for this path
                              print("Tapped playing recording (${recording.name}) in list. Requesting PAUSE via BLoC.");
                              _audioDashboardBloc.add(const PausePlaybackEvent());
                            } else {
                               // If BLoC is PlaybackPaused for this path, or not playing this path at all
                              print("Tapped non-playing/paused recording (${recording.name}) in list. Requesting PLAY via _handlePlaybackWithPath.");
                              _handlePlaybackWithPath(context, recording.path); // This will set UI path and send BLoC event
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: isThisRecordingPlaying ? Appcolors.kredColor.withOpacity(0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Row(
                              children: [
                                // Play/Pause icon
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isThisRecordingPlaying ? Appcolors.kredColor : Colors.grey[300],
                                  ),
                                  child: Icon(
                                    isThisRecordingPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16.0),
                                // File name and duration
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Filename
                                      Text(
                                        recording.name,
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.w500,
                                          color: isThisRecordingPlaying ? Appcolors.kredColor : Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4.0),
                                      // Time and date
                                      RichText(
                                        text: TextSpan(
                                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                                          children: [
                                            TextSpan(
                                              text: '${_formatDuration(Duration(seconds: recording.duration))} · ${_formatDate(recording.date)}',
                                              style: const TextStyle(fontWeight: FontWeight.normal),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Storage indicator or upload icon
                                _selectedSavedTab == 0
                                    ? IconButton(
                                        icon: const Icon(Icons.cloud_upload, color: Appcolors.kprimaryColor),
                                        onPressed: () {
                                          _saveRecordingToServer(context, recording);
                                        },
                                      )
                                    : const Icon(Icons.cloud_done, color: Colors.green),
                                // More options button
                                IconButton(
                                  icon: Icon(Icons.more_horiz, color: Colors.grey[600]),
                                  onPressed: () {
                                    _showRecordingOptions(context, recording);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) => Divider(height: 1.0, color: Colors.grey[300]),
                    ),
            ),
          ],
        );
      },
    );
  }

  // Show recording options in a popup menu
  void _showRecordingOptions(BuildContext context, Recording recording) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Title
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Icon(Icons.settings, color: Appcolors.kprimaryColor, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Recording Options',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 16),
                
                // Options list
                ListTile(
                  leading: const Icon(Icons.play_arrow, color: Appcolors.kprimaryColor),
                  title: const Text('Play Recording'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _handlePlaybackWithPath(context, recording.path);
                  },
                ),
                
                // Rename option for both local and server recordings
                ListTile(
                  leading: const Icon(Icons.edit, color: Appcolors.kprimaryColor),
                  title: const Text('Rename Recording'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    if (recording.serverSaved && recording.path.startsWith('server://')) {
                      _showServerRenameDialog(context, recording);
                    } else {
                      _showRenameDialog(context, recording);
                    }
                  },
                ),
                
                // Save to server option (if not already saved)
                if (!recording.serverSaved) 
                  ListTile(
                    leading: const Icon(Icons.cloud_upload, color: Appcolors.kprimaryColor),
                    title: const Text('Save to Server'),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      _saveRecordingToServer(context, recording);
                    },
                  ),
                
                // Edit Audio option (only for server recordings)
                if (recording.serverSaved)
                  ListTile(
                    leading: const Icon(Icons.auto_fix_high, color: Appcolors.kprimaryColor),
                    title: const Text('Edit Audio'),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      _navigateToAudioEditor(context, recording);
                    },
                  ),
                
                // Share option
                  ListTile(
                    leading: const Icon(Icons.share, color: Appcolors.kprimaryColor),
                    title: const Text('Share Recording'),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                    if (recording.serverSaved) {
                      _shareServerRecording(context, recording);
                    } else {
                      _shareLocalRecording(context, recording);
                    }
                    },
                  ),

                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete Recording'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    // Use the appropriate delete method based on recording type
                    if (recording.serverSaved && recording.path.startsWith('server://')) {
                      _showServerDeleteConfirmation(context, recording);
                    } else {
                      _showDeleteConfirmation(context, recording);
                    }
                  },
                ),
                
                // Add Logout option only if _signupApp equals "1"
                if (_signupApp == "1")
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout'),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      _showLogoutConfirmation(context);
                    },
                  ),
                // Add these options when _signupApp equals "0" (or is null/empty)
                if (_signupApp != "1")
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout'),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      _showLogoutConfirmation(context);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Show logout confirmation dialog
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Logout', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                
                try {
                  // Clear shared preferences
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  
                  // Navigate to login page
                  if (mounted && context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                      (Route<dynamic> route) => false,
                    );
                  }
                } catch (e) {
                  print("Error during logout: $e");
                  CustomSnackBar.show(
                    context: context,
                    title: 'Error',
                    message: 'Failed to logout: ${e.toString()}',
                    contentType: ContentType.failure,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Show dialog to rename recording
  void _showRenameDialog(BuildContext context, Recording recording) {
    final TextEditingController nameController = TextEditingController(text: recording.name);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit, color: Colors.blue),
              SizedBox(width: 8),
              Text('Rename Recording'),
            ],
          ),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'New Name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('Rename', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                final newTitle = nameController.text.trim();
                if (newTitle.isEmpty) {
                  CustomSnackBar.show(
                    context: context,
                    title: 'Error',
                    message: 'Please enter a valid name',
                    contentType: ContentType.failure,
                  );
                  return;
                }

                Navigator.of(context).pop();

                if (recording.serverSaved) {
                  _renameServerRecording(context, recording, newTitle);
                } else {
                  _renameLocalRecording(context, recording, newTitle);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _renameLocalRecording(BuildContext context, Recording recording, String newTitle) async {
    try {
      // If the new title includes an extension, remove it for the recording name
      String nameForRecordingObject = newTitle;
      if (newTitle.toLowerCase().endsWith('.wav') || newTitle.toLowerCase().endsWith('.mp3') || newTitle.toLowerCase().endsWith('.m4a')) {
          nameForRecordingObject = newTitle.substring(0, newTitle.lastIndexOf('.'));
      }

      final oldFile = File(recording.path);
      if (!await oldFile.exists()) {
        CustomSnackBar.show(
          context: context,
          title: 'Error',
          message: 'Recording file not found',
          contentType: ContentType.failure,
        );
        return;
      }

      // Get directory and create new path with new name
      final directory = oldFile.parent;
      final extension = recording.path.split('.').last;
      
      // Ensure the new title for the file path doesn't have the extension duplicated
      String newFileName = newTitle;
      if (newFileName.toLowerCase().endsWith(".$extension")) {
        newFileName = newFileName.substring(0, newFileName.length - (extension.length + 1));
      }
      final newPath = '${directory.path}/$newFileName.$extension';

      // Rename the file
      await oldFile.rename(newPath);

      // Create updated recording object
      final updatedRecording = Recording(
        path: newPath,
        name: nameForRecordingObject, // Use the title without extension for the name
        date: recording.date,
        duration: recording.duration,
        serverSaved: false,
      );

      // Update cached recordings
      setState(() {
        _cachedRecordings.removeWhere((r) => r.path == recording.path);
        _cachedRecordings.add(updatedRecording);
        _cachedRecordings.sort((a, b) => b.date.compareTo(a.date));
      });

      // Save to SharedPreferences to persist the changes
      await _saveRecordingsToPrefs();

      // Show success message
      CustomSnackBar.show(
        context: context,
        title: 'Renamed',
        message: 'Recording has been renamed successfully',
        contentType: ContentType.success,
      );

      // Update bloc state
      _audioDashboardBloc.add(LoadRecordingsEvent());
    } catch (e) {
      // Check if the widget is still mounted before showing the snackbar
      if (!context.mounted) return;
      CustomSnackBar.show(
        context: context,
        title: 'Error',
        message: 'Failed to rename recording: $e',
        contentType: ContentType.failure,
      );
    }
  }

  // Helper method to save recordings to SharedPreferences
  Future<void> _saveRecordingsToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localRecordings = _cachedRecordings.where((r) => !r.serverSaved).toList();
      final encodedRecordings = json.encode(localRecordings.map((r) => r.toJson()).toList());
      await prefs.setString(_localRecordingsKey, encodedRecordings);
    } catch (e) {
      debugPrint('Error saving recordings to SharedPreferences: $e');
    }
  }

  // Show recording information
  void _showRecordingInfo(BuildContext context, Recording recording) {
    // Format file size
    String fileSize = "Unknown";
    try {
      final File file = File(recording.path);
      final int sizeInBytes = file.lengthSync();
      
      if (sizeInBytes < 1024) {
        fileSize = "$sizeInBytes B";
      } else if (sizeInBytes < 1024 * 1024) {
        fileSize = "${(sizeInBytes / 1024).toStringAsFixed(2)} KB";
      } else {
        fileSize = "${(sizeInBytes / (1024 * 1024)).toStringAsFixed(2)} MB";
      }
    } catch (e) {
      fileSize = "Could not determine";
      print("Error getting file size: $e");
    }
    
    // Format duration
    String duration = _formatDuration(Duration(seconds: recording.duration));
    
    // Get user name from SharedPreferences
    String userName = "User";
    SharedPreferences.getInstance().then((prefs) {
      userName = prefs.getString('USER_NAME') ?? "Current User";
    });
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Recording Info'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('Title', recording.name),
                const SizedBox(height: 8),
                _infoRow('Subtitle', 'Voice Recording'),
                const SizedBox(height: 8),
                _infoRow('Voice Artist Name', userName),
                const SizedBox(height: 8),
                _infoRow('Date Recorded', _formatDate(recording.date)),
                const SizedBox(height: 8),
                _infoRow('Duration', duration),
                const SizedBox(height: 8),
                _infoRow('Bit Rate', '128 kbps'),
                const SizedBox(height: 8),
                _infoRow('Channel', 'Mono'),
                const SizedBox(height: 8),
                _infoRow('Sampling Rate', '44.1 kHz'),
                const SizedBox(height: 8),
                _infoRow('Size', fileSize),
                const SizedBox(height: 8),
                _infoRow('Recorded by', userName),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Appcolors.kprimaryColor,
              ),
              child: const Text('Close', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
  
  // Helper method to create info rows
  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Show delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context, Recording recording) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: Text("Are you sure you want to delete '${recording.name}'? This action cannot be undone."),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
              onPressed: () {
                if (recording.serverSaved) {
                  _audioDashboardBloc.add(DeleteServerRecordingEvent(recording.serverId!));
                } else {
                  _audioDashboardBloc.add(DeleteRecordingEvent(recording.path));
                }
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Create a waveform animation similar to the reference image
  Widget _buildWaveformAnimation({bool isRed = false}) {
    Color barColor = isRed ? Appcolors.kredColor : Appcolors.kprimaryColor;
    // This widget now purely relies on _animationController for its animation state.
    // The decision to show this animated widget vs. a static icon is made by the calling widgets,
    // based on BLoC state (e.g., isThisRecordingPlaying, displayAsPlaying).

    return SizedBox(
      width: 28.0,
      height: 28.0,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          // If _animationController is not animating (e.g., value is 0 or it's stopped),
          // this will render static bars based on the controller's current (likely 0) value.
          // If it IS animating, it will show the wave.
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              4,
              (i) {
                final double barHeight = 6.0 + 
                    (i == 0 || i == 3 ? 8.0 : 14.0) * 
                    _animationController.value;
                
                return Container(
                  width: 3.0,
                  height: barHeight.clamp(6.0, 20.0), // Ensure minimum height and clamp max
                  margin: const EdgeInsets.symmetric(horizontal: 1.0),
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(1.0),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Handle playing saved recordings, with support for both local and server recordings
  void _playSavedRecording(BuildContext context, Recording recording, {int startAtSeconds = 0}) {
    final recordingPath = recording.path;

    // Use a local orElse to handle cases where the recording might not be in the cache
    final foundRecording = _cachedRecordings.firstWhere((rec) => rec.path == recordingPath, orElse: () {
      final state = _audioDashboardBloc.state;
      if (state is RecordingsLoaded) {
        // Check server recordings if not found locally
        return state.serverRecordings.firstWhere((rec) => rec.path == recordingPath, orElse: () => recording);
      }
      return recording; // Fallback to the provided recording object
    });

    final isCurrentlyPlaying = _audioDashboardBloc.state is PlaybackInProgress && _currentPlayingPath == foundRecording.path;

    if (isCurrentlyPlaying && startAtSeconds == 0) {
      _audioDashboardBloc.add(const PausePlaybackEvent());
      return;
    }
    
    int durationInSeconds = foundRecording.duration;
    print("UI _playSavedRecording: Playing ${foundRecording.name}, start: $startAtSeconds s, total: $durationInSeconds s");

    setState(() {
      _currentPlayingPath = foundRecording.path;
      _totalDurationSeconds = durationInSeconds;
      _currentPlaybackPositionSeconds = startAtSeconds;
      _showPlayerWithoutAudio = true;
    });

    _audioDashboardBloc.add(PlaySavedRecordingEvent(foundRecording.path, startAt: Duration(seconds: startAtSeconds)));
  }

  Widget _buildPlayingInterface() {
    // If _currentPlayingPath is null, player should not be visible, handled by the outer if.
    // This _showPlayerWithoutAudio helps keep it visible briefly if BLoC is slow to emit first PlaybackInProgress
    if (_currentPlayingPath == null && !_showPlayerWithoutAudio) return const SizedBox.shrink();

    // Find the currently playing recording details for display (name, etc.)
    Recording? playingRecordingDisplayData;
    if (_currentPlayingPath != null) {
        playingRecordingDisplayData = _cachedRecordings.firstWhere(
            (r) => r.path == _currentPlayingPath,
            orElse: () {
                String name = _currentPlayingPath!.split('/').last;
                return Recording(
                    path: _currentPlayingPath!, 
                    name: name, 
                    date: DateTime.now(), 
                    duration: _totalDurationSeconds, // Use UI's current total duration for display if not in cache
                    serverId: null // Cannot determine serverId for a non-cached item here
                );
            }
        );
    }
    if (playingRecordingDisplayData == null && _showPlayerWithoutAudio && _currentPlayingPath != null) {
        // If we force show player but no recording data, make a placeholder
        playingRecordingDisplayData = Recording(path: _currentPlayingPath!, name: _currentPlayingPath!.split('/').last, date: DateTime.now(), duration: _totalDurationSeconds);
    }
    
    // Derive UI display state directly from BLoC
    final currentBlocState = context.watch<AudioDashboardBloc>().state;
    bool displayAsPlaying = false;
    bool displayAsPaused = false;
    int displayPositionSeconds = _currentPlaybackPositionSeconds; // Fallback to UI timer's position
    int displayTotalDurationSeconds = _totalDurationSeconds; // Fallback to UI timer's total duration

    // Always check if any recording is currently playing or paused in BLoC state
    if (currentBlocState is PlaybackInProgress) {
      // If BLoC is playing something, update UI state to match
      _currentPlayingPath = currentBlocState.filePath; // Ensure path is updated
      displayAsPlaying = true;
      displayAsPaused = false;
      displayPositionSeconds = currentBlocState.position.inSeconds;
      displayTotalDurationSeconds = currentBlocState.duration.inSeconds;
      // Force player visibility
      _showPlayerWithoutAudio = true;
    } else if (currentBlocState is PlaybackPaused) {
      // If BLoC has something paused, update UI state to match
      _currentPlayingPath = currentBlocState.filePath; // Ensure path is updated
      displayAsPlaying = false;
      displayAsPaused = true;
      displayPositionSeconds = currentBlocState.position.inSeconds;
      displayTotalDurationSeconds = currentBlocState.duration.inSeconds;
      // Force player visibility
      _showPlayerWithoutAudio = true;
    } else if (currentBlocState is RecordingStopped && currentBlocState.filePath != null) {
      // If recording was just stopped, update path and show player
      _currentPlayingPath = currentBlocState.filePath;
      _showPlayerWithoutAudio = true;
      displayAsPlaying = false;
      displayAsPaused = false;
    } else if (_currentPlayingPath != null) {
        // If BLoC is not playing/paused OR is playing a DIFFERENT path,
        // then for THIS currentPlayingPath, it's effectively stopped or just selected.
        // We rely on _currentPlaybackPositionSeconds for the slider position if just selected.
        displayAsPlaying = false;
        displayAsPaused = false; // Or true if we want to show paused icon at current slider pos.
                                 // For now, show play icon if not actively playing/paused by BLoC for this path.
    }

    // If _currentPlayingPath is set but BLoC state doesn't match, the UI timer might be ahead or behind.
    // Let BLoC state be the primary driver for displayPosition and displayTotalDuration when active for this path.
    // The _playerPositionTimer in _startPlaybackTracking is responsible for updating _currentPlaybackPositionSeconds
    // and _totalDurationSeconds based on BLoC state as well, attempting to keep them in sync.

    // Format time values using the derived display values
    final currentTimeStr = _formatDurationTime(displayPositionSeconds);
    final remainingSeconds = displayTotalDurationSeconds - displayPositionSeconds;
    final remainingTimeStr = '-${_formatDurationTime(remainingSeconds < 0 ? 0 : remainingSeconds)}';
    
    final sliderValue = displayTotalDurationSeconds > 0 ? 
        (displayPositionSeconds / displayTotalDurationSeconds).clamp(0.0, 1.0) : 0.0;

    final bool isPlaybackConsideredFinishedForDisplay = displayAsPaused && displayPositionSeconds >= displayTotalDurationSeconds && displayTotalDurationSeconds > 0;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.grey.shade50],
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8.0,
            offset: Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: filename, controls, and close button in one row
          Row(
            children: [
              // Waveform icon
              displayAsPlaying 
                ? _buildWaveformAnimation(isRed: true)
                : Icon(Icons.graphic_eq, color: Colors.grey[400], size: 20.0),
              const SizedBox(width: 8.0),
              // Filename
              Expanded(
                child: Text(
                  playingRecordingDisplayData?.name ?? "Audio Track",
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Control buttons in a row
              BlocBuilder<AudioDashboardBloc, AudioDashboardState>(
                builder: (context, state) {
                  final bool isPlaying = state is PlaybackInProgress && state.filePath == _currentPlayingPath;
                  final bool isPaused = state is PlaybackPaused && state.filePath == _currentPlayingPath;
                  
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (_currentPlayingPath == null) return;
                        if (isPlaying) {
                          print("Pausing playback for: $_currentPlayingPath");
                          context.read<AudioDashboardBloc>().add(const PausePlaybackEvent());
                        } else {
                          print("Resuming playback for: $_currentPlayingPath");
                          context.read<AudioDashboardBloc>().add(const ResumePlaybackEvent());
                        }
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isPlaying ? Appcolors.kredColor : (isPaused ? Appcolors.kredColor.withOpacity(0.8) : Colors.grey[300]),
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: isPlaying || isPaused ? Colors.white : Colors.black87,
                          size: 24.0,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8.0),
              // Skip buttons with smaller size
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCompactSkipButton(false), // Backward 10s
                  const SizedBox(width: 4.0),
                  _buildCompactSkipButton(true),  // Forward 10s
                ],
              ),
              const SizedBox(width: 8.0),
              // Close button
              InkWell(
                onTap: () {
                  print("Close button tapped. Stopping and hiding player.");
                  _stopAndHidePlayerUI(); // Use the new method
                },
                child: Container(
                  width: 28.0,
                  height: 28.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.black87,
                    size: 16.0,
                  ),
                ),
              ),
            ],
          ),
          
          // Speed controls
          _buildSpeedControls(),

          // Slider and time display
          Row(
            children: [
              Text(currentTimeStr, 
                  style: TextStyle(fontSize: 10.0, color: Colors.grey[600])),
              const SizedBox(width: 4.0),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Appcolors.kredColor,
                    inactiveTrackColor: Colors.grey[300],
                    thumbColor: Appcolors.kredColor,
                    trackHeight: 2.0,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                  ),
                  child: Slider(
                    value: sliderValue,
                    onChanged: (value) {
                      if (_currentPlayingPath == null) return;
                      final newPositionSeconds = (value * displayTotalDurationSeconds).round();
                      setState(() {
                        _currentPlaybackPositionSeconds = newPositionSeconds;
                      });
                    },
                    onChangeEnd: (value) async {
                      if (_currentPlayingPath == null) return;
                      final newPositionSeconds = (value * displayTotalDurationSeconds).round();
                      
                      // Use SeekPlaybackEvent instead of stopping and restarting
                      context.read<AudioDashboardBloc>().add(
                        SeekPlaybackEvent(Duration(seconds: newPositionSeconds))
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 4.0),
              Text(remainingTimeStr, 
                  style: TextStyle(fontSize: 10.0, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 8.0),
        ],
      ),
    );
  }

  // Add a more compact skip button for the player UI
  Widget _buildCompactSkipButton(bool forward) {
    return InkWell(
      onTap: () {
        if (_currentPlayingPath == null) return;
        
        // Use SeekPlaybackEvent for skipping
        context.read<AudioDashboardBloc>().add(
          SeekPlaybackEvent(Duration(seconds: forward ? 10 : -10), relative: true),
        );
      },
      child: Icon(
        forward ? Icons.forward_10_rounded : Icons.replay_10_rounded,
        color: Colors.black54,
        size: 20.0,
      ),
    );
  }

  void _showCustomNotification(BuildContext context, String message) {
    CustomSnackBar.show(
      context: context,
      title: 'Info',
      message: message,
      contentType: ContentType.help,
    );
  }

  void _showCustomErrorNotification(BuildContext context, String message) {
    CustomSnackBar.show(
      context: context,
      title: 'Error',
      message: message,
      contentType: ContentType.failure,
    );
  }

  void _showCustomSuccessNotification(BuildContext context, String message) {
    CustomSnackBar.show(
      context: context,
      title: 'Success',
      message: message,
      contentType: ContentType.success,
    );
  }

  void _showCustomErrorNotificationBottom(BuildContext context, String message) {
    _showCustomErrorNotification(context, message);
  }

  void _showCustomNotificationBottom(BuildContext context, String message) {
    _showCustomNotification(context, message);
  }

  void _showCustomDialog(BuildContext context, String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Appcolors.kprimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);
    
    if (dateToCheck == today) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    } else {
      return DateFormat('MMM d, yyyy - h:mm a').format(date);
    }
  }

  void _showPermissionDialog(BuildContext dialogContext, String message, {bool openSettingsOption = false}) {
    // Use dialogContext for showing the dialog, but use this.context (or a stored context) for BLoC operations
    // For simplicity, we'll call _requestPermissions AFTER the dialog is popped, using the main widget's context.
    showDialog(
      context: dialogContext, // This context is for the dialog itself
      builder: (BuildContext alertContext) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(alertContext), // Use alertContext to pop
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(alertContext); // Pop the dialog first
              // Now call _requestPermissions using the _RecordingPageState's context (this.context)
              // or a context that is known to have AudioDashboardBloc in its ancestry.
              if (openSettingsOption) {
                openAppSettings();
              } else {
                // It's generally safer to call methods that need a specific context 
                // (like one with a BLoC) from the widget's main build context or a stored one.
                // Assuming `context` here refers to the _RecordingPageState's build context.
                _requestPermissions(); 
              }
            },
            child: Text(openSettingsOption ? 'Open Settings' : 'Grant'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermissions() async {
    // No longer take context as a parameter, use this.context which is the State's context
    // Ensure this.context is available and has the BLoC.
    // It's generally good practice to check if mounted before async gaps if using this.context directly.
    if (!mounted) return;

    final bloc = context.read<AudioDashboardBloc>(); // this.context is implied
    bool permissionsGranted = true;

    // Request Microphone Permission
    PermissionStatus micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      permissionsGranted = false;
      if (micStatus.isPermanentlyDenied) {
        // Pass the build context of _RecordingPageState for showing subsequent dialogs
        _showPermissionDialog(context, 'Microphone permission has been permanently denied. Please enable it in app settings.', openSettingsOption: true);
      } else {
        _showPermissionDialog(context, 'Microphone permission is required for recording.');
      }
      return;
    }

    // Request Storage Permission
    // For Android 13+ (API 33), specific permissions like Photos, Videos, Audio might be needed
    // instead of broad external storage. For now, sticking with `Permission.storage`.
    // Consider `Permission.audio` or `Permission.manageExternalStorage` if issues persist on newer Android.
    PermissionStatus storageStatus = await Permission.storage.request();
    if (!storageStatus.isGranted) {
      permissionsGranted = false;
      if (storageStatus.isPermanentlyDenied) {
        _showPermissionDialog(context, 'Storage permission has been permanently denied. Please enable it in app settings to save recordings.', openSettingsOption: true);
      } else {
        _showPermissionDialog(context, 'Storage permission is required to save recordings.');
      }
      return;
    }
    
    // If Android 10 (API 29) or above, manageExternalStorage might be relevant for broader access if needed,
    // but typical app_flutter directory access should work with Permission.storage.
    // Only request if absolutely necessary and after checking platform version.
    if (Platform.isAndroid) {
        // Consider checking Android SDK version if more specific permissions are needed.
        // For now, Permission.storage should cover app-specific directories.
        // Example: final deviceInfo = await DeviceInfoPlugin().androidInfo;
        // if (deviceInfo.version.sdkInt >= 30) { /* Android 11+ specific logic */ }
    }

    if (permissionsGranted) {
      // If all permissions are granted, re-initialize or trigger a refresh in the BLoC.
      // Using ResetRecordingEvent as it seems to re-trigger initialization or loading.
      bloc.add(ResetRecordingEvent()); 
      // Alternatively, a specific event like PermissionsGrantedEvent could be added to the BLoC
      // to explicitly re-run parts of _initializeBloc or reload data.
      print("All necessary permissions granted. Resetting BLoC state.");
    }
  }

  // Helper method to format recording duration (sync version that displays interim value)
  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Add direct file deletion method
  Future<bool> _deleteRecordingFile(String filePath) async {
    try {
      // If deleting currently playing recording, stop playback first
      if (_currentPlayingPath == filePath) {
        // _isActuallyPlaying = false; // This line is removed as it's no longer needed for the condition
        _audioDashboardBloc.add(StopRecordingEvent()); // Stop BLoC player
        _cleanupPlayback(force: true); // Reset UI fully
      }

      final file = File(filePath);
      if (await file.exists()) {
        print("File exists, deleting: $filePath");
        await file.delete();
        final stillExists = await file.exists();
        print("File deleted successfully: $filePath (still exists: $stillExists)");
        
        // Also delete duration data when file is deleted
        _removeRecordingDuration(filePath);
        
        return !stillExists;
      } else {
        print("File does not exist: $filePath");
        return true; // Return true if file doesn't exist (already deleted)
      }
    } catch (e) {
      print("Error deleting file: $e");
      return false;
    }
  }
  
  // Method to store a recording's duration
  Future<void> _saveRecordingDuration(String filePath, int durationSeconds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'duration_${filePath.split('/').last}';
      await prefs.setInt(key, durationSeconds);
      print("Saved duration $durationSeconds seconds for recording: $key");
    } catch (e) {
      print("Error saving duration: $e");
    }
  }
  
  // Method to retrieve a recording's duration
  Future<int> _getRecordingDuration(String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'duration_${filePath.split('/').last}';
      final duration = prefs.getInt(key) ?? 0;
      print("Retrieved duration $duration seconds for recording: $key");
      return duration;
    } catch (e) {
      print("Error retrieving duration: $e");
      return 0;
    }
  }
  
  // Method to remove a recording's duration
  Future<void> _removeRecordingDuration(String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'duration_${filePath.split('/').last}';
      await prefs.remove(key);
      print("Removed duration data for recording: $key");
    } catch (e) {
      print("Error removing duration: $e");
    }
  }

  void _pausePlayback() {
    // This method is likely called from older UI parts or gestures.
    // It should request the BLoC to pause the currently playing audio.
    final currentBlocState = _audioDashboardBloc.state;
    if (currentBlocState is PlaybackInProgress && _currentPlayingPath == currentBlocState.filePath) {
      print("UI _pausePlayback: Requesting BLoC to PAUSE path: ${currentBlocState.filePath}");
      _audioDashboardBloc.add(const PausePlaybackEvent());
      // UI timer and animation will stop/update based on BLoC state changes handled by _startPlaybackTracking's timer
      // and _buildPlayingInterface.
      // We can optimistically update _pausedPositionSeconds for other UI parts if needed.
      if(mounted) {
        setState(() {
          _pausedPositionSeconds = _currentPlaybackPositionSeconds;
        });
      }
    } else {
      print("UI _pausePlayback: Not currently playing or path mismatch. BLoC State: ${currentBlocState.runtimeType}, UI Path: $_currentPlayingPath");
    }
  }

  void _resumePlayback() {
    if (_currentPlayingPath != null) {
      int positionToStartFrom = _pausedPositionSeconds;
      _cleanupPlayback();
      
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _currentPlayingPath != null) {
          _handlePlaybackWithPath(context, _currentPlayingPath!, startAtSeconds: positionToStartFrom);
        }
      });
    }
  }

  // Make sure we have clean versions for these to fix all references
  void _handleCancelRequest() {
    _audioDashboardBloc.add(StopRecordingEvent());
    _cleanupPlayback(force: true);
  }

  void _handlePausePlayToggle() {
    if (_currentPlayingPath == null) return;

    final currentBlocState = _audioDashboardBloc.state;
    bool isPlayingAccordingToBloc = false;
    if (currentBlocState is PlaybackInProgress && currentBlocState.filePath == _currentPlayingPath) {
      isPlayingAccordingToBloc = true;
    }

    print("UI _handlePausePlayToggle: Path: $_currentPlayingPath, isPlayingAccordingToBloc: $isPlayingAccordingToBloc");
    _togglePlayPauseWithForce(_currentPlayingPath!, isPlayingAccordingToBloc);
  }

  // Remove duplicate _cleanupPlayback method and replace _forceStopPlayback
  void _stopAndHidePlayerUI() {
    print("Stopping and hiding player UI requested.");
    _audioDashboardBloc.add(StopRecordingEvent()); // Tell BLoC to stop audio
    _cleanupPlayback(force: true); // Full UI reset, will set _currentPlayingPath = null
  }

  // Update _togglePlayPauseWithForce to use the new _cleanupPlayback method
  void _togglePlayPauseWithForce(String currentPath, bool isCurrentlyPlayingAudioAccordingToBloc) {
    // currentPath is _currentPlayingPath, which should be non-null if this is called.
    if (_currentPlayingPath == null || _currentPlayingPath != currentPath) {
        print("Warning: _togglePlayPauseWithForce called with path mismatch or null _currentPlayingPath. UI: $_currentPlayingPath, Argument: $currentPath");
        return;
    }

    if (isCurrentlyPlayingAudioAccordingToBloc) { // If BLoC (via UI interpretation) says it's playing (PlaybackInProgress) -> dispatch PAUSE
      print("Play/Pause Button: BLoC is PlaybackInProgress (UI sees as playing). Requesting PAUSE for: $currentPath at ${_currentPlaybackPositionSeconds}s");
      _audioDashboardBloc.add(const PausePlaybackEvent());
      
      // UI updates optimistically or via BLoC listener for PlaybackPaused state
      _playerPositionTimer?.cancel(); // Stop UI timer from incrementing further
      if (_animationController.isAnimating) _animationController.stop();
      if (mounted) {
        setState(() {
          _pausedPositionSeconds = _currentPlaybackPositionSeconds; // Save current UI position as the point of pause
        });
      }
      print("UI Paused (optimistically) at: $_pausedPositionSeconds. PausePlaybackEvent dispatched.");

    } else { // BLoC is not PlaybackInProgress for this path. It might be PlaybackPaused, Initial, or playing another track.
             // Request to PLAY/RESUME for currentPath.
      
      int positionToStartFrom = 0; 
      final currentBlocState = _audioDashboardBloc.state;

      if (currentBlocState is PlaybackPaused && currentBlocState.filePath == currentPath) {
        // If BLoC is paused for THIS track
        if (currentBlocState.position >= currentBlocState.duration && currentBlocState.duration > Duration.zero) { // Finished
          positionToStartFrom = 0; // Replay from beginning
          print("Play/Pause Button: Track was finished (Paused at end). Requesting REPLAY for $currentPath from $positionToStartFrom seconds.");
        } else { // Paused mid-track
          positionToStartFrom = currentBlocState.position.inSeconds;
           print("Play/Pause Button: BLoC is PlaybackPaused for this track. Requesting RESUME for $currentPath from $positionToStartFrom seconds.");
        }
      } else {
          // BLoC is not paused for THIS track (could be Initial, or playing something else, or UI just selected this track)
          // Use the UI's current slider position (_currentPlaybackPositionSeconds) or _pausedPositionSeconds if it seems more relevant
          // If slider is at the end of a non-BLoC-paused track, replay from 0.
          if (_currentPlaybackPositionSeconds >= _totalDurationSeconds && _totalDurationSeconds > 0) {
            positionToStartFrom = 0;
          } else {
            positionToStartFrom = _currentPlaybackPositionSeconds; 
          }
          print("Play/Pause Button: BLoC not PlaybackPaused for this track (State: ${currentBlocState.runtimeType}). Requesting PLAY for $currentPath from UI pos $positionToStartFrom s.");
      }
      
      // Dispatch ResumePlaybackEvent to BLoC. BLoC will handle if it needs to start new or resume.
      _audioDashboardBloc.add(const ResumePlaybackEvent()); 
      // The _playSavedRecording method is NOT called here anymore directly for resume.
      // BLoC state changes (to PlaybackInProgress) should restart the _playerPositionTimer via its logic.
      // We can call _startPlaybackTracking to get the UI going optimistically if needed,
      // but BLoC's PlaybackInProgress should be the main driver for the timer.

      if(mounted){
        setState(() {
          // Optimistically update UI state, BLoC will confirm via PlaybackInProgress state
          _currentPlaybackPositionSeconds = positionToStartFrom; 
        });
         // If we want immediate UI timer start, we can call _startPlaybackTracking here,
         // ensuring _totalDurationSeconds is correctly set for this path.
         // For now, let BLoC's PlaybackInProgress trigger the timer updates in _startPlaybackTracking.
         if (_totalDurationSeconds > 0) {
            _startPlaybackTracking(positionToStartFrom, _totalDurationSeconds); 
         } else {
            // If total duration is unknown, BLoC will provide it with PlaybackInProgress
            print("Play/Pause Button: Total duration for $currentPath is unknown, waiting for BLoC to provide it.");
         }
      }
    }
  }

  // Add back the helper method for formatting duration
  // Helper method to format duration string in mm:ss for display
  String _formatDurationTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  // Also add back _buildPlayerControlButton which is used by _buildSkipButton
  // Helper method for player control buttons
  Widget _buildPlayerControlButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
            ),
            child: Icon(icon, size: 20.0, color: Colors.black87),
          ),
        ),
        const SizedBox(height: 4.0),
        Text(label, style: TextStyle(fontSize: 10.0, color: Colors.grey[600])),
      ],
    );
  }

  // Add method to save recording to server
  void _saveRecordingToServer(BuildContext callerContext, Recording recording) async { 
    if (!mounted) return; // Initial check
    
    // Create a local variable to track if we need to pop the dialog
    bool dialogShown = false;

    try {
      // Show loading dialog using the State's current context
      if (mounted) {
        showDialog(
          context: context, 
          barrierDismissible: false,
          builder: (BuildContext ctx) {
            dialogShown = true;
            return const Center(child: CircularProgressIndicator());
          },
        );
      } else {
        return; // Exit early if not mounted
      }

      // Get SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();
      
      // Check mounted status after async operation
      if (!mounted) {
        return; // Exit if no longer mounted
      }

      // Get token - using USER_TOKEN instead of JWT_TOKEN
      final token = prefs.getString('USER_TOKEN');
      if (token == null) {
        // Close dialog if it was shown
        if (dialogShown && mounted) {
          Navigator.of(context).pop(); 
        }
        
        // Show error only if mounted
        if (mounted && widget.scaffoldMessengerKey.currentState != null) {
          widget.scaffoldMessengerKey.currentState!.showSnackBar(
            const SnackBar(
              content: Text("Authentication token not found. Please log in again."),
              backgroundColor: Colors.red,
            )
          );
        }
        return;
      }

      // Print token for debugging
      print("Using token: $token");

      // Check if recording file exists
      final File file = File(recording.path);
      final bool fileExists = await file.exists(); 
      
      // Check mounted status after async operation
      if (!mounted) {
        return; // Exit if no longer mounted
      }
      
      if (!fileExists) {
        // Close dialog if it was shown
        if (dialogShown && mounted) {
          Navigator.of(context).pop();
        }
        
        // Show error only if mounted
        if (mounted && widget.scaffoldMessengerKey.currentState != null) {
          widget.scaffoldMessengerKey.currentState!.showSnackBar(
            const SnackBar(
              content: Text("Recording file not found."),
              backgroundColor: Colors.red,
            )
          );
        }
        return;
      }

      // Read file as bytes
      List<int> audioBytes = await file.readAsBytes(); 
      
      // Check mounted status after async operation
      if (!mounted) {
        return; // Exit if no longer mounted
      }

      // Encode to base64
      String base64Audio = base64Encode(audioBytes);
      
      // Get user info
      final userName = prefs.getString('USER_NAME') ?? "Current User";
      final userId = prefs.getString('USER_ID'); 

      if (userId == null) {
        // Close dialog if it was shown
        if (dialogShown && mounted) {
          Navigator.of(context).pop();
        }
        
        // Show error only if mounted
        if (mounted && widget.scaffoldMessengerKey.currentState != null) {
          widget.scaffoldMessengerKey.currentState!.showSnackBar(
            const SnackBar(
              content: Text("User ID not found. Please log in again."),
              backgroundColor: Colors.red,
            )
          );
        }
        return;
      }
      
      // Prepare file metadata
      final String fileName = file.path.split('/').last;
      final Duration recordingDuration = Duration(seconds: recording.duration);

      // Send to server
      final dio = Dio();
      
      // Log request details
      print("Sending request to: https://vacha.langlex.com/Api/ApiController/saveRecording");
      print("With user_id: $userId");
      print("With token length: ${token.length}");
      
      try {
        // Print first 10 chars of token for debugging (don't print full token for security)
        print("Token starts with: ${token.length > 10 ? '${token.substring(0, 10)}...' : token}");
        
        // Try a different approach with Dio
        dio.options.headers = {
          'Authorization': token,
          'Content-Type': 'multipart/form-data',
        };
        print("Setting dio.options.headers directly: ${dio.options.headers}");
        
        // Create FormData with all fields
        final formData = FormData.fromMap({
          'title': recording.name,
          'subtitle': 'Recorded on LexSpeech',
          'voice_artist_name': userName,
          'date_recorded': recording.date.toIso8601String(),
          'duration': recordingDuration.inSeconds.toString(),
          'bit_rate': '128kbps', 
          'channel': 'Mono',
          'sampling_rate': '44100Hz',
          'recorded_by': userName,
          'file_path': fileName, 
          'audio_content': base64Audio, 
          'user_id': userId,
          // Also add token here in case the server looks for it in the POST data
          'token': token,
        });
        
        final response = await dio.post(
          'https://vacha.langlex.com/Api/ApiController/saveRecording',
          data: formData,
          // No longer using Options here
        );
        
        // Log response
        print("Response status: ${response.statusCode}");
        print("Response data: ${response.data}");
      
        // Close dialog if it was shown and we're still mounted
        if (dialogShown && mounted) {
          Navigator.of(context).pop();
        }

        // Exit if no longer mounted
        if (!mounted) return;

        // Process response
        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = response.data;
          if (responseData is Map && responseData['error'] == false) {
            if (mounted && widget.scaffoldMessengerKey.currentState != null) {
              CustomSnackBar.show(
                context: context,
                title: "Recording Saved",
                message: responseData['message'] ?? "Recording saved successfully!",
                contentType: ContentType.success,
              );
            }
            
            // Mark the recording as saved to the server
            final updatedRecording = Recording(
              path: recording.path,
              name: recording.name,
              date: recording.date,
              duration: recording.duration,
              serverSaved: true, // Set to true now that it's saved on the server
            );
            
            // Update the recordings list
            List<Recording> updatedRecordings = List.from(_cachedRecordings);
            int index = updatedRecordings.indexWhere((r) => r.path == recording.path);
            if (index != -1) {
              updatedRecordings[index] = updatedRecording;
              
              // Persist the server-saved status
              _saveServerSavedStatus(recording.path, true);
              
              // Update the AudioDashboardBloc with the new recording
              _audioDashboardBloc.add(LoadRecordingsEvent());
              
              // For instant UI update
              setState(() {
                _cachedRecordings = updatedRecordings;
                
                // Add null check for TabController
                _savedTabController?.animateTo(1);
              });
            }
          } else {
            String errorMessage = "Server error while saving recording.";
            if (responseData is Map && responseData['message'] != null) {
              errorMessage = responseData['message'];
            } else if (responseData != null) {
              errorMessage = responseData.toString();
            }
            
            if (mounted && widget.scaffoldMessengerKey.currentState != null) {
              widget.scaffoldMessengerKey.currentState!.showSnackBar(
                SnackBar(
                  content: Text(errorMessage),
                  backgroundColor: Colors.red,
                )
              );
            }
          }
        } else {
          if (mounted && widget.scaffoldMessengerKey.currentState != null) {
            widget.scaffoldMessengerKey.currentState!.showSnackBar(
              SnackBar(
                content: Text("Failed to save recording. Status: ${response.statusCode} ${response.statusMessage}"),
                backgroundColor: Colors.red,
              )
            );
          }
        }
      } catch (dioError, dioStackTrace) {
        print("Dio specific error: $dioError");
        print("Dio stack trace: $dioStackTrace");
        
        // Close dialog if it was shown and we're still mounted
        if (dialogShown && mounted) {
          Navigator.of(context).pop();
        }
        
        // Show error if we're still mounted
        if (mounted && widget.scaffoldMessengerKey.currentState != null) {
          widget.scaffoldMessengerKey.currentState!.showSnackBar(
            SnackBar(
              content: Text("Network error: ${dioError.toString()}"),
              backgroundColor: Colors.red,
            )
          );
        }
      }
    } catch (e, stackTrace) {
      print("Error saving recording: $e");
      print("Stack trace: $stackTrace");

      // Close dialog if it was shown and we're still mounted
      if (dialogShown && mounted) {
        Navigator.of(context).pop();
      }
      
      // Show error if we're still mounted
      if (mounted && widget.scaffoldMessengerKey.currentState != null) {
        widget.scaffoldMessengerKey.currentState!.showSnackBar(
          SnackBar(
            content: Text("An unexpected error occurred: ${e.toString()}"),
            backgroundColor: Colors.red,
          )
        );
      }
    }
  }

  // Helper method to save server-saved state in SharedPreferences
  Future<void> _saveServerSavedStatus(String filePath, bool isSaved) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Get existing saved paths or create a new set
      final savedPaths = prefs.getStringList('SERVER_SAVED_RECORDINGS') ?? <String>[];
      
      if (isSaved && !savedPaths.contains(filePath)) {
        savedPaths.add(filePath);
        await prefs.setStringList('SERVER_SAVED_RECORDINGS', savedPaths);
        print("Saved $filePath as server-saved recording");
      } else if (!isSaved && savedPaths.contains(filePath)) {
        savedPaths.remove(filePath);
        await prefs.setStringList('SERVER_SAVED_RECORDINGS', savedPaths);
        print("Removed $filePath from server-saved recordings");
      }
    } catch (e) {
      print("Error saving server-saved status: $e");
    }
  }
  
  // Helper method to load server-saved status for recordings
  Future<Set<String>> _loadServerSavedRecordings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPaths = prefs.getStringList('SERVER_SAVED_RECORDINGS') ?? <String>[];
      return savedPaths.toSet();
    } catch (e) {
      print("Error loading server-saved recordings: $e");
      return <String>{};
    }
  }

  void _rewindRecording() {
    if (_currentPlayingPath != null) {
      int newPosition = max(0, _currentPlaybackPositionSeconds - 5);
      
      _cleanupPlayback();
      _audioDashboardBloc.add(StopRecordingEvent());
      
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _currentPlayingPath != null) {
          _handlePlaybackWithPath(context, _currentPlayingPath!, startAtSeconds: newPosition);
        }
      });
    }
  }

  void _fastForwardRecording() {
    if (_currentPlayingPath != null) {
      int newPosition = min(_totalDurationSeconds, _currentPlaybackPositionSeconds + 5);
      
      _cleanupPlayback();
      _audioDashboardBloc.add(StopRecordingEvent());
      
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _currentPlayingPath != null) {
          _handlePlaybackWithPath(context, _currentPlayingPath!, startAtSeconds: newPosition);
        }
      });
    }
  }

  void _seekToPosition(int seconds) {
    if (_currentPlayingPath != null) {
      _cleanupPlayback();
      
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _currentPlayingPath != null) {
          _handlePlaybackWithPath(context, _currentPlayingPath!, startAtSeconds: seconds);
        }
      });
    }
  }

  // Show dialog to rename server recording
  void _showServerRenameDialog(BuildContext context, Recording recording) {
    final TextEditingController nameController = TextEditingController();
    // Pre-fill with current name without extension
    String nameWithoutExtension = recording.name.split('.').first;
    nameController.text = nameWithoutExtension;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Rename Server Recording'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Enter new name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Appcolors.kprimaryColor,
              ),
              child: const Text('Rename', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                
                if (nameController.text.isEmpty) return;
                
                try {
                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext ctx) {
                      return const Center(child: CircularProgressIndicator());
                    },
                  );
                  
                  // Extract server path from virtual path
                  String serverPath = recording.path;
                  if (recording.path.startsWith('server://')) {
                    serverPath = recording.path.substring('server://'.length);
                  }
                  
                  // Get the new title
                  final String newTitle = nameController.text;
                  
                  // Get authentication token
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('USER_TOKEN');
                  final int? serverRecordingId = recording.serverId; // Get the specific server ID
                  
                  if (token == null) {
                    // Close loading dialog
                    Navigator.of(context).pop();
                    
                    CustomSnackBar.show(
                      context: context,
                      title: 'Error',
                      message: 'Authentication token not found. Please log in again.',
                      contentType: ContentType.failure,
                    );
                    return;
                  }

                  if (serverRecordingId == null) {
                     // Close loading dialog
                    Navigator.of(context).pop();
                    
                    CustomSnackBar.show(
                      context: context,
                      title: 'Error',
                      message: 'Recording ID not found. Cannot rename.',
                      contentType: ContentType.failure,
                    );
                    return;
                  }
                  
                  // Make API request to rename the recording
                  final dio = Dio();
                  dio.options.headers = {
                    'Authorization': 'Bearer $token',
                    // 'Content-Type': 'application/x-www-form-urlencoded', // Dio sets this with FormData
                  };
                  
                  // Create FormData for the POST request
                  final formData = FormData.fromMap({
                    'id': serverRecordingId.toString(), // Use the correct server ID
                    'title': newTitle,
                  });
                  
                  print("Renaming server recording: id=$serverRecordingId, newTitle=$newTitle");
                  
                  final response = await dio.post(
                    'https://vacha.langlex.com/Api/ApiController/updateTitleAudioRecording',
                    data: formData,
                  );
                  
                  // Close loading dialog
                  Navigator.of(context).pop();
                  
                  if (response.statusCode == 200) {
                    final responseData = response.data;
                    
                    if (responseData is Map && responseData['error'] == false) {
                      // Create a new recording object with the updated name
                      final Recording updatedRecording = Recording(
                        path: recording.path,
                        name: newTitle,
                        date: recording.date,
                        duration: recording.duration,
                        serverSaved: recording.serverSaved,
                      );
                      
                      // Update the cached recordings list
                      setState(() {
                        _cachedRecordings.removeWhere((r) => r.path == recording.path);
                        _cachedRecordings.add(updatedRecording);
                        _cachedRecordings.sort((a, b) => b.date.compareTo(a.date));
                      });
                      
                      // Show success message
                      CustomSnackBar.show(
                        context: context,
                        title: 'Renamed',
                        message: responseData['message'] ?? 'Server recording has been renamed',
                        contentType: ContentType.success,
                      );
                      
                      // Refresh recordings
                      _audioDashboardBloc.add(const LoadServerRecordingsEvent());
                    } else {
                      // Show error message
                      CustomSnackBar.show(
                        context: context,
                        title: 'Error',
                        message: responseData['message'] ?? 'Failed to rename server recording',
                        contentType: ContentType.failure,
                      );
                    }
                  } else {
                    // Show error message
                    CustomSnackBar.show(
                      context: context,
                      title: 'Error',
                      message: 'Failed to rename server recording. Server returned: ${response.statusCode}',
                      contentType: ContentType.failure,
                    );
                  }
                } catch (e) {
                  // Close loading dialog if open
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                  
                  print("Error renaming server file: $e");
                  CustomSnackBar.show(
                    context: context,
                    title: 'Error',
                    message: 'Failed to rename server recording: ${e.toString()}',
                    contentType: ContentType.failure,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Share server recording
  void _shareServerRecording(BuildContext context, Recording recording) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) {
          return const Center(child: CircularProgressIndicator());
        },
      );
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('USER_TOKEN');
      final int? serverRecordingId = recording.serverId;

      if (token == null) {
        if (context.mounted) Navigator.pop(context); // Close loading dialog
        if (context.mounted) {
          CustomSnackBar.show(
            context: context, title: 'Error', 
            message: 'Authentication required.', contentType: ContentType.failure);
        }
        return;
      }

      if (serverRecordingId == null) {
        if (context.mounted) Navigator.pop(context); // Close loading dialog
        if (context.mounted) {
          CustomSnackBar.show(
            context: context, title: 'Error', 
            message: 'Recording ID not found.', contentType: ContentType.failure);
        }
        return;
      }

      final dio = Dio();
      dio.options.headers = {
        'Authorization': 'Bearer $token',
      };

      final response = await dio.post(
        'https://vacha.langlex.com/Api/ApiController/getAudioRecordingFilePath',
        data: FormData.fromMap({'id': serverRecordingId.toString()}),
      );

      if (context.mounted) Navigator.pop(context); // Close initial loading

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map && responseData['error'] == false && responseData['data'] != null) {
          final String relativeFilePath = responseData['data']['file_path'];
          final String userFullName = responseData['data']['user_full_name'] ?? 'Unknown User';
          final String fullAudioUrl = 'https://vacha.langlex.com/$relativeFilePath';

          print('Share details: URL: $fullAudioUrl, User: $userFullName');

          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext ctx) {
                return const Center(child: Text('Downloading audio...'));
              },
            );
          }

          final http.Response downloadResponse = await http.get(Uri.parse(fullAudioUrl));
          final Directory tempDir = await getTemporaryDirectory();
          final String fileName = relativeFilePath.split('/').last;
          final File tempFile = File('${tempDir.path}/$fileName');
          await tempFile.writeAsBytes(downloadResponse.bodyBytes);

          if (context.mounted) Navigator.pop(context); // Close downloading dialog

          final String shareMessage = 'Check out this recording from $userFullName: This recording belongs to you! Also, you can download this application from the app store and Play Store. This is a amazing application for Speech Recording Management!';
          final String shareSubject = 'Audio Recording: ${recording.name}';

          // Share the file
          await Share.shareXFiles(
            [XFile(tempFile.path)], 
            text: shareMessage,
            subject: shareSubject,
          );

          // After sharing, copy text to clipboard and notify user
          // await Clipboard.setData(ClipboardData(text: shareMessage));
          // if (context.mounted) {
          //   CustomSnackBar.show(
          //     context: context,
          //     title: 'Text Copied!',
          //     message: 'Message copied to clipboard. You can paste it in your chat.',
          //     contentType: ContentType.success,
          //   );
          // }

        } else {
          if (context.mounted) {
            CustomSnackBar.show(
              context: context, title: 'Error', 
              message: responseData['message'] ?? 'Could not get recording details.', 
              contentType: ContentType.failure);
          }
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.show(
            context: context, title: 'API Error', 
            message: 'Failed to get recording details: ${response.statusCode}',
            contentType: ContentType.failure);
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); 
      if (context.mounted) {
        CustomSnackBar.show(
          context: context, title: 'Error', 
          message: 'Failed to share recording: ${e.toString()}',
          contentType: ContentType.failure);
      }
      print('Error sharing server recording: $e');
    }
  }

  // Share local recording
  void _shareLocalRecording(BuildContext context, Recording recording) async {
    try {
      final File file = File(recording.path);
      if (!await file.exists()) {
        if (context.mounted) {
          CustomSnackBar.show(
              context: context,
              title: 'Error',
              message: 'Recording file not found.',
              contentType: ContentType.failure);
        }
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final userFullName = prefs.getString('USER_NAME') ?? 'A User';

      final String shareMessage = 'Check out this recording from $userFullName: This recording belongs to you! Also, you can download this application from the app store and Play Store. This is a amazing application for Speech Recording Management!';
      final String shareSubject = 'Audio Recording: ${recording.name}';
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareMessage,
        subject: shareSubject,
      );

    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
            context: context,
            title: 'Error',
            message: 'Failed to share recording: ${e.toString()}',
            contentType: ContentType.failure);
      }
      print('Error sharing local recording: $e');
    }
  }

  // Show server recording delete confirmation
  void _showServerDeleteConfirmation(BuildContext context, Recording recording) {
    debugPrint('Opening delete confirmation for recording: ${recording.name}, ID: ${recording.serverId}');
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.delete_outline, color: Appcolors.kredColor),
              SizedBox(width: 8),
              Text('Delete Server Recording'),
            ],
          ),
          content: Text('Are you sure you want to delete "${recording.name}" from the server?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                debugPrint('Delete cancelled');
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Appcolors.kredColor,
              ),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
              onPressed: () {
                debugPrint('Delete confirmed for recording ID: ${recording.serverId}');
                Navigator.of(dialogContext).pop();
                
                // If deleting currently playing recording, stop playback first
                if (_currentPlayingPath == recording.path) {
                  debugPrint('Stopping playback before deletion');
                  _audioDashboardBloc.add(StopRecordingEvent());
                  _cleanupPlayback(force: true);
                }
                
                // Delete the server recording
                _deleteServerRecording(context, recording);
              },
            ),
          ],
        );
      },
    );
  }
  
  // Delete server recording using API
  void _deleteServerRecording(BuildContext context, Recording recording) async {
    try {
      debugPrint('Starting deletion process for recording: ${recording.name}');
      debugPrint('Recording details - Path: ${recording.path}, ID: ${recording.serverId}, ServerSaved: ${recording.serverSaved}');
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) {
          return const Center(child: CircularProgressIndicator());
        },
      );
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('USER_TOKEN');
      final int? recordingId = recording.serverId;
      
      debugPrint('Auth Token available: ${token != null}');
      debugPrint('Recording ID from object: $recordingId');
      
      if (token == null) {
        debugPrint('Error: No auth token found');
        if (context.mounted) Navigator.pop(context);
        if (context.mounted) {
          CustomSnackBar.show(
            context: context,
            title: 'Error',
            message: 'Authentication error. Please login again.',
            contentType: ContentType.failure,
          );
        }
        return;
      }
      
      if (recordingId == null) {
        debugPrint('Error: No recording ID found');
        if (context.mounted) Navigator.pop(context);
        if (context.mounted) {
          CustomSnackBar.show(
            context: context,
            title: 'Error',
            message: 'Error: Could not determine recording ID.',
            contentType: ContentType.failure,
          );
        }
        debugPrint("Error: serverId is null for recording path: ${recording.path}");
        return;
      }

      debugPrint('Preparing to send delete request for ID: $recordingId');

      // Using Dio with form-data
      final dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';
      
      // Create form data exactly as Postman
      final formData = FormData.fromMap({
        'id': recordingId.toString(),
      });
      
      debugPrint('Form data: ${formData.fields}');
      
      debugPrint('Sending DELETE request to server...');
      final response = await dio.post(
        'https://vacha.langlex.com/Api/ApiController/deleteAudioRecording',
        data: formData,
      );
      
      debugPrint('Server Response Status: ${response.statusCode}');
      debugPrint('Server Response Data: ${response.data}');
      
      if (context.mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        final responseData = response.data;
        debugPrint('Processing response data: $responseData');
        
        if (responseData['error'] == false) {
          debugPrint('Delete successful, updating UI');
          if (context.mounted) {
            CustomSnackBar.show(
              context: context,
              title: "Recording Deleted",
              message: responseData['message'] ?? 'Recording deleted successfully',
              contentType: ContentType.success,
            );
            
            // Remove from cached recordings
            setState(() {
              _cachedRecordings.removeWhere((r) => r.serverId == recordingId);
            });
            
            debugPrint('Triggering server recordings refresh');
            _audioDashboardBloc.add(const LoadServerRecordingsEvent());
            
            if (_currentPlayingPath == recording.path) {
              debugPrint('Cleaning up playback for deleted recording');
              _cleanupPlayback(force: true);
            }
          }
        } else {
          if (context.mounted) {
            CustomSnackBar.show(
              context: context,
              title: 'Error',
              message: responseData['message'] ?? 'Failed to delete recording',
              contentType: ContentType.failure,
            );
          }
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.show(
            context: context,
            title: 'Error',
            message: 'Server error: ${response.statusCode}',
            contentType: ContentType.failure,
          );
        }
      }
    } catch (e) {
      debugPrint('Error in deletion: $e');
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        CustomSnackBar.show(
          context: context,
          title: 'Error',
          message: 'Failed to delete recording: $e',
          contentType: ContentType.failure,
        );
      }
    }
  }

  Future<void> _initAudioStuffIfPermissionsGranted() async {
    PermissionStatus micStatus = await Permission.microphone.status; // CHECKS STATUS!
    PermissionStatus storageStatus = await Permission.storage.status; // CHECKS STATUS!

    if (micStatus.isGranted && storageStatus.isGranted) {
      // Setup microphone and storage-dependent features
      print("RecordingPage: Permissions are granted. Initializing audio features.");
      // ... proceed with your audio recorder initialization ...
    } else {
      print("RecordingPage: Permissions are NOT granted. Audio features will be disabled.");
      // Optionally: Show a placeholder UI or message within RecordingPage
      if (mounted) {
          setState(() {
              // e.g., set a flag to disable record button
              // _canRecord = false; 
          });
      }
    }
  }

  // Stops playback UI timer and cleans up playback state
  void _cleanupPlayback({bool force = false}) {
    _playerPositionTimer?.cancel();
    
    if (force) {
      setState(() {
        _currentPlayingPath = null;
        _showPlayerWithoutAudio = false;
      });
    }
  }

  // Starts and maintains a UI timer for playback tracking
  void _startPlaybackTracking(int startPositionSeconds, int durationSeconds) {
    // Cancel any existing timer
    _playerPositionTimer?.cancel();
    
    // Set initial position
    _currentPlaybackPositionSeconds = startPositionSeconds;
    _totalDurationSeconds = durationSeconds;
    
    // Start a timer to update the UI
    _playerPositionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Only increment if not at the end
          if (_currentPlaybackPositionSeconds < _totalDurationSeconds) {
            _currentPlaybackPositionSeconds++;
          } else {
            // At the end, stop the timer
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _renameServerRecording(BuildContext context, Recording recording, String newTitle) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) {
          return const Center(child: CircularProgressIndicator());
        },
      );
      
      // Get authentication token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('USER_TOKEN');
      final int? serverRecordingId = recording.serverId;
      
      if (token == null) {
        if (context.mounted) Navigator.pop(context);
        if (context.mounted) {
          CustomSnackBar.show(
            context: context,
            title: 'Error',
            message: 'Authentication token not found. Please log in again.',
            contentType: ContentType.failure,
          );
        }
        return;
      }

      if (serverRecordingId == null) {
        if (context.mounted) Navigator.pop(context);
        if (context.mounted) {
          CustomSnackBar.show(
            context: context,
            title: 'Error',
            message: 'Recording ID not found. Cannot rename.',
            contentType: ContentType.failure,
          );
        }
        return;
      }

      // Make API request to rename the recording
      final response = await http.post(
        Uri.parse('https://vacha.langlex.com/Api/ApiController/updateTitleAudioRecording'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': token,
        },
        body: {
          'id': serverRecordingId.toString(),
          'title': newTitle,
        },
      );

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['error'] == false) {
          // Create a new recording object with the updated name
          final Recording updatedRecording = Recording(
            path: recording.path,
            name: newTitle,
            date: recording.date,
            duration: recording.duration,
            serverSaved: recording.serverSaved,
            serverId: serverRecordingId,
          );
          
          // Update the cached recordings list
          setState(() {
            _cachedRecordings.removeWhere((r) => r.path == recording.path);
            _cachedRecordings.add(updatedRecording);
            _cachedRecordings.sort((a, b) => b.date.compareTo(a.date));
          });
          
          // Show success message
          if (context.mounted) {
            CustomSnackBar.show(
              context: context,
              title: 'Renamed',
              message: responseData['message'] ?? 'Server recording has been renamed',
              contentType: ContentType.success,
            );
            
            // Refresh recordings
            _audioDashboardBloc.add(const LoadServerRecordingsEvent());
          }
        } else {
          // Show error message
          if (context.mounted) {
            CustomSnackBar.show(
              context: context,
              title: 'Error',
              message: responseData['message'] ?? 'Failed to rename server recording',
              contentType: ContentType.failure,
            );
          }
        }
      } else {
        // Show error message for non-200 status code
        if (context.mounted) {
          CustomSnackBar.show(
            context: context,
            title: 'Error',
            message: 'Failed to rename recording. Server returned ${response.statusCode}',
            contentType: ContentType.failure,
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still showing
      if (context.mounted) Navigator.pop(context);
      
      print("Error renaming file: $e");
      if (context.mounted) {
        CustomSnackBar.show(
          context: context,
          title: 'Error',
          message: 'Failed to rename recording: $e',
          contentType: ContentType.failure,
        );
      }
    }
  }

  Future<void> _reloadLocalRecordingsAfterRename(Recording updatedRecording, String oldPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_localRecordingsKey);
      List<Recording> recordings = [];
      if (cached != null) {
        final decoded = json.decode(cached) as List;
        recordings = decoded.map((data) => Recording.fromJson(data as Map<String, dynamic>)).toList();
      }
      // Remove old and add updated
      recordings.removeWhere((r) => r.path == oldPath);
      recordings.add(updatedRecording);
      recordings.sort((a, b) => b.date.compareTo(a.date));
      final encodedRecordings = json.encode(recordings.map((r) => r.toJson()).toList());
      await prefs.setString(_localRecordingsKey, encodedRecordings);
      setState(() {
        _cachedRecordings.removeWhere((r) => r.path == oldPath);
        _cachedRecordings.add(updatedRecording);
        _cachedRecordings.sort((a, b) => b.date.compareTo(a.date));
      });
    } catch (e) {
      debugPrint('Error reloading local recordings after rename: $e');
    }
  }

  // This is the big player that shows at the bottom of the screen.
  Widget _buildPlaybackControls(BuildContext context, AudioDashboardState state) {
    if (_currentPlayingPath == null) return const SizedBox.shrink();

    bool isPlaying = state is PlaybackInProgress && state.filePath == _currentPlayingPath;
    bool isPaused = state is PlaybackPaused && state.filePath == _currentPlayingPath;
    
    double currentSpeed = 1.0;
    if (state is PlaybackInProgress) {
       currentSpeed = state.speed;
    } else if (state is PlaybackPaused) {
       currentSpeed = state.speed;
    }

    Duration currentPosition = Duration.zero;
    if(state is PlaybackInProgress) {
      currentPosition = state.position;
    } else if (state is PlaybackPaused) {
      currentPosition = state.position;
    }
    
    final sliderValue = (_totalDurationSeconds > 0)
        ? (currentPosition.inSeconds / _totalDurationSeconds).clamp(0.0, 1.0)
        : 0.0;
    
    final currentTimeStr = _formatDuration(currentPosition);
    final totalTimeStr = _formatDuration(Duration(seconds: _totalDurationSeconds));

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10),
                onPressed: () {
                  _audioDashboardBloc.add(const SeekPlaybackEvent(Duration(seconds: -10), relative: true));
                },
                iconSize: 28,
              ),
              IconButton(
                icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                onPressed: () {
                  if (isPlaying) {
                    _audioDashboardBloc.add(const PausePlaybackEvent());
                  } else {
                    _audioDashboardBloc.add(const ResumePlaybackEvent());
                  }
                },
                iconSize: 48,
                color: Appcolors.kredColor,
              ),
              IconButton(
                icon: const Icon(Icons.forward_10),
                onPressed: () {
                  _audioDashboardBloc.add(const SeekPlaybackEvent(Duration(seconds: 10), relative: true));
                },
                iconSize: 28,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(currentTimeStr),
              Expanded(
                child: Slider(
                  value: sliderValue,
                  onChanged: (value) {
                     // This is just for visual feedback while dragging
                     setState(() {
                       _currentPlaybackPositionSeconds = (value * _totalDurationSeconds).round();
                     });
                  },
                  onChangeEnd: (value) {
                     final newPosition = Duration(seconds: (value * _totalDurationSeconds).round());
                     _audioDashboardBloc.add(SeekPlaybackEvent(newPosition));
                  },
                ),
              ),
              Text(totalTimeStr),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [0.5, 1.0, 1.5, 2.0].map((speed) {
              final isSelected = (speed - currentSpeed).abs() < 0.01;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TextButton(
                  onPressed: (isPlaying || isPaused) ? () {
                    _audioDashboardBloc.add(SetPlaybackSpeedEvent(speed));
                  } : null,
                  style: TextButton.styleFrom(
                    backgroundColor: isSelected ? Appcolors.kredColor : Colors.grey[200],
                    foregroundColor: isSelected ? Colors.white : Colors.black,
                    disabledBackgroundColor: Colors.grey[300]
                  ),
                  child: Text('${speed}x'),
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  // String _formatDuration(Duration d) {
  //   final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  //   final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  //   return '$minutes:$seconds';
  // }

  // Refactored Skip Button
  Widget _buildSkipButton(bool forward) {
    return BlocBuilder<AudioDashboardBloc, AudioDashboardState>(
      builder: (context, state) {
        final bool isPlayingOrPaused = (state is PlaybackInProgress && state.filePath == _currentPlayingPath) ||
                                       (state is PlaybackPaused && state.filePath == _currentPlayingPath);

        return InkWell(
          onTap: isPlayingOrPaused
              ? () {
                  print("Skip button tapped (forward: $forward).");
                  // Send seek event directly to BLoC
                  _audioDashboardBloc.add(SeekPlaybackEvent(
                    Duration(seconds: forward ? 10 : -10),
                    relative: true,
                  ));
                }
              : null,
          child: Opacity(
            opacity: isPlayingOrPaused ? 1.0 : 0.4,
            child: Icon(
              forward ? Icons.forward_10_rounded : Icons.replay_10_rounded,
              color: Colors.black,
              size: 32,
            ),
          ),
        );
      },
    );
  }

  String _getFileNameFromUrl(String url) {
    try {
      return Uri.decodeComponent(Uri.parse(url).pathSegments.last);
    } catch (e) {
      return url; // fallback to the original url if parsing fails
    }
  }
  
  Widget _buildServerRecordingListItem(Recording recording, bool isCurrentlyPlaying, bool isPlaying) {
    String duration = _formatDuration(Duration(seconds: recording.duration));
    String date = _formatDate(recording.date);
    String title = recording.name.endsWith('.wav') || recording.name.endsWith('.mp4')
        ? recording.name.substring(0, recording.name.length - 4)
        : recording.name;
    // ... existing code ...
    // ...
    return Container();
  }

  // This function is being removed as it's a duplicate and the other one is better.

  // void _showDeleteConfirmation(BuildContext context, Recording recording) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext dialogContext) {
  //       return AlertDialog(
  //         title: const Text("Confirm Deletion"),
  //         content: Text("Are you sure you want to delete '${recording.name}'? This action cannot be undone."),
  //         actions: <Widget>[
  //           TextButton(
  //             child: const Text("Cancel"),
  //             onPressed: () {
  //               Navigator.of(dialogContext).pop();
  //             },
  //           ),
  //           TextButton(
  //             child: const Text("Delete", style: TextStyle(color: Colors.red)),
  //             onPressed: () {
  //               if (recording.serverSaved) {
  //                 _audioDashboardBloc.add(DeleteServerRecordingEvent(recording.serverId!));
  //               } else {
  //                 _audioDashboardBloc.add(DeleteRecordingEvent(recording.path));
  //               }
  //               Navigator.of(dialogContext).pop();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // Helper method to find Recording by path
  Recording? _findRecordingByPath(String path) {
    try {
      return _cachedRecordings.firstWhere(
        (rec) => rec.path == path,
        orElse: () {
          final state = _audioDashboardBloc.state;
          if (state is RecordingsLoaded) {
            return state.recordings.firstWhere(
              (rec) => rec.path == path,
              orElse: () => throw Exception('Recording not found'),
            );
          }
          throw Exception('State not loaded');
        },
      );
    } catch (e) {
      print('Error finding recording: $e');
      return null;
    }
  }

  // Helper method to handle playback with path
  void _handlePlaybackWithPath(BuildContext context, String path, {int startAtSeconds = 0}) {
    final recording = _findRecordingByPath(path);
    if (recording != null) {
      _playSavedRecording(context, recording, startAtSeconds: startAtSeconds);
    } else {
      print('Recording not found for path: $path');
    }
  }

  // Navigate to audio editor
  void _navigateToAudioEditor(BuildContext context, Recording recording) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudioEditorPage(recording: recording),
      ),
    );
  }

  // Speed control methods
  void _onSpeedButtonPressed(double speed) {
    if (mounted) {
      setState(() {
        _currentPlaybackSpeed = speed;
      });
      final state = _audioDashboardBloc.state;
      if (state is PlaybackInProgress || state is PlaybackPaused) {
         context.read<AudioDashboardBloc>().add(SetPlaybackSpeedEvent(speed));
      }
    }
  }

  void _onRecordingTapped(Recording recording) {
    print("Tapped non-playing/paused recording (${recording.name}) in list. Requesting PLAY via _handlePlaybackWithPath.");
    _handlePlaybackWithPath(context, recording.path);
  }

  void _onRecordingSelected(Recording recording) {
    _handlePlaybackWithPath(context, recording.path);
  }

  void _handlePlaybackRequest(Recording recording, {int startAtSeconds = 0}) {
    _handlePlaybackWithPath(context, recording.path, startAtSeconds: startAtSeconds);
  }

  // Add method to build speed button
  Widget _buildSpeedButton(String text, double speed, VoidCallback onPressed) {
    final isSelected = _currentPlaybackSpeed == speed;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: isSelected ? Appcolors.kredColor : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Appcolors.kredColor : Colors.grey,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  // Update the speed buttons UI
  Widget _buildSpeedControls() {
    return BlocBuilder<AudioDashboardBloc, AudioDashboardState>(
      buildWhen: (previous, current) {
        if (previous is PlaybackInProgress && current is PlaybackInProgress) {
          return previous.speed != current.speed;
        }
        if (previous is PlaybackPaused && current is PlaybackPaused) {
          return previous.speed != current.speed;
        }
        return previous.runtimeType != current.runtimeType;
      },
      builder: (context, state) {
        bool isPlayingOrPaused = false;
        double currentSpeed = 1.0;
        
        // Update speed from state
        if (state is PlaybackInProgress) {
          currentSpeed = state.speed;
          isPlayingOrPaused = true;
        } else if (state is PlaybackPaused) {
          currentSpeed = state.speed;
          isPlayingOrPaused = true;
        }

        return Opacity(
          opacity: isPlayingOrPaused ? 1.0 : 0.5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [0.5, 1.0, 1.5, 2.0].map((speed) {
              final isSelected = (_currentPlaybackSpeed - speed).abs() < 0.1;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Appcolors.kredColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Appcolors.kredColor : Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: isPlayingOrPaused ? () => _onSpeedButtonPressed(speed) : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Text(
                          '${speed}x',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
} 
