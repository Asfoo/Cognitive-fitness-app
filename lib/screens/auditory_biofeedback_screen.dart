import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'results_screen.dart';
import '../db/database_helper.dart';

class AuditoryBiofeedbackScreen extends StatefulWidget {
  @override
  _AuditoryBiofeedbackScreenState createState() => _AuditoryBiofeedbackScreenState();
}

class _AuditoryBiofeedbackScreenState extends State<AuditoryBiofeedbackScreen> {
  bool _isStarted = false;
  int _mathStartTime = 0;
  int _num1 = 0;
  int _num2 = 0;
  int _correctAnswer = 0;
  TextEditingController _answerController = TextEditingController();
  late AudioPlayer _player;
  String? _beepType;
  int? _beepStartTime;
  Timer? _beepTimer;
  List<double> _responseTimes = [];
  int _errors = 0;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
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

    // Beep every 3-5 seconds
    _beepTimer = Timer.periodic(Duration(seconds: 3 + random.nextInt(3)), (_) async {
      if (_beepType != null) {
        _errors++;
        _attempts++;
        _checkAutoSubmit();
      }
      if (_attempts >= 3) return;
      _beepType = random.nextBool() ? 'high' : 'low';
      _beepStartTime = DateTime.now().millisecondsSinceEpoch;
      await _player.play(AssetSource('beep_$_beepType.mp3'));
    });
  }

  void _onLeftTap() {
    if (_beepType != null) {
      _attempts++;
      if (_beepType == 'high') {
        double response = (DateTime.now().second - _beepStartTime!) / 1000.0;
        _responseTimes.add(response);
      } else {
        _errors++;
      }
      _beepType = null;
      _checkAutoSubmit();
    }
  }

  void _onRightTap() {
    if (_beepType != null) {
      _attempts++;
      if (_beepType == 'low') {
        double response = (DateTime.now().second - _beepStartTime!) / 1000.0;
        _responseTimes.add(response);
      } else {
        _errors++;
      }
      _beepType = null;
      _checkAutoSubmit();
    }
  }

  void _checkAutoSubmit() {
    if (_attempts >= 3) {
      _onSubmit();
    }
  }

  void _onSubmit() {
    _beepTimer?.cancel();
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
      'test_type': 'AuditoryBio',
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
          testType: 'AuditoryBio',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _beepTimer?.cancel();
    _player.dispose();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Auditory Biofeedback Test', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[700],
         centerTitle: true,
        foregroundColor: Colors.white,
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
                        _isStarted ? 'Solve Math & Respond to Beeps' : 'Start the Test',
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
                          'Tap Left for High Pitch, Right for Low Pitch',
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: _onLeftTap,
                                child: Container(
                                  height: 100,
                                  color: Colors.blue[200],
                                  child: Center(child: Text('Left (High)', style: GoogleFonts.poppins())),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: _onRightTap,
                                child: Container(
                                  height: 100,
                                  color: Colors.blue[400],
                                  child: Center(child: Text('Right (Low)', style: GoogleFonts.poppins())),
                                ),
                              ),
                            ),
                          ],
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