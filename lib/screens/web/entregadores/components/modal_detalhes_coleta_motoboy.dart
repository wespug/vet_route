import 'package:flutter/material.dart';
import 'package:vet_route/models/coleta_model.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ModalDetalhesColetaMotoboy extends StatelessWidget {
  final Coleta item;
  final bool isInsumo;

  const ModalDetalhesColetaMotoboy({
    super.key,
    required this.item,
    required this.isInsumo,
  });

  DateTime _parseData(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    if (val is DateTime) return val;
    return DateTime.now();
  }

  String _formatarData(DateTime data) {
    return "${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} às ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final String origem = item.origemVisual;
    final String destino = item.destinoVisual;

    final String codigoFormatado = item.id.length >= 6
        ? item.id.substring(0, 6).toUpperCase()
        : item.id.toUpperCase();

    final formatadorData = DateFormat('dd/MM/yyyy HH:mm');
    final String dataFormatada = item.dataCriacao != null
        ? formatadorData.format(item.dataCriacao!)
        : '--/--/----';

    final List<dynamic> itensSeguros = item.itens;

    // Preparação do Histórico Logístico
    List<Map<String, dynamic>> logs = List<Map<String, dynamic>>.from(
      item.historico.map((e) => Map<String, dynamic>.from(e)),
    );
    logs.sort((a, b) => _parseData(a['data']).compareTo(_parseData(b['data'])));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Container(
        width: 550,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
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
                          const SizedBox(height: 4),
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
                    "${itensSeguros.isEmpty ? 1 : itensSeguros.length} item(ns)",
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
                child: itensSeguros.isEmpty
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
                                  ? "Pacote de insumos lacrado"
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
                        children: itensSeguros.map((i) {
                          final String descricao =
                              i['descricao'] ??
                              i['nome'] ??
                              i['nomeInsumo'] ??
                              'Item';
                          final String qtd = (i['quantidade'] ?? i['qtd'] ?? 1)
                              .toString();

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              children: [
                                Icon(
                                  isInsumo
                                      ? Icons.medication_rounded
                                      : Icons.science_rounded,
                                  color: Colors.indigo,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    descricao,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Text(
                                  "$qtd un.",
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

              if (logs.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  "Histórico do Pedido",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: logs.map((log) {
                    final int index = logs.indexOf(log);
                    final bool isUltimo = index == logs.length - 1;
                    final String statusStr = (log['status'] ?? 'DESCONHECIDO')
                        .toString()
                        .toUpperCase();
                    final String usuario = log['usuario'] ?? 'Sistema';
                    final String obs = log['observacao'] ?? '';
                    final DateTime dataLog = _parseData(log['data']);

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: isUltimo
                                    ? Colors.indigo
                                    : Colors.grey.shade400,
                                shape: BoxShape.circle,
                                border: isUltimo
                                    ? Border.all(
                                        color: Colors.indigo.shade100,
                                        width: 3,
                                      )
                                    : null,
                              ),
                            ),
                            if (!isUltimo)
                              Container(
                                width: 2,
                                height: obs.isNotEmpty ? 55 : 40,
                                color: Colors.grey.shade300,
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  statusStr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isUltimo
                                        ? Colors.indigo.shade800
                                        : Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Por: $usuario em ${_formatarData(dataLog)}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (obs.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    "Obs: $obs",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Fechar",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
