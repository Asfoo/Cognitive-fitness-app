import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'single_task_screen.dart';
import 'dual_task_screen.dart';
import 'dual_task_biofeedback_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cognitive Fitness', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blue[700],
        elevation: 10,
        shadowColor: Colors.blue[900],
        centerTitle: true,
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
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Select a Test',
                      style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.blue[900]),
                    ),
                    SizedBox(height: 20, width: double.infinity,),
                    _buildAnimatedButton(context, 'Single-Task Test', SingleTaskScreen()),
                    SizedBox(height: 16),
                    _buildAnimatedButton(context, 'Dual-Task Test', DualTaskScreen()),
                    SizedBox(height: 16),
                    _buildAnimatedButton(context, 'Dual-Task with Biofeedback', DualTaskBiofeedbackScreen()),
                    SizedBox(height: 16),
                    _buildAnimatedButton(context, 'View History', HistoryScreen()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedButton(BuildContext context, String text, Widget destination) {
    return AnimatedScaleButton(
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => destination)),
        child: Container(
          alignment: Alignment.center,
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          decoration: BoxDecoration(
          
           borderRadius: BorderRadius.circular(10),
           boxShadow: [
             BoxShadow(
               color: Colors.blue[900]!.withAlpha(100),
               spreadRadius: 2,
               blurRadius: 5,
               offset: Offset(0, 3),
             ),],
            
            color: Colors.blue[700],
            
          ),
          
          
          child: Text(text, 
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedScaleButton extends StatefulWidget {
  final Widget child;
  AnimatedScaleButton({required this.child});

  @override
  _AnimatedScaleButtonState createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<AnimatedScaleButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}