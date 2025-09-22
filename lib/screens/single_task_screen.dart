import 'package:cognitive_fitness_app/widgets/appbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'results_screen.dart';
import '../db/database_helper.dart';

class SingleTaskScreen extends StatefulWidget {
  @override
  _SingleTaskScreenState createState() => _SingleTaskScreenState();
}

class _SingleTaskScreenState extends State<SingleTaskScreen> with SingleTickerProviderStateMixin {
  bool _isStarted = false;
  bool _isSignalShown = false;
  int _reactionTime = 0;
  int _startTime = 0;
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
      DatabaseHelper.instance.insertResult({
        'test_type': 'Single',
        'reaction_time': _reactionTime,
        'math_answer': null,
        'correct_answer': null,
        'eeg': null,
        'ecg': null,
        'emg': null,
        'eye_tracking': null,
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultsScreen(
            reactionTime: _reactionTime,
            sensorData: {},
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppbar(title: 'Single Task'),
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
                padding: EdgeInsets.all(50),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isStarted ? 'Wait for the Signal' : 'Start the Test',
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.blue[900]),
                    ),
                    SizedBox(height: 20),
                    if (!_isStarted)
                      ElevatedButton(
                        onPressed: _startTest,
                        child: Text('Start Test'),
                      ),
                    if (_isStarted && !_isSignalShown)
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}