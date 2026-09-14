import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:vet_route/models/item_logistica_model.dart';

class ItemCardColetaMobile extends StatelessWidget {
  final ItemLogisticaModel item;

  const ItemCardColetaMobile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final dataFormatada = DateFormat('dd/MM/yyyy').format(item.dataCriacao);
    final horaFormatada = DateFormat('HH:mm').format(item.dataCriacao);
    final dataHoraExibicao = "$dataFormatada às $horaFormatada";

    final isEmergencia = item.nomeTipoFormatado.toLowerCase().contains('urg');

    Color corTema;
    String badgeTexto;
    IconData iconeTipo;

    if (item.isInsumo) {
      corTema = Colors.teal;
      badgeTexto = "PEDIDO DE INSUMO";
      iconeTipo = Icons.inventory_2_rounded;
    } else if (isEmergencia) {
      corTema = Colors.redAccent.shade700;
      badgeTexto = "URGÊNCIA";
      iconeTipo = Icons.flash_on_rounded;
    } else {
      corTema = Colors.indigo;
      badgeTexto = "COLETA AGENDADA";
      iconeTipo = Icons.science_rounded;
    }

    final statusNorm = item.status.toLowerCase();
    final isEncerrado = [
      'entregue',
      'concluído',
      'concluido',
      'recusado',
      'cancelado',
    ].contains(statusNorm);

    Color corStatus;
    if (statusNorm.contains('pendente') || statusNorm.contains('aguardando')) {
      corStatus = Colors.orange.shade700;
    } else if (statusNorm.contains('rota') || statusNorm.contains('caminho')) {
      corStatus = Colors.indigo.shade600;
    } else if (isEncerrado) {
      corStatus = Colors.grey.shade600;
      corTema = Colors.grey.shade600;
    } else {
      corStatus = corTema;
    }

    final codExibicao = item.codigo.length > 6
        ? item.codigo.substring(0, 6).toUpperCase()
        : item.codigo.toUpperCase();

    String statusExibicao = item.status.replaceAll('_', ' ').toLowerCase();
    statusExibicao = statusExibicao
        .split(' ')
        .map(
          (str) => str.isNotEmpty
              ? '${str[0].toUpperCase()}${str.substring(1)}'
              : '',
        )
        .join(' ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: corTema.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeTexto,
                    style: TextStyle(
                      color: corTema,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  "#$codExibicao",
                  style: TextStyle(
                    color: Colors.indigo.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(iconeTipo, color: corTema, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Destino: ${item.laboratorioNome.isNotEmpty ? item.laboratorioNome : 'Laboratório'}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dataHoraExibicao,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 💡 SESSÃO DO ENTREGADOR ESPELHADA DA WEB EM TEMPO REAL
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection(
                  item.isInsumo ? 'pedidos_insumos' : 'chamados_coleta',
                )
                .doc(item.id)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const SizedBox.shrink();
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final String? nomeEntregador = data['nomeEntregador']?.toString();
              final bool isTerceiro = data['isTransporteExterno'] ?? false;
              final String placa =
                  data['placa']?.toString() ??
                  data['placaExterna']?.toString() ??
                  '';

              final bool temEntregador =
                  nomeEntregador != null &&
                  nomeEntregador.isNotEmpty &&
                  !nomeEntregador.toLowerCase().contains('aguardando');

              if (!temEntregador) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isTerceiro
                        ? Colors.purple.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isTerceiro
                          ? Colors.purple.shade200
                          : Colors.orange.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isTerceiro
                              ? Colors.purple.shade100
                              : Colors.orange.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isTerceiro
                              ? Icons.local_shipping_rounded
                              : Icons.sports_motorsports_rounded,
                          size: 20,
                          color: isTerceiro
                              ? Colors.purple.shade700
                              : Colors.orange.shade800,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isTerceiro
                                  ? "SERVIÇO TERCEIRIZADO"
                                  : "MOTOBOY VET ROUTE",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: isTerceiro
                                    ? Colors.purple.shade700
                                    : Colors.orange.shade900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              nomeEntregador,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (placa.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.grey.shade400,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            placa.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Status:",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: corStatus.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: corStatus.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusExibicao,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: corStatus,
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
