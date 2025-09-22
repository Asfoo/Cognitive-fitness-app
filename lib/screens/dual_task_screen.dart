import 'package:cognitive_fitness_app/widgets/appbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math';
import 'results_screen.dart';
import '../db/database_helper.dart';

class DualTaskScreen extends StatefulWidget {
  @override
  _DualTaskScreenState createState() => _DualTaskScreenState();
}

class _DualTaskScreenState extends State<DualTaskScreen> with SingleTickerProviderStateMixin {
  bool _isStarted = false;
  bool _isSignalShown = false;
  int _reactionTime = 0;
  int _startTime = 0;
  int _num1 = 0;
  int _num2 = 0;
  int _correctAnswer = 0;
  TextEditingController _answerController = TextEditingController();
  Timer? _timer;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
  }

  void _startTest() {
    final random = Random();
    _num1 = random.nextInt(10) + 1;
    _num2 = random.nextInt(10) + 1;
    _correctAnswer = _num1 + _num2;
    setState(() {
      _isStarted = true;
    });
    _timer = Timer(Duration(seconds: 2 + (DateTime.now().millisecond % 3)), () {
      setState(() {
        _isSignalShown = true;
        _startTime = DateTime.now().second;
        _fadeController.forward();
      });
    });
  }

  void _onTap() {
    if (_isSignalShown) {
      setState(() {
        _reactionTime = DateTime.now().second - _startTime;
        _isSignalShown = false;
      });
      final sensorData = {
        'test_type': 'Dual',
        'reaction_time': _reactionTime,
        'math_answer': int.tryParse(_answerController.text),
        'correct_answer': _correctAnswer,
        'eeg': null,
        'ecg': null,
        'emg': null,
        'eye_tracking': null,
      };
      DatabaseHelper.instance.insertResult(sensorData);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultsScreen(
            reactionTime: _reactionTime,
            sensorData: {'MathAnswer': int.tryParse(_answerController.text) ?? 0, 'CorrectAnswer': _correctAnswer},
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _answerController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppbar(title:  'Dual Task'),
      body: Container(
          height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.blue[100]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
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
                      _isStarted ? 'Solve & Wait for Signal' : 'Start the Test',
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
                      if (!_isSignalShown)
                        CircularProgressIndicator(color: Colors.blue),
                      if (_isSignalShown)
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: GestureDetector(
                            onTap: _onTap,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.blue, Colors.blueAccent],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 4))],
                              ),
                              child: Center(
                                child: Text(
                                  'Tap Now!',
                                  style: GoogleFonts.poppins(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}