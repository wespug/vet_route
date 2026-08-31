import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vet_route/models/coleta_model.dart';
import 'package:vet_route/screens/web/laboratorios/components/modal_detalhes_exame_lab.dart';

class ItemCardExameKanban extends StatelessWidget {
  final Coleta coleta;

  const ItemCardExameKanban({super.key, required this.coleta});

  @override
  Widget build(BuildContext context) {
    final formatadorHora = DateFormat('dd/MM HH:mm');
    final isUrgente = coleta.isEmergencia;
    final corDestaque = isUrgente ? Colors.redAccent : Colors.indigo;

    // 💡 PADRONIZAÇÃO: Puxa o mesmo código de 6 dígitos visto pela Clínica
    final String codigoRaw = coleta.codigoAcompanhamento ?? coleta.id;
    final String codigoFormatado = codigoRaw.length >= 6
        ? codigoRaw.substring(0, 6).toUpperCase()
        : codigoRaw.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: corDestaque.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isUrgente
                          ? Icons.flash_on_rounded
                          : Icons.science_rounded,
                      size: 14,
                      color: corDestaque,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "ID: #$codigoFormatado", // 💡 Código curto aplicado
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: corDestaque,
                      ),
                    ),
                  ],
                ),
                Text(
                  coleta.dataCriacao != null
                      ? formatadorHora.format(coleta.dataCriacao!)
                      : '--:--',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.storefront_rounded,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Clínica: ${coleta.origemVisual}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.business_rounded,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Lab: ${coleta.destinoVisual}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => ModalDetalhesExameLab(coleta: coleta),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: corDestaque,
                      side: BorderSide(color: corDestaque.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      "Ver Detalhes",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
