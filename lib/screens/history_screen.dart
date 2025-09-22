import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../db/database_helper.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _results = [];
  Map<String, dynamic> _latestResult = {};

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query('test_results', orderBy: 'timestamp DESC', limit: 5);
    final latestResult = await DatabaseHelper.instance.getLatestResult();
    setState(() {
      _results = results;
      _latestResult = latestResult;
    });
  }

  double _calculateYInterval() {
    if (_results.isEmpty) return 500.0;
    final reactionTimes = _results.map((result) => result['reaction_time'].toDouble()).toList();
    final maxTime = reactionTimes.isNotEmpty ? reactionTimes.reduce((a, b) => a > b ? a : b) : 1000.0;
    final minTime = reactionTimes.isNotEmpty ? reactionTimes.reduce((a, b) => a < b ? a : b) : 0.0;
    final range = maxTime - minTime;
    return (range / 4).ceilToDouble().clamp(200.0, 500.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test History', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text(
                          'Recent Reaction Times (Last 5 Tests)',
                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.blue[900]),
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: _results.isEmpty
                              ? Center(child: Text('No data available', style: GoogleFonts.poppins()))
                              : LineChart(
                                  LineChartData(
                                    gridData: FlGridData(show: true),
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            final index = value.toInt();
                                            if (index >= 0 && index < _results.length) {
                                              String testType = _results[index]['test_type'];
                                              if (testType == 'Single') {
                                                testType = 'Single';
                                              } else if (testType == 'Dual') {
                                                testType = 'Dual';
                                              } else if (testType == 'AuditoryBio') {
                                                testType = 'Auditory';
                                              } else if (testType == 'VisualBio') {
                                                testType = 'Visual';
                                              } else if (testType == 'TappingBio') {
                                                testType = 'Tapping';
                                              }
                                              return Text(
                                                '$testType ${_results.length - index}',
                                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue[900]),
                                              );
                                            }
                                            return Text('');
                                          },
                                          interval: 1,
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            final reactionTime = value.toInt();
                                            if (reactionTime >= 1000) {
                                              return Text(
                                                '${(reactionTime / 1000).toStringAsFixed(1)} s',
                                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue[900]),
                                              );
                                            }
                                            return Text(
                                              '$reactionTime ms',
                                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue[900]),
                                              );
                                          },
                                          interval: _calculateYInterval(),
                                          reservedSize: 40,
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: true),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: _results.asMap().entries.map((entry) {
                                          return FlSpot(entry.key.toDouble(), entry.value['reaction_time'].toDouble());
                                        }).toList(),
                                        isCurved: true,
                                        color: Colors.blue,
                                        dotData: FlDotData(show: true),
                                        belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.2)),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text(
                          'Latest Biofeedback Metrics',
                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.blue[900]),
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: _latestResult.isEmpty || (!_latestResult.containsKey('eeg') || _latestResult['eeg'] == 0)
                              ? Center(child: Text('No biofeedback data available', style: GoogleFonts.poppins()))
                              : BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            const titles = ['Avg Resp', 'Math Time', 'Resp SD', 'Errors'];
                                            return Text(
                                              titles[value.toInt()],
                                              style: GoogleFonts.poppins(fontSize: 12),
                                            );
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            return Text(
                                              value.toInt().toString(),
                                              style: GoogleFonts.poppins(fontSize: 12),
                                            );
                                          },
                                          interval: 20,
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: true),
                                    barGroups: [
                                      BarChartGroupData(x: 0, barRods: [
                                        BarChartRodData(
                                          toY: (_latestResult['eeg'] ?? 0).toDouble(),
                                          color: Colors.blue,
                                          width: 15,
                                        ),
                                      ]),
                                      BarChartGroupData(x: 1, barRods: [
                                        BarChartRodData(
                                          toY: (_latestResult['ecg'] ?? 0).toDouble(),
                                          color: Colors.blueAccent,
                                          width: 15,
                                        ),
                                      ]),
                                      BarChartGroupData(x: 2, barRods: [
                                        BarChartRodData(
                                          toY: (_latestResult['emg'] ?? 0).toDouble(),
                                          color: Colors.blue[700],
                                          width: 15,
                                        ),
                                      ]),
                                      BarChartGroupData(x: 3, barRods: [
                                        BarChartRodData(
                                          toY: (_latestResult['eye_tracking'] ?? 0).toDouble(),
                                          color: Colors.blue[900],
                                          width: 15,
                                        ),
                                      ]),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}