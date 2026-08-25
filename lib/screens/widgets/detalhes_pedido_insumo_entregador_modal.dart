import 'package:flutter/material.dart';
import '../../models/pedido_insumo_model.dart';

class DetalhesPedidoInsumoEntregadorModal extends StatelessWidget {
  final PedidoInsumoModel item;

  const DetalhesPedidoInsumoEntregadorModal({super.key, required this.item});

  static void exibir(BuildContext context, PedidoInsumoModel item) {
    showDialog(
      context: context,
      builder: (context) => DetalhesPedidoInsumoEntregadorModal(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color corTema = Color(0xFF34C759);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: corTema.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: corTema,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Detalhes do Pedido de Insumo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLinhaDetalhe('Código:', item.id),
              _buildLinhaDetalhe('Status:', item.textoStatus),
              _buildLinhaDetalhe(
                'Origem (Laboratório):',
                item.nomeOrigemVisual,
              ),
              _buildLinhaDetalhe('Destino (Clínica):', item.clinicaNome),
              _buildLinhaDetalhe('Solicitante:', item.usuarioSolicitante),
              _buildLinhaDetalhe(
                'Data/Hora:',
                item.formatarData(item.dataSolicitacao),
              ),
              if (item.justificativaLab.isNotEmpty)
                _buildLinhaDetalhe('Obs. Laboratório:', item.justificativaLab),
              const SizedBox(height: 16),
              const Text(
                'Materiais Solicitados:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 8),
              ...item.itens.map(
                (mat) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          mat['descricao'] ?? 'Material',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        '${mat['quantidade'] ?? 0} un.',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: corTema,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: corTema,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text(
            "Fechar",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildLinhaDetalhe(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF8E8E93),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1C1E),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
