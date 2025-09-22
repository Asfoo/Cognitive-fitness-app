import 'dart:math';

class SensorData {
  static Map<String, dynamic> generateDummyData() {
    final random = Random();
    return {
      'EEG': (random.nextDouble() * 50 + 50).toStringAsFixed(2), // 50-100 range for brain activity
      'ECG': (60 + random.nextInt(21)).toString(),              // 60-80 bpm for heart rate
      'EMG': (random.nextDouble() * 30).toStringAsFixed(2),     // 0-30 range for muscle tension
      'EyeTracking': random.nextInt(101).toString(),            // 0-100 for attention level
    };
  }
}