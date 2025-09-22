import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math';
import 'results_screen.dart';
import '../db/database_helper.dart';

class TappingBiofeedbackScreen extends StatefulWidget {
  @override
  _TappingBiofeedbackScreenState createState() => _TappingBiofeedbackScreenState();
}

class _TappingBiofeedbackScreenState extends State<TappingBiofeedbackScreen> {
  bool _isStarted = false;
  int _mathStartTime = 0;
  int _num1 = 0;
  int _num2 = 0;
  int _correctAnswer = 0;
  TextEditingController _answerController = TextEditingController();
  int _requiredTaps = 0;
  int _currentTaps = 0;
  List<int> _tapTimes = [];
  double _buttonLeft = 0.0;
  double _buttonTop = 0.0;

  @override
  void initState() {
    super.initState();
  }

  void _startTest() {
    final random = Random();
    _num1 = random.nextInt(50) + 1;
    _num2 = random.nextInt(20) + 1;
    _correctAnswer = _num1 + _num2;
    _mathStartTime = DateTime.now().second;
    _requiredTaps = random.nextInt(4) + 1; // 1 to 4
    _currentTaps = 0;
    _tapTimes = [];
    _buttonLeft = random.nextDouble() * 200; // Random left position (adjust based on screen)
    _buttonTop = random.nextDouble() * 300; // Random top position
    setState(() {
      _isStarted = true;
    });
  }

  void _onButtonTap() {
    if (_currentTaps < _requiredTaps) {
      _tapTimes.add(DateTime.now().second);
      _currentTaps++;
      // if (_currentTaps == _requiredTaps) {
      //   _onSubmit();
      // }
    }
  }

  void _onSubmit() {
    int mathTime = DateTime.now().second - _mathStartTime;
    double sum = 0.0;
    double sumSq = 0.0;
    List<double> intervals = [];
    for (int i = 1; i < _tapTimes.length; i++) {
      double interval = (_tapTimes[i] - _tapTimes[i - 1]) / 1000.0;
      intervals.add(interval);
      sum += interval;
      sumSq += interval * interval;
    }
    int n = intervals.length;
    double mean = n > 0 ? sum / n : 0.0;
    double variance = n > 0 ? (sumSq - sum * sum / n) / n : 0.0;
    double sd = sqrt(variance);
    final bioData = {
      'MathAnswer': int.tryParse(_answerController.text) ?? 0,
      'CorrectAnswer': _correctAnswer,
      'EEG': mean.toStringAsFixed(2), // Avg tap interval (sec)
      'ECG': mathTime.toString(),     // Math solving time (ms)
      'EMG': sd.toStringAsFixed(2),   // Tap interval SD (sec)
      'EyeTracking': '0',             // No errors in this task
    };
    final insertData = {
      'test_type': 'TappingBio',
      'reaction_time': mathTime,
      'math_answer': bioData['MathAnswer'],
      'correct_answer': _correctAnswer,
      'eeg': mean,
      'ecg': mathTime,
      'emg': sd,
      'eye_tracking': 0,
    };
    DatabaseHelper.instance.insertResult(insertData);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          reactionTime: mathTime,
          sensorData: bioData,
          testType: 'TappingBio',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text('Tapping Biofeedback Test', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.blue[100]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isStarted ? 'Solve Math & Tap Button' : 'Start the Test',
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.blue[900]),
                      ),
                      SizedBox(height: 20),
                      if (!_isStarted)
                        ElevatedButton(
                          onPressed: _startTest,
                          child: Text('Start Test'),
                        ),
                      if (_isStarted) ...[
                        Text(
                          'Solve: $_num1 + $_num2 = ?',
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _answerController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.blue[50],
                              hintText: 'Answer',
                              hintStyle: GoogleFonts.poppins(color: Colors.blue[300]),
                            ),
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Tap the button $_requiredTaps times',
                          style: GoogleFonts.poppins(fontSize: 16, color: Colors.blue[900]),
                        ),
                        SizedBox(height: 20),
                        Container(
                          height: 400, // Space for random position
                          child: Stack(
                            children: [
                              Positioned(
                                left: _buttonLeft,
                                top: _buttonTop,
                                child: ElevatedButton(
                                  onPressed: _onButtonTap,
                                  style: ElevatedButton.styleFrom(
                                    shape: CircleBorder(),
                                    padding: EdgeInsets.all(24),
                                  ),
                                  child: Text('Tap', style: GoogleFonts.poppins()),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _onSubmit,
                          child: Text('Submit Answer'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}