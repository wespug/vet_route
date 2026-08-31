import 'package:flutter/material.dart';
import 'package:vet_route/models/coleta_model.dart';
import 'package:intl/intl.dart';

class ModalDetalhesColetaMotoboy extends StatelessWidget {
  final Coleta item;
  final bool isInsumo;

  const ModalDetalhesColetaMotoboy({
    super.key,
    required this.item,
    required this.isInsumo,
  });

  @override
  Widget build(BuildContext context) {
    final String origem = isInsumo
        ? item.laboratorioDestino.nome
        : item.nomeClinica;
    final String destino = isInsumo
        ? item.nomeClinica
        : item.laboratorioDestino.nome;

    final String codigoOriginal = item.codigo.isNotEmpty
        ? item.codigo
        : (item.codigoAcompanhamento ?? item.id);
    final String codigoFormatado = codigoOriginal.length >= 6
        ? codigoOriginal.substring(0, 6).toUpperCase()
        : codigoOriginal.toUpperCase();

    final formatadorData = DateFormat('dd/MM/yyyy HH:mm');
    final String dataFormatada = item.dataCriacao != null
        ? formatadorData.format(item.dataCriacao!)
        : '--/--/----';

    // Lista vazia segura para evitar o NoSuchMethodError de propriedades inexistentes
    final List<dynamic> itensLista = [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Container(
        width: 550,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isInsumo
                      ? Icons.inventory_2_outlined
                      : Icons.vaccines_outlined,
                  color: Colors.grey.shade700,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "${isInsumo ? 'Pedido' : 'Coleta'} #$codigoFormatado - ${item.status}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isInsumo
                          ? Icons.business_rounded
                          : Icons.local_hospital_rounded,
                      color: Colors.indigo,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Origem: $origem",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Destino: $destino",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          "Solicitado em: $dataFormatada",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isInsumo
                      ? "Itens Solicitados para Entrega:"
                      : "Amostras para Coleta:",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "${itensLista.isEmpty ? 1 : itensLista.length} item(ns)",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: itensLista.isEmpty
                  ? Row(
                      children: [
                        Icon(
                          isInsumo
                              ? Icons.medication_rounded
                              : Icons.science_rounded,
                          color: Colors.indigo,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isInsumo
                                ? "Pacote de insumos fechado"
                                : "Material biológico para análise",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: itensLista.map((i) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Icon(
                                isInsumo
                                    ? Icons.medication_rounded
                                    : Icons.science_rounded,
                                color: Colors.indigo,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      i['descricao'] ?? i['nome'] ?? 'Item',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "${i['quantidade'] ?? i['qtd'] ?? 1} un.",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Observações da Rota",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sem observações adicionais cadastradas para este pedido.',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  "Fechar Detalhes",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
