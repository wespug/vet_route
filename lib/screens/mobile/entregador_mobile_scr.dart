import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:vet_route/models/coleta_model.dart';
import 'package:vet_route/controllers/coleta_controller.dart';
import 'package:vet_route/screens/widgets/coleta_card.dart';

class EntregadorMobileScr extends StatefulWidget {
  final String? entregadorId;
  final bool isVisaoGeral;

  const EntregadorMobileScr({
    super.key,
    this.entregadorId,
    this.isVisaoGeral = false,
  });

  @override
  State<EntregadorMobileScr> createState() => _EntregadorMobileScrState();
}

class _EntregadorMobileScrState extends State<EntregadorMobileScr> {
  int _selectedSegment = 0; // 0 = A Fazer, 1 = Concluídas

  @override
  void initState() {
    super.initState();
    _iniciarEscutaColetas();
  }

  @override
  void didUpdateWidget(covariant EntregadorMobileScr oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entregadorId != widget.entregadorId) {
      _iniciarEscutaColetas();
    }
  }

  void _iniciarEscutaColetas() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<ColetaController>(context, listen: false);

      if (widget.isVisaoGeral) {
        controller.escutarTodasColetasAtivas();
      } else if (widget.entregadorId != null &&
          widget.entregadorId!.isNotEmpty) {
        controller.escutarColetasDoEntregador(widget.entregadorId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.two_wheeler_rounded,
                    color: Colors.indigo,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Central de Entregas",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.isVisaoGeral
                    ? "Visão geral de paradas e coletas do sistema."
                    : "Acompanhe e gerencie a rota ativa.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildPillLegenda('Exames', const Color(0xFF007AFF)),
                  const SizedBox(width: 8),
                  _buildPillLegenda('Insumos', const Color(0xFF34C759)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl(
                  backgroundColor: Colors.grey.shade300.withOpacity(0.5),
                  thumbColor: Colors.white,
                  groupValue: _selectedSegment,
                  padding: const EdgeInsets.all(4),
                  children: {
                    0: _buildSegmentText("📍 Em Aberto", 0),
                    1: _buildSegmentText("✅ Concluídas", 1),
                  },
                  onValueChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedSegment = value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Consumer<ColetaController>(
                  builder: (context, controller, child) {
                    if (controller.carregando) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.indigo),
                      );
                    }

                    if (!widget.isVisaoGeral &&
                        (widget.entregadorId == null ||
                            widget.entregadorId!.isEmpty)) {
                      return _buildListaAgrupadaMobile(
                        [],
                        controller,
                        isFinalizados: _selectedSegment == 1,
                      );
                    }

                    final listaAtiva = _selectedSegment == 0
                        ? controller.coletasAtivas
                        : controller.coletasFinalizadas;

                    return _buildListaAgrupadaMobile(
                      listaAtiva,
                      controller,
                      isFinalizados: _selectedSegment == 1,
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

  Widget _buildSegmentText(String texto, int index) {
    final isSelected = _selectedSegment == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.black87 : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildPillLegenda(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaAgrupadaMobile(
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
              size: 56,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              isFinalizados
                  ? "Nenhuma parada finalizada ainda."
                  : "Nenhuma parada na rota atual.",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final agrupados = controller.agruparEOrdenarColetas(lista);

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: agrupados.keys.length,
      itemBuilder: (context, index) {
        final chaveData = agrupados.keys.elementAt(index);
        final itensDoDia = agrupados[chaveData]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      controller.formatarDataCabecalho(chaveData).toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      controller.obterTextoQuantidade(itensDoDia.length),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...itensDoDia.map((coleta) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ColetaCard(item: coleta, isFinalizados: isFinalizados),
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}
