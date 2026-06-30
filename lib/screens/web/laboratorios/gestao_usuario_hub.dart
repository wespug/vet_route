import 'package:flutter/material.dart';
import 'package:vet_route/models/laboratorio_model.dart';

class GestaoUsuarioHub extends StatefulWidget {
  final Laboratorio laboratorio;

  const GestaoUsuarioHub({super.key, required this.laboratorio});

  @override
  State<GestaoUsuarioHub> createState() => _GestaoUsuarioHubState();
}

class _GestaoUsuarioHubState extends State<GestaoUsuarioHub> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_alt_outlined,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              "Gestão de Utilizadores",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Laboratório: ${widget.laboratorio.nome ?? 'Não identificado'}",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
