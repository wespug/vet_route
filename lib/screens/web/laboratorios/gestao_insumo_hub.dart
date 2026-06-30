import 'package:flutter/material.dart';
import 'package:vet_route/models/laboratorio_model.dart';

class GestaoInsumosHub extends StatelessWidget {
  final Laboratorio laboratorio;

  const GestaoInsumosHub({super.key, required this.laboratorio});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.green.shade400, // 🟢 Caixa Verde de Teste
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            Text(
              "Gestão de Insumos e Kits - ${laboratorio.nome}",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Área reservada para controle de estoque de tubos e kits de coleta.",
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
