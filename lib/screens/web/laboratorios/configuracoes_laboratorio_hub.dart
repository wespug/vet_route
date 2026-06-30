import 'package:flutter/material.dart';
import 'package:vet_route/models/laboratorio_model.dart';

class ConfiguracoesLaboratorioView extends StatelessWidget {
  final Laboratorio laboratorio;
  const ConfiguracoesLaboratorioView({super.key, required this.laboratorio});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              "Configurações Administrativas",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withValues(alpha: 0.1),
              child: const Icon(Icons.edit, color: Colors.orange),
            ),
            title: const Text("Editar Perfil do Laboratório"),
            subtitle: const Text("Atualizar CNPJ, endereço ou telefone"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.withValues(alpha: 0.1),
              child: const Icon(Icons.delete_forever, color: Colors.red),
            ),
            title: const Text("Desativar Laboratório"),
            subtitle: const Text(
              "Bloquear o acesso deste laboratório ao sistema",
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
