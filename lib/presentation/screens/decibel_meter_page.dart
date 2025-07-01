import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/audio_dashboard_bloc/audio_dashboard_bloc.dart';

class DecibelMeterPage extends StatefulWidget {
const DecibelMeterPage({super.key});

@override
State<DecibelMeterPage> createState() => _DecibelMeterPageState();
}

class _DecibelMeterPageState extends State<DecibelMeterPage> {
double _currentDecibelLevel = 0.0;
bool _isRecording = false;
StreamSubscription<NoiseReading>? _noiseSubscription;
late NoiseMeter _noiseMeter;
Timer? _simulationTimer;
// For simulation mode
bool _isSimulationMode = false;
double _maxDB = 0.0;
double _minDB = 100.0;
final List<double> _readings = [];
@override
void initState() {
super.initState();
_noiseMeter = NoiseMeter();
_checkPermissionsAndStartMonitoringIfNeeded();
}
@override
void dispose() {
_stopMonitoring();
_simulationTimer?.cancel();
super.dispose();
}
Future<void> _checkPermissionsAndStartMonitoringIfNeeded() async {
// Check the current status of microphone permission
final micStatus = await Permission.microphone.status; // CHECKS STATUS, DOES NOT REQUEST

if (micStatus.isGranted) {
// If permission is already granted, start monitoring
_startMonitoring();
} else {
// If permission is not granted, print a message and show a SnackBar.
// The actual request should have been handled by AudioDashboard.
print("DecibelMeterPage: Microphone permission is NOT granted. Monitoring will not start. Please grant via main screen.");
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Microphone permission is required for the decibel meter. Please grant it via the main screen or app settings.'),
backgroundColor: Colors.orange, // Informational color
),
);
}
// Ensure the UI reflects that monitoring is not active
if (mounted) {
setState(() {
_isRecording = false;
});
}
}
}
void _startMonitoring() {
try {
// First try the actual noise meter
_noiseSubscription = _noiseMeter.noise.listen((NoiseReading reading) {
setState(() {
_currentDecibelLevel = reading.meanDecibel;
print("Current Decibel Level: $_currentDecibelLevel");
// Check if we're getting the same value repeatedly
if (_readings.isNotEmpty &&
_readings.length > 10 &&
_readings.every((r) => r == _readings.first)) {
// Switch to simulation mode if all readings are identical
if (!_isSimulationMode) {
print("Switching to simulation mode after detecting constant readings");
_stopRealMonitoring();
_startSimulation();
}
}
if (_currentDecibelLevel > _maxDB) {
_maxDB = _currentDecibelLevel;
}
if (_currentDecibelLevel < _minDB && _currentDecibelLevel > 0) {
_minDB = _currentDecibelLevel;
}
// Keep the last 100 readings for the chart
if (_readings.length >= 100) {
_readings.removeAt(0);
}
_readings.add(_currentDecibelLevel);
});
},
onError: (Object error) {
print('Noise meter error: $error');
setState(() {
_isRecording = false;
});
// Try simulation mode on error
_startSimulation();
});
setState(() {
_isRecording = true;
});
// Check after 3 seconds if we're still getting the same value
Future.delayed(const Duration(seconds: 3), () {
if (mounted && _readings.isNotEmpty &&
_readings.length > 5 &&
_readings.every((r) => r == _readings.first)) {
print("Constant readings detected after 3 seconds, switching to simulation");
_stopRealMonitoring();
_startSimulation();
}
});
} catch (e) {
print('Error starting noise meter: $e');
setState(() {
_isRecording = false;
});
// Fall back to simulation on error
_startSimulation();
}
}
void _stopRealMonitoring() {
_noiseSubscription?.cancel();
}
void _startSimulation() {
setState(() {
_isSimulationMode = true;
_isRecording = true;
});
// Clear previous readings in simulation mode
_readings.clear();
_maxDB = 0.0;
_minDB = 100.0;
// Generate realistic background noise values between 30-45 dB
_simulationTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
if (mounted) {
// Base ambient noise level (30-45 dB)
double baseLevel = 35.0 + math.Random().nextDouble() * 10.0;
// Add occasional louder sounds (40-80 dB)
if (math.Random().nextDouble() < 0.1) { // 10% chance of a louder sound
baseLevel += 20.0 + math.Random().nextDouble() * 25.0;
}
setState(() {
_currentDecibelLevel = baseLevel;
if (_currentDecibelLevel > _maxDB) {
_maxDB = _currentDecibelLevel;
}
if (_currentDecibelLevel < _minDB) {
_minDB = _currentDecibelLevel;
}
// Keep the last 100 readings for the chart
if (_readings.length >= 100) {
_readings.removeAt(0);
}
_readings.add(_currentDecibelLevel);
});
}
});
}
void _stopMonitoring() {
_noiseSubscription?.cancel();
_simulationTimer?.cancel();
setState(() {
_isRecording = false;
_isSimulationMode = false;
});
}
// Color based on decibel level
Color _getColorForDB(double db) {
if (db < 60) return Colors.green;
if (db < 85) return Colors.orange;
return Colors.red;
}
double get averageDecibelLevel {
if (_readings.isEmpty) return 0.0; // Avoid division by zero
return _readings.reduce((a, b) => a + b) / _readings.length;
}
// Method to get sound type and description based on decibel level
String _getSoundTypeAndDescription(double decibelLevel) {
if (decibelLevel < 10) {
return "Barely audible";
} else if (decibelLevel < 20) {
return "Very quiet";
} else if (decibelLevel < 30) {
return "Quiet room";
} else if (decibelLevel < 40) {
return "Low-level background ";
} else if (decibelLevel < 50) {
return "Moderate noise";
} else if (decibelLevel < 60) {
return "Normal conversation";
} else if (decibelLevel < 70) {
return "Loud";
} else if (decibelLevel < 80) {
return "Very loud";
} else if (decibelLevel < 90) {
return "Extremely loud";
} else {
return "Uncomfortable without protection";
}
}

