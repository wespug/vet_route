// ignore: file_names
import 'package:flutter/material.dart';

// Importando as nossas outras telas para os atalhos
import 'package:vet_route/screens/clinica_scr.dart';
import 'package:vet_route/screens/laboratorio_scr.dart';
import 'package:vet_route/screens/motoboy_scr.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Acesso Vet Route'),
        backgroundColor: Colors.green, // A cor principal do nosso app
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ícone do topo
            const Icon(Icons.pets, size: 80, color: Colors.green),
            const SizedBox(height: 40),

            // 1ª Caixa: Usuário
            const TextField(
              decoration: InputDecoration(
                labelText: 'Usuário ou E-mail',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 20),

            // 2ª Caixa: Senha
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Senha',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),

            const SizedBox(height: 30),

            // === BOTÃO PRINCIPAL DE ENTRAR ===
            ElevatedButton(
              onPressed: () {
                print("Tentou fazer login!");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'ENTRAR',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 30),

            // === DIVISÓRIA VISUAL ===
            const Divider(), // Uma linha cinza fina
            const SizedBox(height: 10),
            const Text(
              'Acesso Rápido de Teste:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // === OS 3 BOTÕES DE ATALHO ===
            // O widget Row coloca os botões lado a lado
            Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceEvenly, // Espalha os botões com espaços iguais
              children: [
                // Atalho Clínica
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ClinicaScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Clínica',
                    style: TextStyle(color: Colors.teal),
                  ),
                ),

                // Atalho Laboratório
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LaboratorioScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Laboratório',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),

                // Atalho Motoboy
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MotoboyScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Motoboy',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
