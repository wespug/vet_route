import 'package:flutter/material.dart';

class MotoboyScreen extends StatelessWidget {
  const MotoboyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Área do Motoboy'),
        backgroundColor: Colors.orange,
      ),
      body: const Center(
        child: Text(
          'Bem-vindo à tela do Motoboy!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
