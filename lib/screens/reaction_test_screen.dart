import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class ReactionTestScreen extends StatefulWidget {
  const ReactionTestScreen({super.key});

  @override
  State<ReactionTestScreen> createState() => _ReactionTestScreenState();
}

class _ReactionTestScreenState extends State<ReactionTestScreen> {
  bool isStimulusShown = false;
  List<double> reactionTimes = [];
  final Stopwatch stopwatch = Stopwatch();
  int trialCount = 0;
  static const int totalTrials = 5; // Number of trials in the test
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    startTrial();
  }

  void startTrial() {
    if (trialCount >= totalTrials) {
      endTest();
      return;
    }
    // Schedule stimulus after a random delay between 1-4 seconds
    Future.delayed(Duration(seconds: 1 + random.nextInt(4)), () {
      if (mounted) {
        setState(() {
          isStimulusShown = true;
          stopwatch.start();
        });
      }
    });
  }

  void handleTap() {
    if (isStimulusShown) {
      stopwatch.stop();
      final reactionTime = stopwatch.elapsedMilliseconds / 1000.0; // Seconds
      reactionTimes.add(reactionTime);
      stopwatch.reset();
      setState(() {
        isStimulusShown = false;
        trialCount++;
      });
      startTrial();
    }
    // Ignore taps when stimulus isn't shown to prevent false starts
  }

  void endTest() {
    Navigator.pushNamed(
      context,
      '/results',
      arguments: {'reactionTimes': reactionTimes},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: handleTap,
        child: Container(
          color: isStimulusShown ? Colors.red : Colors.white,
          child: Center(
            child: Text(
              isStimulusShown ? 'Tap Now!' : 'Wait for Stimulus...',
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    stopwatch.stop();
    super.dispose();
  }
}