import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auditory_biofeedback_screen.dart';
import 'visual_biofeedback_screen.dart';
import 'tapping_biofeedback_screen.dart';

class DualTaskBiofeedbackScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dual-Task with Biofeedback', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Select Biofeedback Task',
                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.blue[900]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AuditoryBiofeedbackScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: GoogleFonts.poppins(fontSize: 18),
                  ),
                  child: Text('Auditory Biofeedback'),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => VisualBiofeedbackScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: GoogleFonts.poppins(fontSize: 18),
                  ),
                  child: Text('Visual Biofeedback'),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TappingBiofeedbackScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: GoogleFonts.poppins(fontSize: 18),
                  ),
                  child: Text('Tapping pattern feedback'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}