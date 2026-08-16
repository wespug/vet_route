import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vet_route/controllers/direcionamento_coletas_controller.dart';
import 'package:vet_route/models/chamado_coleta_model.dart';

class DirecionamentoColetasView extends StatefulWidget {
  final String? entregadorId;

  const DirecionamentoColetasView({super.key, this.entregadorId});

  @override
  State<DirecionamentoColetasView> createState() =>
      _DirecionamentoColetasViewState();
}

class _DirecionamentoColetasViewState extends State<DirecionamentoColetasView>
    with SingleTickerProviderStateMixin {
  late DirecionamentoColetasController _controller;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = DirecionamentoColetasController();
    _tabController = TabController(length: 2, vsync: this);
    _controller.escutarColetasDoEntregador(entregadorId: widget.entregadorId);
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // BARRA SUPERIOR DE ABAS INTERNAS
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.deepOrange,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Colors.deepOrange,
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  icon: Icon(Icons.assignment_outlined, size: 20),
                  text: "Agenda & Pendentes",
                ),
                Tab(
                  icon: Icon(Icons.check_circle_outline, size: 20),
                  text: "Coletas Concluídas",
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: _controller.isLoading,
              builder: (context, loading, child) {
                if (loading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.deepOrange),
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAbaAgendaEPendentes(),
                    _buildAbaConcluidas(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 1️⃣ ABA AGENDA E PENDENTES (SEPARADO POR DIA)
  Widget _buildAbaAgendaEPendentes() {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _controller.coletasAtrasadas,
        _controller.coletasHoje,
        _controller.coletasFuturas,
      ]),
      builder: (context, child) {
        final atrasadas = _controller.coletasAtrasadas.value;
        final hoje = _controller.coletasHoje.value;
        final futuras = _controller.coletasFuturas.value;

        if (atrasadas.isEmpty && hoje.isEmpty && futuras.isEmpty) {
          return _buildEmptyState("Nenhuma coleta pendente no momento.");
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (atrasadas.isNotEmpty)
              _buildSecaoData(
                titulo:
                    "⚠️ Pendências de Dias Anteriores (${atrasadas.length})",
                corHeader: Colors.red.shade700,
                corFundoHeader: Colors.red.shade50,
                coletas: atrasadas,
              ),
            if (hoje.isNotEmpty)
              _buildSecaoData(
                titulo: "🟢 Coletas para Hoje (${hoje.length})",
                corHeader: Colors.green.shade800,
                corFundoHeader: Colors.green.shade50,
                coletas: hoje,
              ),
            if (futuras.isNotEmpty)
              _buildSecaoData(
                titulo: "📅 Próximos Dias (${futuras.length})",
                corHeader: Colors.blue.shade800,
                corFundoHeader: Colors.blue.shade50,
                coletas: futuras,
              ),
          ],
        );
      },
    );
  }

  // 2️⃣ ABA DE COLETAS CONCLUÍDAS
  Widget _buildAbaConcluidas() {
    return ValueListenableBuilder<List<ChamadoColetaModel>>(
      valueListenable: _controller.coletasConcluidas,
      builder: (context, concluidas, child) {
        if (concluidas.isEmpty) {
          return _buildEmptyState("Nenhuma coleta concluída registrada.");
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: concluidas.length,
          itemBuilder: (context, index) {
            final item = concluidas[index];
            return _buildCardColeta(item, isConcluida: true);
          },
        );
      },
    );
  }

  Widget _buildSecaoData({
    required String titulo,
    required Color corHeader,
    required Color corFundoHeader,
    required List<ChamadoColetaModel> coletas,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: corFundoHeader,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: corHeader,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: coletas.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              return _buildCardColeta(coletas[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCardColeta(ChamadoColetaModel item, {bool isConcluida = false}) {
    final formatadorData = DateFormat('dd/MM/yyyy HH:mm');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: item.isEmergencia
                  ? Colors.red.shade50
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.isEmergencia
                  ? Icons.warning_amber_rounded
                  : Icons.local_shipping_outlined,
              color: item.isEmergencia ? Colors.red : Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.clinicaNome,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (item.isEmergencia)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "URGENTE",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Destino: ${item.laboratorioNome}",
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                if (item.observacao.isNotEmpty)
                  Text(
                    "Obs: ${item.observacao}",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatadorData.format(item.dataAgendamento),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isConcluida
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.status,
                  style: TextStyle(
                    color: isConcluida
                        ? Colors.green.shade900
                        : Colors.orange.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String mensagem) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            mensagem,
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
