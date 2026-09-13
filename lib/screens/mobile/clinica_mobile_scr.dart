import 'package:flutter/material.dart';

class ClinicaMobileScr extends StatelessWidget {
  const ClinicaMobileScr({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.teal,
      body: Center(
        child: Text(
          "CLÍNICA",
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2.0,
          ),
        ),
      ),
    );
  }
}
