import 'package:flutter/material.dart';

class LaboratorioScreen extends StatelessWidget {
  const LaboratorioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Área do Laboratório'),
        backgroundColor: Colors.blueAccent,
      ),
      body: const Center(
        child: Text(
          'Bem-vindo à tela do Laboratório!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
