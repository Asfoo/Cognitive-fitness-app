import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'single_task_screen.dart';
import 'dual_task_screen.dart';
import 'auditory_biofeedback_screen.dart';
import 'visual_biofeedback_screen.dart';
import 'tapping_biofeedback_screen.dart';
import 'home_screen.dart';

class ResultsScreen extends StatelessWidget {
  final int reactionTime;
  final Map<String, dynamic> sensorData;
  final String testType;

  ResultsScreen({
    required this.reactionTime,
    required this.sensorData,
    this.testType = 'Unknown',
  });

  Widget _buildSensorBarChart(Map<String, dynamic> sensorData) {
    final avgResponse = double.tryParse(sensorData['EEG'] ?? '0') ?? 0;
    final mathTime = double.tryParse(sensorData['ECG'] ?? '0') ?? 0;
    final responseSD = double.tryParse(sensorData['EMG'] ?? '0') ?? 0;
    final errors = double.tryParse(sensorData['EyeTracking'] ?? '0') ?? 0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const titles = ['Avg Resp', 'Math Time', 'Resp SD', 'Errors'];
                return Text(titles[value.toInt()], style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue[900]));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue[900]),
                );
              },
              interval: 20,
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [
            BarChartRodData(toY: avgResponse, color: Colors.blue, width: 15),
          ]),
          BarChartGroupData(x: 1, barRods: [
            BarChartRodData(toY: mathTime, color: Colors.blueAccent, width: 15),
          ]),
          BarChartGroupData(x: 2, barRods: [
            BarChartRodData(toY: responseSD, color: Colors.blue[700], width: 15),
          ]),
          BarChartGroupData(x: 3, barRods: [
            BarChartRodData(toY: errors, color: Colors.blue[900], width: 15),
          ]),
        ],
      ),
    );
  }

  Widget _navigateToTestScreen(BuildContext context) {
    switch (testType) {
      case 'Single':
        return SingleTaskScreen();
      case 'Dual':
        return DualTaskScreen();
      case 'AuditoryBio':
        return AuditoryBiofeedbackScreen();
      case 'VisualBio':
        return VisualBiofeedbackScreen();
      case 'TappingBio':
        return TappingBiofeedbackScreen();
      default:
        return HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Results', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue, Colors.blueAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Text(
                          '$testType Results',
                          style: GoogleFonts.poppins(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        testType == 'Single' ? 'Reaction Time: ${reactionTime} s' : 'Math Solving Time: ${reactionTime} s',
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.blue[900]),
                      ),
                      SizedBox(height: 20),
                      if (sensorData.containsKey('MathAnswer')) ...[
                        Text(
                          'Your Answer: ${sensorData['MathAnswer']}',
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                        Text(
                          'Correct Answer: ${sensorData['CorrectAnswer']}',
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                        SizedBox(height: 20),
                      ],
                      if (sensorData.containsKey('EEG')) ...[
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  'Biofeedback Metrics',
                                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blue[900]),
                                ),
                                SizedBox(height: 8),
                                SizedBox(
                                  height: 200,
                                  child: _buildSensorBarChart(sensorData),
                                ),
                                SizedBox(height: 8),
                                Text('Average Interval/Response: ${sensorData['EEG']} sec', style: GoogleFonts.poppins()),
                                Text('Math Solving Time: ${sensorData['ECG']} ms', style: GoogleFonts.poppins()),
                                Text('Interval/Response SD: ${sensorData['EMG']} sec', style: GoogleFonts.poppins()),
                                Text('Errors: ${sensorData['EyeTracking']}', style: GoogleFonts.poppins()),
                              ],
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => _navigateToTestScreen(context)));
                        },
                        child: Text('Retake Test'),
                      ),
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