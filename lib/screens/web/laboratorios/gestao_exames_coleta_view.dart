import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vet_route/models/laboratorio_model.dart';
import 'package:vet_route/controllers/gestao_exames_lab_controller.dart';
import 'components/item_card_exame_kanban.dart';

class GestaoExamesColetaView extends StatelessWidget {
  final Laboratorio labContexto;

  const GestaoExamesColetaView({super.key, required this.labContexto});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          GestaoExamesLabController()..iniciarEscuta(labContexto.id!),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: const Color(0xFFF4F5F7),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.science_rounded,
                      size: 28,
                      color: Colors.indigo,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Gestão de Exames p/ Coleta",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Painel de controle logístico em tempo real para o laboratório ${labContexto.nome}.",
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                const TabBar(
                  labelColor: Colors.indigo,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.indigo,
                  tabs: [
                    Tab(text: "Kanban Operacional (Dia Atual)"),
                    Tab(text: "Histórico & Encerrados"),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    children: [_buildKanbanBoard(), _buildHistoricoList()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKanbanBoard() {
    return Consumer<GestaoExamesLabController>(
      builder: (context, controller, _) {
        if (controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.indigo),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildColunaKanban(
              "Aguardando Coleta",
              Icons.pending_actions_rounded,
              Colors.orange,
              controller.aguardando,
            ),
            const SizedBox(width: 16),
            _buildColunaKanban(
              "Em Rota p/ Lab",
              Icons.two_wheeler_rounded,
              Colors.blue,
              controller.emRota,
            ),
            const SizedBox(width: 16),
            _buildColunaKanban(
              "Recebidos Hoje",
              Icons.check_circle_outline,
              Colors.green,
              controller.recebidosHoje,
            ),
          ],
        );
      },
    );
  }

  Widget _buildColunaKanban(
    String titulo,
    IconData icone,
    MaterialColor cor,
    List itens,
  ) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Icon(icone, color: cor.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cor.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${itens.length}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cor.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: itens.length,
                itemBuilder: (context, index) {
                  return ItemCardExameKanban(coleta: itens[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricoList() {
    return Consumer<GestaoExamesLabController>(
      builder: (context, controller, _) {
        if (controller.historico.isEmpty) {
          return const Center(
            child: Text(
              "Nenhum histórico disponível.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          itemCount: controller.historico.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 6.0,
                horizontal: 8.0,
              ),
              child: ItemCardExameKanban(coleta: controller.historico[index]),
            );
          },
        );
      },
    );
  }
}
