import 'package:flutter/material.dart';
import 'package:vet_route/models/clinica_model.dart';

class ClinicaDashboardView extends StatelessWidget {
  final Clinica clinicaContexto;

  const ClinicaDashboardView({super.key, required this.clinicaContexto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Visão Geral Operacional - ${clinicaContexto.nome}",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Métricas em tempo real (Mock Visual).",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              _buildMockCard(
                "Coletas Solicitadas Hoje",
                "12",
                Icons.local_shipping_rounded,
                Colors.teal,
              ),
              _buildMockCard(
                "Laudos Pendentes",
                "5",
                Icons.science_rounded,
                Colors.orange,
              ),
              _buildMockCard(
                "Faturas em Aberto",
                "R\$ 450,00",
                Icons.payments_rounded,
                Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMockCard(
    String titulo,
    String valor,
    IconData icone,
    Color cor,
  ) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: cor.withAlpha(25),
            radius: 28,
            child: Icon(icone, color: cor, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
