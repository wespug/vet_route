import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:vet_route/models/coleta_model.dart';
import 'package:vet_route/controllers/coleta_controller.dart';
import 'package:vet_route/screens/widgets/coleta_card.dart';
import 'package:vet_route/screens/widgets/coleta_segmented_control.dart';

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

  String _formatarDataCabecalho(String dataStr) {
    try {
      final data = DateTime.parse(dataStr);
      final hoje = DateTime.now();
      final ontem = hoje.subtract(const Duration(days: 1));

      if (DateFormat('yyyy-MM-dd').format(hoje) == dataStr) {
        return 'Hoje, ${DateFormat("dd 'de' MMMM", 'pt_BR').format(data)}';
      } else if (DateFormat('yyyy-MM-dd').format(ontem) == dataStr) {
        return 'Ontem, ${DateFormat("dd 'de' MMMM", 'pt_BR').format(data)}';
      }

      return DateFormat("EEEE, dd 'de' MMMM", 'pt_BR').format(data);
    } catch (_) {
      return dataStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Central de Entregas',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.entregadorId != null &&
                                widget.entregadorId!.isNotEmpty
                            ? "Rotas e Insumos do Motoboy"
                            : "Visão Geral de Chamados",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8E8E93),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildPillLegenda('Exames', const Color(0xFF007AFF)),
                      const SizedBox(width: 8),
                      _buildPillLegenda('Insumos', const Color(0xFF34C759)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              ColetaSegmentedControl(tabController: _tabController),
              const SizedBox(height: 20),

              Expanded(
                child: Consumer<ColetaController>(
                  builder: (context, controller, child) {
                    if (controller.carregando) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      );
                    }

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildListaAgrupada(
                          controller.coletasAtivas,
                          isFinalizados: false,
                        ),
                        _buildListaAgrupada(
                          controller.coletasFinalizadas,
                          isFinalizados: true,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillLegenda(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaAgrupada(
    List<Coleta> lista, {
    required bool isFinalizados,
  }) {
    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFinalizados ? Icons.archive_outlined : Icons.inbox_outlined,
              size: 48,
              color: const Color(0xFFC7C7CC),
            ),
            const SizedBox(height: 12),
            Text(
              isFinalizados
                  ? "Nenhum exame ou insumo recusado / finalizado."
                  : "Nenhum chamado ativo no momento.",
              style: const TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    }

    final controller = Provider.of<ColetaController>(context, listen: false);
    final agrupados = controller.agruparEOrdenarColetas(lista);

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: agrupados.keys.length,
      itemBuilder: (context, index) {
        final chaveData = agrupados.keys.elementAt(index);
        final itensDoDia = agrupados[chaveData]!;
        final int qtdExames = itensDoDia.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatarDataCabecalho(chaveData).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E5EA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "$qtdExames ${qtdExames == 1 ? 'PEDIDO' : 'PEDIDOS'}",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF636366),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...itensDoDia.map(
              (coleta) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: ColetaCard(item: coleta, isFinalizados: isFinalizados),
              ),
            ),
          ],
        );
      },
    );
  }
}
