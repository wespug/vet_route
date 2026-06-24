import 'package:flutter/material.dart';
import 'package:vet_route/models/laboratorio_model.dart';
import 'package:vet_route/screens/web/laboratorios/configuracoes_laboratorio_hub.dart';
import 'package:vet_route/screens/web/laboratorios/dashboard_laboratorio_hub.dart';
import 'package:vet_route/screens/web/laboratorios/gestao_usuario_laboratorio_hub.dart';

class DetalheLaboratorioHub extends StatelessWidget {
  final Laboratorio laboratorio;

  const DetalheLaboratorioHub({Key? key, required this.laboratorio})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CABEÇALHO COM AS ABAS (Design Clean em formato de Card)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TabBar(
              // CORES MELHORADAS AQUI 👇
              labelColor: Theme.of(
                context,
              ).primaryColor, // Cor do item selecionado (ex: Verde/Azul do seu tema)
              unselectedLabelColor:
                  Colors.grey.shade500, // Cinza legível para não selecionados
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 4,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.dashboard_outlined), text: "Dashboard"),
                Tab(icon: Icon(Icons.people_alt_outlined), text: "Usuários"),
                Tab(
                  icon: Icon(Icons.admin_panel_settings_outlined),
                  text: "Gestão",
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // O CONTEÚDO DAS ABAS
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TabBarView(
                children: [
                  DashboardLaboratorioView(laboratorio: laboratorio),
                  GestaoUsuariosLaboratorioView(laboratorio: laboratorio),
                  ConfiguracoesLaboratorioView(laboratorio: laboratorio),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ... as sub-visões (DashboardLaboratorioView, etc) continuam iguais aqui embaixo ...