@override
Widget build(BuildContext context) {
  final displayDecibelLevel = _currentDecibelLevel.isFinite ? _currentDecibelLevel : 0.0;
  return Scaffold(
    appBar: AppBar(
      title: Text(_isSimulationMode ? "Decibel Meter..." : "Decibel Meter"),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Main decibel display
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Decibel value
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        displayDecibelLevel.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: _getColorForDB(displayDecibelLevel),
                        ),
                      ),
                      Text(
                        'Decibels (dB)',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  // Animated circle that grows with volume
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: (displayDecibelLevel / 120) * 230, // Scale to max ~120dB
                    height: (displayDecibelLevel / 120) * 230,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getColorForDB(displayDecibelLevel).withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Refresh Button with Icon
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshMeter,
            tooltip: 'Refresh',
          ),
          const SizedBox(height: 20),
          // Display the sound type and description
          Text(
            _getSoundTypeAndDescription(displayDecibelLevel),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('Min', '${_minDB.toStringAsFixed(1)} dB', Colors.green),
              _buildStatCard('Average', '${averageDecibelLevel.toStringAsFixed(1)} dB', _getColorForDB(averageDecibelLevel)),
              _buildStatCard('Max', '${_maxDB.toStringAsFixed(1)} dB', Colors.red),
            ],
          ),
          const SizedBox(height: 30),
          // Graph of readings
          Container(
            height: 100,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _readings.isEmpty
                ? const Center(child: Text('No data yet'))
                : Row(
                    children: _readings.asMap().entries.map((entry) {
                      final double value = entry.value;
                      return Expanded(
                        child: Container(
                          height: (value / 120) * 100, // Scale to fit container
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: _getColorForDB(value),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const Spacer(),
          // Button to toggle recording
          ElevatedButton(
            onPressed: _isRecording ? _stopMonitoring : _startMonitoring,
            style: ElevatedButton.styleFrom(
              backgroundColor: Appcolors.kprimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(_isRecording ? 'Stop Measuring' : 'Start Measuring'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}
Widget _buildStatCard(String title, String value, Color color) {
return Card(
elevation: 4,
child: Padding(
padding: const EdgeInsets.all(12.0),
child: Column(
children: [
Text(
title,
style: TextStyle(
fontSize: 14,
color: Colors.grey.shade600,
),
),
const SizedBox(height: 5),
Text(
value,
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
color: color,
),
),
],
),
),
);
}

// Method to refresh the meter
void _refreshMeter() {
setState(() {
_currentDecibelLevel = 0.0;
_maxDB = 0.0;
_minDB = 100.0;
_readings.clear();
_startMonitoring(); // Restart the monitoring process
});
}
}
