import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:vet_route/models/coleta_model.dart';
import 'package:vet_route/controllers/coleta_controller.dart';
import 'package:vet_route/screens/widgets/coleta_card.dart'; // Chamando o nosso novo Card Limpo!

class DirecionamentoColetasView extends StatefulWidget {
  final String? entregadorId;

  const DirecionamentoColetasView({super.key, this.entregadorId});

  @override
  State<DirecionamentoColetasView> createState() =>
      _DirecionamentoColetasViewState();
}

class _DirecionamentoColetasViewState extends State<DirecionamentoColetasView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _iniciarEscutaColetas();
  }

  @override
  void didUpdateWidget(covariant DirecionamentoColetasView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entregadorId != widget.entregadorId) {
      _iniciarEscutaColetas();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _iniciarEscutaColetas() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<ColetaController>(context, listen: false);
      if (widget.entregadorId != null && widget.entregadorId!.isNotEmpty) {
        controller.escutarColetasDoEntregador(widget.entregadorId!);
      } else {
        controller.escutarTodasColetasAtivas();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F5),
      body: Column(
        children: [
          // ==========================================
          // HEADER PREMIUM WEB (Visão Despachante/Uber)
          // ==========================================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            decoration: const BoxDecoration(
              color: Color(0xFF1C1C1E),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.deepOrange.shade400),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.circle,
                            color: Colors.deepOrange,
                            size: 12,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.entregadorId != null &&
                                    widget.entregadorId!.isNotEmpty
                                ? "Status: Rota Ativa"
                                : "Status: Visão Geral",
                            style: const TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.two_wheeler_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Central de Entregas",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Acompanhe as paradas e gerencie as coletas em tempo real.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                    // Legendas Limpas e Modernas
                    Row(
                      children: [
                        _buildPillLegenda('Exames', const Color(0xFF007AFF)),
                        const SizedBox(width: 12),
                        _buildPillLegenda('Insumos', const Color(0xFF34C759)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ABAS (Tabs) com design Web
                Container(
                  height: 50,
                  width: 400,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey.shade400,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: "📍 A Fazer"),
                      Tab(text: "✅ Concluídas"),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // CORPO (GRID RESPONSIVO)
          // ==========================================
          Expanded(
            child: Consumer<ColetaController>(
              builder: (context, controller, child) {
                if (controller.carregando) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.deepOrange),
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildListaAgrupadaWeb(
                      controller.coletasAtivas,
                      controller,
                      isFinalizados: false,
                    ),
                    _buildListaAgrupadaWeb(
                      controller.coletasFinalizadas,
                      controller,
                      isFinalizados: true,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillLegenda(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaAgrupadaWeb(
    List<Coleta> lista,
    ColetaController controller, {
    required bool isFinalizados,
  }) {
    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFinalizados
                  ? Icons.check_circle_outline
                  : Icons.sports_motorsports_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              isFinalizados
                  ? "Nenhuma parada finalizada ainda."
                  : "Pista limpa! Nenhuma parada na sua rota.",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final agrupados = controller.agruparEOrdenarColetas(lista);

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      itemCount: agrupados.keys.length,
      itemBuilder: (context, index) {
        final chaveData = agrupados.keys.elementAt(index);
        final itensDoDia = agrupados[chaveData]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    controller.formatarDataCabecalho(chaveData).toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      controller.obterTextoQuantidade(itensDoDia.length),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Grid responsivo usando Wrap (não estica até o fim da tela, fica com blocos de largura fixa)
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: itensDoDia.map((coleta) {
                return SizedBox(
                  width: 420, // Largura padrão Web
                  child: ColetaCard(item: coleta, isFinalizados: isFinalizados),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }
}
