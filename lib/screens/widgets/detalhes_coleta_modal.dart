import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vet_route/models/coleta_model.dart';

class DetalhesColetaModal extends StatelessWidget {
  final Coleta item;
  final bool isInsumo;

  const DetalhesColetaModal({
    super.key,
    required this.item,
    required this.isInsumo,
  });

  static void exibir(BuildContext context, Coleta item, bool isInsumo) {
    showDialog(
      context: context,
      builder: (context) => DetalhesColetaModal(item: item, isInsumo: isInsumo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatadorData = DateFormat('dd/MM/yyyy HH:mm');
    final dataFormatada = item.dataCriacao != null
        ? formatadorData.format(item.dataCriacao!)
        : 'Data não informada';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            isInsumo ? Icons.inventory_2_rounded : Icons.two_wheeler_rounded,
            color: isInsumo ? const Color(0xFF34C759) : const Color(0xFF007AFF),
          ),
          const SizedBox(width: 10),
          Text(isInsumo ? 'Detalhes do Insumo' : 'Detalhes do Exame'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLinhaDetalhe('Código:', item.codigo),
              _buildLinhaDetalhe('Status:', item.status),
              _buildLinhaDetalhe(
                'Clínica:',
                item.nomeClinica.isNotEmpty
                    ? item.nomeClinica
                    : 'Não informada',
              ),
              _buildLinhaDetalhe(
                'Laboratório Destino:',
                item.laboratorioDestino.nome.isNotEmpty
                    ? item.laboratorioDestino.nome
                    : 'Não informado',
              ),
              _buildLinhaDetalhe('Data/Hora:', dataFormatada),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007AFF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text("Fechar"),
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
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF8E8E93),
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF1C1C1E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
