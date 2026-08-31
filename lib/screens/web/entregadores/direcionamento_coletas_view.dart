import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:vet_route/models/coleta_model.dart';
import 'package:vet_route/controllers/coleta_controller.dart';
import 'package:vet_route/screens/widgets/coleta_card.dart';

class DirecionamentoColetasView extends StatefulWidget {
  final String? entregadorId;
  final bool
  isVisaoGeral; // 💡 Nova flag de segurança que impede o vazamento de dados

  const DirecionamentoColetasView({
    super.key,
    this.entregadorId,
    this.isVisaoGeral =
        false, // Por padrão, assume que é a tela privada de um motoboy
  });

  @override
  State<DirecionamentoColetasView> createState() =>
      _DirecionamentoColetasViewState();
}

class _DirecionamentoColetasViewState extends State<DirecionamentoColetasView> {
  int _selectedSegment = 0; // 0 = A Fazer, 1 = Concluídas

  @override
  void initState() {
    super.initState();
    _iniciarEscutaColetas();
  }

  @override
  void didUpdateWidget(covariant DirecionamentoColetasView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entregadorId != widget.entregadorId) {
      _iniciarEscutaColetas();
    }
  }

  void _iniciarEscutaColetas() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<ColetaController>(context, listen: false);

      // 💡 A BLINDAGEM: Agora ela não adivinha mais nada.
      if (widget.isVisaoGeral) {
        controller.escutarTodasColetasAtivas();
      } else if (widget.entregadorId != null &&
          widget.entregadorId!.isNotEmpty) {
        controller.escutarColetasDoEntregador(widget.entregadorId!);
      }
      // Se não for visão geral e o ID estiver vazio/nulo, ela simplesmente NÃO puxa nada (mantém a pista limpa).
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // Cinza claro padrão do sistema
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // CABEÇALHO CLEAN CORPORATIVO
            // ==========================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.two_wheeler_rounded,
                          color: Colors.indigo,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Central de Entregas",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
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
                          : "Acompanhe e gerencie a rota ativa do entregador.",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                // Legendas de Cor
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

            // ==========================================
            // CONTROLE DE ABAS (Padrão Cupertino)
            // ==========================================
            SizedBox(
              width: 400,
              child: CupertinoSlidingSegmentedControl<int>(
                backgroundColor: Colors.grey.shade300.withOpacity(0.5),
                thumbColor: Colors.white,
                groupValue: _selectedSegment,
                padding: const EdgeInsets.all(4),
                children: {
                  0: _buildSegmentText("📍 Paradas em Aberto", 0),
                  1: _buildSegmentText("✅ Concluídas / Recusadas", 1),
                },
                onValueChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSegment = value);
                  }
                },
              ),
            ),
            const SizedBox(height: 24),

            // ==========================================
            // CORPO (GRID RESPONSIVO)
            // ==========================================
            Expanded(
              child: Consumer<ColetaController>(
                builder: (context, controller, child) {
                  if (controller.carregando) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.indigo),
                    );
                  }

                  // Se for o perfil de um motoboy novo e o ID demorou/está vazio, mostra a lista vazia.
                  if (!widget.isVisaoGeral &&
                      (widget.entregadorId == null ||
                          widget.entregadorId!.isEmpty)) {
                    return _buildListaAgrupadaWeb(
                      [],
                      controller,
                      isFinalizados: _selectedSegment == 1,
                    );
                  }

                  final listaAtiva = _selectedSegment == 0
                      ? controller.coletasAtivas
                      : controller.coletasFinalizadas;

                  return _buildListaAgrupadaWeb(
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
    );
  }

  Widget _buildSegmentText(String texto, int index) {
    final isSelected = _selectedSegment == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.black87 : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildPillLegenda(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
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
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cor,
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
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              isFinalizados
                  ? "Nenhuma parada finalizada ainda."
                  : "Nenhuma parada na rota atual.",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
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
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: agrupados.keys.length,
      itemBuilder: (context, index) {
        final chaveData = agrupados.keys.elementAt(index);
        final itensDoDia = agrupados[chaveData]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    controller.formatarDataCabecalho(chaveData).toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      controller.obterTextoQuantidade(itensDoDia.length),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Grid responsivo com Wrap
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: itensDoDia.map((coleta) {
                return SizedBox(
                  width: 420, // Mantém a largura consistente
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
