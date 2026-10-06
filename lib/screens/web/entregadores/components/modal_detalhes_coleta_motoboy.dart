import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vet_route/models/coleta_model.dart';

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
    final String codigoOriginal = item.codigo.isNotEmpty
        ? item.codigo
        : (item.codigoAcompanhamento ?? item.id);
    final String codigoFormatado = codigoOriginal.length >= 6
        ? codigoOriginal.substring(0, 6).toUpperCase()
        : codigoOriginal.toUpperCase();

    final Color corTema = isInsumo ? Colors.teal : Colors.indigo;

    // Tratamento de Itens (se houver, e se for Insumo)
    final List<dynamic> itensInsumo =
        []; // TODO: Expandir modelo de Coleta para receber a lista de itens se necessário.

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFFF4F4F8),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isInsumo ? Icons.inventory_2_rounded : Icons.vaccines_rounded,
                  color: corTema,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isInsumo ? "Detalhes do Insumo" : "Detalhes da Coleta",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildLinhaDetalhe("ID", "#$codigoFormatado", Icons.tag),
                  const Divider(height: 24),
                  _buildLinhaDetalhe(
                    "Status",
                    item.status
                        .replaceAll('_', ' ')
                        .toUpperCase(), // Remove o underscore e põe em maiúsculas
                    Icons.info_outline,
                  ),
                  const Divider(height: 24),
                  _buildLinhaDetalhe(
                    "Agendamento",
                    item.dataCriacao != null
                        ? DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(item.dataCriacao!)
                        : "A definir",
                    Icons.calendar_today_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.radio_button_checked,
                        color: Colors.blue,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Ponto de Coleta",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              item.origemVisual,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 8.0,
                      top: 4,
                      bottom: 4,
                    ),
                    child: Container(
                      width: 2,
                      height: 20,
                      color: Colors.grey.shade300,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Ponto de Entrega",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              item.destinoVisual,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // TODO: Se 'itens' existissem na ColetaModel, faríamos um map aqui para mostrar a listagem de insumos.
            // if (isInsumo && itensInsumo.isNotEmpty) ...
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: corTema,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Ciente, Voltar",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinhaDetalhe(String label, String valor, IconData icone) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icone, size: 20, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
