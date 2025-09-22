import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math';
import 'results_screen.dart';
import '../db/database_helper.dart';

class VisualBiofeedbackScreen extends StatefulWidget {
  @override
  _VisualBiofeedbackScreenState createState() => _VisualBiofeedbackScreenState();
}

class _VisualBiofeedbackScreenState extends State<VisualBiofeedbackScreen> {
  bool _isStarted = false;
  int _mathStartTime = 0;
  int _num1 = 0;
  int _num2 = 0;
  int _correctAnswer = 0;
  TextEditingController _answerController = TextEditingController();
  Color _visualColor = Colors.grey;
  String? _visualType;
  int? _visualStartTime;
  Timer? _visualTimer;
  bool _visualResponded = false;
  List<double> _responseTimes = [];
  int _errors = 0;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
  }

  void _startTest() {
    final random = Random();
    _num1 = random.nextInt(10) + 1;
    _num2 = random.nextInt(10) + 1;
    _correctAnswer = _num1 + _num2;
    _mathStartTime = DateTime.now().second;
    _responseTimes = [];
    _errors = 0;
    _attempts = 0;
    setState(() {
      _isStarted = true;
    });

    // Visual stimulus every 5-8 seconds, lasts 2 seconds
    _visualTimer = Timer.periodic(Duration(seconds: 5 + random.nextInt(4)), (_) {
      if (_attempts >= 3) return;
      if (_visualType == 'go' && !_visualResponded) {
        _errors++;
      }
      _attempts++; // Count each color appearance as an attempt
      _checkAutoSubmit();
      _visualResponded = false;
      _visualType = random.nextBool() ? 'go' : 'no-go';
      setState(() {
        _visualColor = _visualType == 'go' ? Colors.green : Colors.red;
      });
      _visualStartTime = DateTime.now().second;
      Timer(Duration(seconds: 2), () {
        setState(() {
          _visualColor = Colors.grey;
        });
      });
    });
  }

  void _onVisualTap() {
    if (_visualColor != Colors.grey) {
      if (_visualType == 'go') {
        double response = (DateTime.now().second - _visualStartTime!) / 1000.0;
        _responseTimes.add(response);
        _visualResponded = true;
      } else {
        _errors++;
      }
      setState(() {
        _visualColor = Colors.grey;
      });
    }
  }

  void _checkAutoSubmit() {
    if (_attempts >= 3) {
      _onSubmit();
    }
  }

  void _onSubmit() {
    _visualTimer?.cancel();
    int mathTime = DateTime.now().second - _mathStartTime;
    double sum = 0.0;
    double sumSq = 0.0;
    for (var r in _responseTimes) {
      sum += r;
      sumSq += r * r;
    }
    int n = _responseTimes.length;
    double mean = n > 0 ? sum / n : 0.0;
    double variance = n > 0 ? (sumSq - sum * sum / n) / n : 0.0;
    double sd = sqrt(variance);
    final bioData = {
      'MathAnswer': int.tryParse(_answerController.text) ?? 0,
      'CorrectAnswer': _correctAnswer,
      'EEG': mean.toStringAsFixed(2),
      'ECG': mathTime.toString(),
      'EMG': sd.toStringAsFixed(2),
      'EyeTracking': _errors.toString(),
    };
    final insertData = {
      'test_type': 'VisualBio',
      'reaction_time': mathTime,
      'math_answer': bioData['MathAnswer'],
      'correct_answer': _correctAnswer,
      'eeg': mean,
      'ecg': mathTime,
      'emg': sd,
      'eye_tracking': _errors,
    };
    DatabaseHelper.instance.insertResult(insertData);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          reactionTime: mathTime,
          sensorData: bioData,
          testType: 'VisualBio',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _visualTimer?.cancel();
    _answerController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Visual Biofeedback Test', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
                        _isStarted ? 'Solve Math & Respond to Colors' : 'Start the Test',
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
                          'Tap if Green, Ignore if Red',
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                        GestureDetector(
                          onTap: _onVisualTap,
                          child: Container(
                            height: 100,
                            width: double.infinity,
                            color: _visualColor,
                            child: Center(child: Text('Visual Area', style: GoogleFonts.poppins(color: Colors.white))),
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Attempts: $_attempts/3',
                          style: GoogleFonts.poppins(fontSize: 16, color: Colors.blue[900]),
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