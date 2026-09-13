import 'package:flutter/material.dart';

class LaboratorioMobileScr extends StatelessWidget {
  const LaboratorioMobileScr({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.indigo,
      body: Center(
        child: Text(
          "LABORATÓRIO",
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
