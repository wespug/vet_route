import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vet_route/models/coleta_model.dart';
import 'package:vet_route/controllers/gestao_exames_lab_controller.dart';
import 'package:vet_route/screens/web/laboratorios/components/modal_detalhes_exame_lab.dart';

class ItemCardExameKanban extends StatelessWidget {
  final Coleta coleta;

  const ItemCardExameKanban({super.key, required this.coleta});

  // 💡 FORMATADOR UNIVERSAL LIMPO E ELEGANTE (Remove Underscores)
  Map<String, dynamic> _obterConfigStatus(String statusRaw) {
    final s = statusRaw.toLowerCase().trim();
    if (s.contains('pendente') || s.contains('analise'))
      return {'texto': 'Pendente', 'cor': Colors.orange.shade800};
    if (s.contains('separacao') ||
        s.contains('separação') ||
        s.contains('aprovado'))
      return {'texto': 'Em Separação', 'cor': Colors.indigo};
    if (s.contains('aguardando_coleta') || s.contains('aguardando_entregador'))
      return {'texto': 'Aguardando Entregador', 'cor': Colors.amber.shade900};
    if (s.contains('coletar'))
      return {'texto': 'Motoboy no Local', 'cor': Colors.purple.shade700};
    if (s.contains('transporte') || s.contains('rota'))
      return {'texto': 'Em Transporte', 'cor': Colors.blue.shade800};
    if (s.contains('entregue') ||
        s.contains('concluido') ||
        s.contains('concluído'))
      return {'texto': 'Concluído', 'cor': Colors.teal.shade800};
    if (s.contains('cancelado') || s.contains('recusado'))
      return {'texto': 'Cancelado', 'cor': Colors.red.shade700};
    return {
      'texto': statusRaw.replaceAll('_', ' ').toUpperCase(),
      'cor': Colors.grey.shade800,
    };
  }

  @override
  Widget build(BuildContext context) {
    final formatadorHora = DateFormat('dd/MM HH:mm');
    final isUrgente = coleta.isEmergencia;

    final String codigoRaw = coleta.codigoAcompanhamento ?? coleta.id;
    final String codigoFormatado = codigoRaw.length >= 6
        ? codigoRaw.substring(0, 6).toUpperCase()
        : codigoRaw.toUpperCase();

    final configStatus = _obterConfigStatus(coleta.status);
    final corTema = isUrgente ? Colors.redAccent.shade700 : configStatus['cor'];
    final corFundoTema = isUrgente
        ? Colors.red.shade50
        : configStatus['cor'].withOpacity(0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUrgente ? const Color(0xFFFFF5F5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgente ? Colors.redAccent.shade400 : Colors.grey.shade200,
          width: isUrgente ? 2.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isUrgente
                ? Colors.red.withOpacity(0.15)
                : Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isUrgente)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.redAccent.shade700,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              alignment: Alignment.center,
              child: const Text(
                "🚨 URGÊNCIA MÁXIMA - FURA FILA",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ),

          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: isUrgente ? 12 : 16,
              bottom: 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: corFundoTema,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      configStatus['texto']
                          .toUpperCase(), // 💡 STATUS LIMPO (Adeus EM_TRANSPORTE)
                      style: TextStyle(
                        color: corTema,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: isUrgente
                          ? Colors.redAccent
                          : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      coleta.dataCriacao != null
                          ? formatadorHora.format(coleta.dataCriacao!)
                          : '--:--',
                      style: TextStyle(
                        color: isUrgente
                            ? Colors.redAccent.shade700
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF2F2F7), thickness: 1.5),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Icon(
                      Icons.radio_button_checked,
                      color: isUrgente ? corTema : Colors.indigo.shade400,
                      size: 18,
                    ),
                    Container(
                      width: 2,
                      height: 28,
                      color: Colors.grey.shade200,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    const Icon(
                      Icons.location_on,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Coletar em",
                        style: TextStyle(
                          fontSize: 11,
                          color: isUrgente
                              ? Colors.redAccent.shade400
                              : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        coleta.origemVisual,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Entregar em",
                        style: TextStyle(
                          fontSize: 11,
                          color: isUrgente
                              ? Colors.redAccent.shade400
                              : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        coleta.destinoVisual,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUrgente
                  ? corFundoTema
                  : Colors.indigo.shade50.withOpacity(0.5),
              borderRadius: BorderRadius.only(
                bottomLeft: const Radius.circular(14),
                bottomRight: const Radius.circular(14),
                topLeft: isUrgente ? Radius.zero : const Radius.circular(0),
                topRight: isUrgente ? Radius.zero : const Radius.circular(0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        isUrgente
                            ? Icons.warning_rounded
                            : Icons.science_rounded,
                        size: 16,
                        color: isUrgente ? corTema : Colors.indigo.shade600,
                      ),
                      const SizedBox(width: 6),
                      // 💡 ID FICA MAIS CURTO SE PRECISAR, MAS NÃO CORTA FACILMENTE
                      Expanded(
                        child: Text(
                          "ID: #$codigoFormatado",
                          style: TextStyle(
                            color: isUrgente ? corTema : Colors.indigo.shade800,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    final controller = Provider.of<GestaoExamesLabController>(
                      context,
                      listen: false,
                    );
                    showDialog(
                      context: context,
                      builder: (_) => ModalDetalhesExameLab(
                        coleta: coleta,
                        controller: controller,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      "Ver Detalhes",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isUrgente ? corTema : Colors.indigo.shade700,
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
