import 'package:flutter/material.dart';

void main() {
  runApp(const VetRouteApp());
}

// === ESTRUTURA PRINCIPAL DO APP ===
class VetRouteApp extends StatelessWidget {
  const VetRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vet Route',
      theme: ThemeData(
        primarySwatch: Colors.green, // Cor base do aplicativo
      ),
      home: const TelaInicial(), // Define qual tela abre primeiro
    );
  }
}

// === TELA INICIAL ===
class TelaInicial extends StatelessWidget {
  const TelaInicial({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vet Route')),
      body: Center(
        // Nosso botão principal
        child: ElevatedButton(
          onPressed: () {
            // Comando que diz ao Flutter para "empurrar" uma nova tela
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TelaLimpa()),
            );
          },
          child: const Text('Abrir Nova Tela'),
        ),
      ),
    );
  }
}

// === TELA LIMPA ===
class TelaLimpa extends StatelessWidget {
  const TelaLimpa({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Tela Limpa')),
      body: const Center(
        child: Text(
          'Pronto! Aqui você pode criar o que quiser.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
