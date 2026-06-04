import 'package:flutter/material.dart';

import 'package:vet_route/screens/login_scr.dart';

// Importando os nossos novos arquivos separados!

void main() {
  runApp(const VetRouteApp());
}

class VetRouteApp extends StatelessWidget {
  const VetRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vet Route',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const LoginScreen(),
    );
  }
}

class TelaInicial extends StatelessWidget {
  const TelaInicial({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vet Route - Início')),
      body: Center(),
    );
  }
}
