import 'package:flutter/material.dart';
import 'package:vet_route/models/laboratorio_model.dart';

class GestaoUsuariosLaboratorioView extends StatelessWidget {
  final Laboratorio laboratorio;
  const GestaoUsuariosLaboratorioView({Key? key, required this.laboratorio})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // O Cabeçalho com o botão de adicionar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Membros da Equipe",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Futuro: Abrir modal para adicionar usuário
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Em breve: Formulário de novo usuário'),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text("Novo Usuário"),
              ),
            ],
          ),
          const Spacer(), // Empurra o ícone para o centro
          // O "Vazio" (Placeholder)
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.blueGrey.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            "Nenhum usuário vinculado ainda.",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
