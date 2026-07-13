import 'package:flutter/material.dart';

class ClinicaDashboardMobileScreen extends StatelessWidget {
  final String rotaQueChamou;

  const ClinicaDashboardMobileScreen({super.key, required this.rotaQueChamou});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            color: Colors.yellow.shade600,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text(
              "Dashboard da Clínica\n(Quadrado Amarelo)",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
