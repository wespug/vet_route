import 'package:flutter/material.dart';

class GestaoExamesColetaView extends StatelessWidget {
  const GestaoExamesColetaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors
            .green
            .shade400, // 🟢 O clássico quadrado verde de homologação
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.science_rounded, size: 64, color: Colors.white),
            SizedBox(height: 16),
            Text(
              "Gestão de Exames para Coleta",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Tela de homologação de roteamento dinâmico concluída.",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
