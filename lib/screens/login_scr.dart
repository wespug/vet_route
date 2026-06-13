import 'package:flutter/material.dart';
import 'package:vet_route/controllers/core/logger_mixin.dart';

import 'package:vet_route/screens/clinica_scr.dart';
import 'package:vet_route/screens/laboratorio_scr.dart';
import 'package:vet_route/screens/motoboy_scr.dart';

// 1. A casca volta a ser limpa e const! (Sem o 'with LoggerMixin' aqui)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// 2. Colocamos o Mixin AQUI, no State!
class _LoginScreenState extends State<LoginScreen> with LoggerMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Acesso Vet Route'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.pets, size: 80, color: Colors.green),
            const SizedBox(height: 40),

            const TextField(
              decoration: InputDecoration(
                labelText: 'Usuário ou E-mail',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Senha',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 30),

            // === BOTÃO PRINCIPAL ===
            ElevatedButton(
              onPressed: () {
                // 3. Como o Mixin está no State, chamamos o log DIRETAMENTE
                // (Não precisamos mais do 'widget.')
                log.i("Tentou fazer login!");
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

            const Divider(),
            const SizedBox(height: 10),
            const Text(
              'Acesso Rápido de Teste:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // === BOTÕES DE ATALHO ===
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClinicaScreen(),
                    ),
                  ),
                  child: const Text(
                    'Clínica',
                    style: TextStyle(color: Colors.teal),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LaboratorioScreen(),
                    ),
                  ),
                  child: const Text(
                    'Laboratório',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MotoboyScreen(),
                    ),
                  ),
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
