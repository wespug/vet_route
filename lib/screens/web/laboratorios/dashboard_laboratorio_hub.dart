import 'package:flutter/material.dart';
import 'package:vet_route/models/laboratorio_model.dart';

class DashboardLaboratorioView extends StatelessWidget {
  final Laboratorio laboratorio;
  const DashboardLaboratorioView({Key? key, required this.laboratorio})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.query_stats_rounded,
            size: 80,
            color: Theme.of(context).primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "Dashboard: ${laboratorio.nome}",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Aqui teremos gráficos de coletas, status de motoboys e métricas em tempo real.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
