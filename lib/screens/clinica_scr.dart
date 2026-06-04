import 'package:flutter/material.dart';

class ClinicaScreen extends StatelessWidget {
  const ClinicaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Área da Clínica'),
        backgroundColor: Colors.teal, // Cor diferente para diferenciar
      ),
      body: const Center(
        child: Text(
          'Bem-vindo à tela da Clínica!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
