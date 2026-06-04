import 'package:flutter/material.dart';

// Importando os nossos novos arquivos separados!
import 'screens/clinica_screen.dart';
import 'screens/laboratorio_screen.dart';
import 'screens/motoboy_screen.dart';

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
      home: const TelaInicial(),
    );
  }
}

class TelaInicial extends StatelessWidget {
  const TelaInicial({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vet Route - Início')),
      body: Center(
        // O Widget Column nos permite colocar vários itens um embaixo do outro
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // Centraliza tudo no meio da tela
          children: [
            // Botão 1: Clínica
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClinicaScreen(),
                  ),
                );
              },
              child: const Text('Entrar como Clínica'),
            ),

            const SizedBox(
              height: 20,
            ), // Um espaço em branco de 20 pixels entre os botões
            // Botão 2: Laboratório
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LaboratorioScreen(),
                  ),
                );
              },
              child: const Text('Entrar como Laboratório'),
            ),

            const SizedBox(height: 20), // Mais um espaço
            // Botão 3: Motoboy
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MotoboyScreen(),
                  ),
                );
              },
              child: const Text('Entrar como Motoboy'),
            ),
          ],
        ),
      ),
    );
  }
}
