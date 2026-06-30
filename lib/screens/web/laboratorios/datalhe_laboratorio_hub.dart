import 'package:flutter/material.dart';
import 'package:vet_route/models/laboratorio_model.dart';
import 'package:vet_route/screens/web/laboratorios/dashboard_laboratorio_hub.dart';
import 'package:vet_route/screens/web/laboratorios/gestao_insumo_hub.dart';
import 'package:vet_route/screens/web/laboratorios/gestao_usuario_hub.dart';

// 💡 Caso use arquivos separados, descomente as linhas abaixo para importar as classes:
// import 'dashboard_laboratorio_hub.dart';
// import 'gestao_usuario_hub.dart';
// import 'gestao_insumos_hub.dart';

class DetalheLaboratorioHub extends StatelessWidget {
  final Laboratorio laboratorio;

  const DetalheLaboratorioHub({super.key, required this.laboratorio});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TabBar(
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey.shade500,
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 3,
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
          Expanded(
            child: TabBarView(
              children: [
                DashboardLaboratorioHub(laboratorio: laboratorio),
                GestaoUsuarioHub(laboratorio: laboratorio),
                GestaoInsumosHub(laboratorio: laboratorio),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
