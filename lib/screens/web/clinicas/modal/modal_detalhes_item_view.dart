import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:vet_route/models/clinica_model.dart';
import 'package:vet_route/controllers/chamado_coleta_controller.dart';
import 'package:vet_route/models/item_logistica_model.dart';

// 💡 1. IMPORTAMOS O NOVO COMPONENTE LINDÃO AQUI
import 'package:vet_route/screens/widgets/card_rastreio_live.dart';
import 'modal_qrcode_coleta.dart';

class ModalDetalhesItemView extends StatelessWidget {
  final ItemLogisticaModel item;
  final Clinica clinicaContexto;
  final String usuarioLogado;
  final ChamadoColetaController controller;

  const ModalDetalhesItemView({
    super.key,
    required this.item,
    required this.clinicaContexto,
    required this.usuarioLogado,
    required this.controller,
  });

  Map<String, dynamic> _obterConfigStatus(String statusRaw) {
    final s = statusRaw.toLowerCase().trim();
    if (s.contains('pendente') || s.contains('analise'))
      return {'texto': 'Pendente / Em Análise', 'cor': Colors.orange.shade800};
    if (s.contains('separacao') ||
        s.contains('separação') ||
        s.contains('aprovado'))
      return {'texto': 'Em Separação', 'cor': Colors.indigo};
    if (s.contains('aguardando_coleta') || s.contains('aguardando_entregador'))
      return {'texto': 'Aguardando Entregador', 'cor': Colors.amber.shade900};
    if (s.contains('coletar'))
      return {'texto': 'Motoboy no Local', 'cor': Colors.purple.shade700};
    if (s.contains('transporte') || s.contains('rota'))
      return {'texto': 'Em Transporte', 'cor': Colors.green.shade800};
    if (s.contains('entregue') ||
        s.contains('concluido') ||
        s.contains('concluído'))
      return {'texto': 'Concluído', 'cor': Colors.teal.shade800};
    if (s.contains('cancelado') || s.contains('recusado'))
      return {'texto': 'Cancelado / Recusado', 'cor': Colors.red.shade700};
    return {
      'texto': statusRaw.replaceAll('_', ' ').toUpperCase(),
      'cor': Colors.grey.shade800,
    };
  }

  bool _verificarSePodeCancelar(String statusRaw) {
    final s = statusRaw.toLowerCase();
    return !s.contains('coletado') &&
        !s.contains('rota') &&
        !s.contains('transporte') &&
        !s.contains('entregue') &&
        !s.contains('concluido') &&
        !s.contains('concluído') &&
        !s.contains('cancelado') &&
        !s.contains('recusado');
  }

  DateTime _parseData(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    if (val is DateTime) return val;
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 850),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection(
                  item.isInsumo ? 'pedidos_insumos' : 'chamados_coleta',
                )
                .doc(item.id)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(
                  child: CircularProgressIndicator(color: Colors.indigo),
                );
              if (!snapshot.hasData || !snapshot.data!.exists)
                return const Center(
                  child: Text("Erro ao carregar dados em tempo real."),
                );

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final String statusRealTime = (data['status'] ?? item.status)
                  .toString();
              final configStatus = _obterConfigStatus(statusRealTime);
              final bool podeCancelarAgora = _verificarSePodeCancelar(
                statusRealTime,
              );

              final bool isMotoboyNoLocal = statusRealTime
                  .toLowerCase()
                  .contains('coletar');

              final String clinicaNome =
                  data['clinicaNome']?.toString() ?? clinicaContexto.nome;
              final String laboratorioNome =
                  data['laboratorioNome']?.toString() ?? item.laboratorioNome;
              final String? nomeEntregador = data['nomeEntregador']?.toString();
              final String observacao = data['observacao']?.toString() ?? '';

              final List<dynamic> rawLogs = List.from(
                data['historicoLogs'] ?? data['historico'] ?? [],
              );

              if (data['comprovanteColetaUrl'] != null &&
                  data['comprovanteColetaUrl'].toString().isNotEmpty) {
                final temLogColeta = rawLogs.any(
                  (l) =>
                      (l['status'] ?? '').toString().toLowerCase().contains(
                        'transporte',
                      ) ||
                      (l['status'] ?? '').toString().toLowerCase().contains(
                        'rota',
                      ) ||
                      (l['status'] ?? '').toString().toLowerCase().contains(
                        'coletad',
                      ),
                );
                if (!temLogColeta) {
                  rawLogs.add({
                    'status': 'em_transporte',
                    'usuario': nomeEntregador ?? 'Entregador',
                    'data': data['comprovanteData'] ?? Timestamp.now(),
                    'observacao':
                        'Pacote coletado e validado. Entregador a caminho do destino.',
                  });
                }
              }

              if (data['fotoUrlEntrega'] != null &&
                  data['fotoUrlEntrega'].toString().isNotEmpty) {
                final temLogEntrega = rawLogs.any(
                  (l) =>
                      (l['status'] ?? '').toString().toLowerCase().contains(
                        'concluido',
                      ) ||
                      (l['status'] ?? '').toString().toLowerCase().contains(
                        'entregue',
                      ),
                );
                if (!temLogEntrega) {
                  rawLogs.add({
                    'status': 'concluido',
                    'usuario': nomeEntregador ?? 'Entregador',
                    'data': data['dataEntrega'] ?? Timestamp.now(),
                    'observacao': 'Pacote entregue e finalizado com sucesso.',
                  });
                }
              }

              final List<HistoricoStatusLog> logsRealTime = rawLogs
                  .map(
                    (e) => HistoricoStatusLog.fromMap(
                      Map<String, dynamic>.from(e),
                    ),
                  )
                  .toList();
              logsRealTime.sort((a, b) => a.data.compareTo(b.data));

              String extrairEnderecoSeguro(Map<String, dynamic>? obj) {
                if (obj == null) return 'Endereço não disponível no sistema';
                final end = obj['endereco'];
                if (end == null) return 'Endereço não disponível no sistema';
                if (end is String) return end;
                if (end is Map) {
                  final rua = end['logradouro'] ?? end['rua'] ?? '';
                  final numero = end['numero'] ?? 'S/N';
                  final bairro = end['bairro'] ?? '';
                  List<String> partes = [];
                  if (rua.toString().isNotEmpty) partes.add("$rua, $numero");
                  if (bairro.toString().isNotEmpty)
                    partes.add(bairro.toString());
                  return partes.isNotEmpty
                      ? partes.join(' - ')
                      : 'Endereço incompleto';
                }
                return 'Endereço não disponível no sistema';
              }

              final enderecoOrigem = extrairEnderecoSeguro(
                data['clinicaOrigem'],
              );
              final enderecoDestino = extrairEnderecoSeguro(
                data['laboratorioDestino'],
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              item.isInsumo
                                  ? Icons.inventory_2_rounded
                                  : Icons.science_rounded,
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Detalhes do Item: #${item.codigo}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.isInsumo
                                    ? "Pedido de Insumos"
                                    : "Coleta de Exames",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildCardInfo(
                                  titulo: "Status Atual",
                                  valor: configStatus['texto'],
                                  corValor: configStatus['cor'],
                                  icone: Icons.info_outline,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildCardInfo(
                                  titulo: "Tipo de Operação",
                                  valor: item.nomeTipoFormatado,
                                  corValor: Colors.black87,
                                  icone: Icons.category_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          const Text(
                            "Trajeto Logístico",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.storefront_rounded,
                                      color: Colors.indigo.shade400,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Origem da Coleta",
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            clinicaNome,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            enderecoOrigem,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 10.0,
                                    top: 4,
                                    bottom: 4,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      width: 2,
                                      height: 20,
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.business_rounded,
                                      color: Colors.indigo.shade400,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Destino da Entrega",
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            laboratorioNome,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            enderecoDestino,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          if (nomeEntregador != null &&
                              nomeEntregador.isNotEmpty)
                            _buildEntregadorCardLive(data, nomeEntregador)
                          else
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.amber.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    color: Colors.amber.shade800,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Aguardando Entregador",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber.shade900,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "O sistema fará a alocação de rota assim que disponível.",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.amber.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 20),

                          if (item.isInsumo && item.itensInsumo.isNotEmpty) ...[
                            const Text(
                              "Itens Solicitados",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: item.itensInsumo.map((insumo) {
                                  final nomeInsumo =
                                      insumo['descricao']?.toString() ??
                                      insumo['nomeInsumo']?.toString() ??
                                      insumo['nome']?.toString() ??
                                      'Insumo';
                                  final qtd =
                                      insumo['quantidade'] ??
                                      insumo['quantidadeSolicitada'] ??
                                      insumo['qtd'] ??
                                      1;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "- $nomeInsumo",
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          "Qtd: $qtd",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          const Text(
                            "Histórico de Movimentação",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // 💡 2. ENVIAMOS ORIGEM E DESTINO AQUI PARA A FUNÇÃO
                          _buildHistoricoLista(
                            logsRealTime,
                            data,
                            statusRealTime,
                            context,
                            enderecoOrigem,
                            enderecoDestino,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      podeCancelarAgora
                          ? TextButton.icon(
                              onPressed: () => _confirmarCancelamento(context),
                              icon: const Icon(
                                Icons.cancel_outlined,
                                color: Colors.red,
                              ),
                              label: const Text(
                                "Cancelar Pedido",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : const Text(
                              "Cancelamento indisponível",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),

                      Row(
                        children: [
                          if (isMotoboyNoLocal)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.qr_code_scanner, size: 18),
                              label: const Text("Liberar p/ Motoboy"),
                              onPressed: () {
                                Navigator.pop(context);
                                showDialog(
                                  context: context,
                                  builder: (_) => ModalQrCodeColeta(
                                    item: item,
                                    nomeEntregador: nomeEntregador,
                                    observacao: observacao,
                                  ),
                                );
                              },
                            ),
                          if (isMotoboyNoLocal) const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("Fechar"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEntregadorCardLive(
    Map<String, dynamic> data,
    String nomeEntregador,
  ) {
    final bool isAppExterno = data['isTransporteExterno'] ?? false;
    final String entregadorId = data['entregadorId']?.toString() ?? '';

    String extrairVeiculo(dynamic v) {
      if (v == null) return '';
      if (v is String) return v;
      if (v is Map) {
        final marca = v['marca']?.toString() ?? '';
        final modelo = v['modelo']?.toString() ?? '';
        final str = "$marca $modelo".trim();
        return str;
      }
      return v.toString();
    }

    final String vFirebase = extrairVeiculo(data['veiculo']);
    final String fallbackVeiculo = vFirebase.isNotEmpty
        ? vFirebase
        : (data['veiculoExterno']?.toString() ?? 'Veículo não informado');
    final String fallbackPlaca =
        data['placa']?.toString() ??
        data['placaExterna']?.toString() ??
        'Não informada';

    Widget renderContainer(String veiculo, String placa) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAppExterno
                ? Colors.purple.shade200
                : Colors.green.shade300,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isAppExterno ? Colors.purple : Colors.green).withOpacity(
                0.04,
              ),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAppExterno
                    ? Colors.purple.shade50
                    : Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAppExterno
                    ? Icons.local_taxi_rounded
                    : Icons.two_wheeler_rounded,
                color: isAppExterno
                    ? Colors.purple.shade700
                    : Colors.green.shade700,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "ENTREGADOR DESIGNADO",
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 0.5,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isAppExterno) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade700,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "APP EXTERNO",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nomeEntregador,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        isAppExterno
                            ? Icons.directions_car_rounded
                            : Icons.directions_bike_rounded,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          veiculo,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.pin_outlined,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        placa,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (entregadorId.isEmpty)
      return renderContainer(fallbackVeiculo, fallbackPlaca);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(entregadorId)
          .snapshots(),
      builder: (context, snapshot) {
        String veiculo = fallbackVeiculo;
        String placa = fallbackPlaca;

        if (snapshot.hasData && snapshot.data!.exists) {
          final uData = snapshot.data!.data() as Map<String, dynamic>;

          if (uData['veiculo'] != null) {
            final v = uData['veiculo'];
            if (v is String && v.trim().isNotEmpty) {
              veiculo = v;
            } else if (v is Map) {
              final marca = v['marca']?.toString() ?? '';
              final modelo = v['modelo']?.toString() ?? '';
              final str = "$marca $modelo".trim();
              if (str.isNotEmpty) veiculo = str;
              if (v['placa'] != null) placa = v['placa'].toString();
            }
          }

          if (uData['placa'] != null &&
              uData['placa'].toString().trim().isNotEmpty) {
            placa = uData['placa'].toString();
          }
        }
        return renderContainer(veiculo, placa);
      },
    );
  }

  Widget _buildCardInfo({
    required String titulo,
    required String valor,
    required Color corValor,
    required IconData icone,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icone, color: Colors.indigo.shade400, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: corValor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 💡 3. ATUALIZADA A ASSINATURA PARA RECEBER ORIGEM E DESTINO
  Widget _buildHistoricoLista(
    List<HistoricoStatusLog> logs,
    Map<String, dynamic> data,
    String statusRealTime,
    BuildContext context,
    String endOrigem,
    String endDestino,
  ) {
    if (logs.isEmpty)
      return const Text(
        "Nenhum histórico disponível.",
        style: TextStyle(color: Colors.grey),
      );

    int indexColeta = logs.indexWhere(
      (l) =>
          l.status.toLowerCase().contains('transporte') ||
          l.status.toLowerCase().contains('rota') ||
          l.status.toLowerCase().contains('coletado'),
    );
    if (indexColeta == -1) indexColeta = logs.length - 1;

    int indexEntrega = logs.indexWhere(
      (l) =>
          l.status.toLowerCase().contains('concluido') ||
          l.status.toLowerCase().contains('entregue'),
    );
    if (indexEntrega == -1) indexEntrega = logs.length - 1;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final bool isUltimo = index == logs.length - 1;
        final configHist = _obterConfigStatus(log.status);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isUltimo
                          ? configHist['cor']
                          : Colors.grey.shade400,
                      shape: BoxShape.circle,
                      border: isUltimo
                          ? Border.all(
                              color: configHist['cor'].withOpacity(0.3),
                              width: 3,
                            )
                          : null,
                    ),
                  ),
                  if (!isUltimo)
                    Expanded(
                      child: Container(width: 2, color: Colors.grey.shade300),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        configHist['texto'].toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isUltimo
                              ? Colors.black87
                              : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Por: ${log.usuario} em ${item.formatarData(log.data)}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (log.observacao.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Obs: ${log.observacao}",
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: log.status.toLowerCase().contains('recusad')
                                ? Colors.red.shade700
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],

                      if (index == indexColeta &&
                          data['comprovanteColetaUrl'] != null &&
                          data['comprovanteColetaUrl']
                              .toString()
                              .isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildCardColeta(data, context),
                      ],
                      if (isUltimo &&
                          statusRealTime.toLowerCase() == 'em_transporte' &&
                          data['entregadorId'] != null) ...[
                        const SizedBox(height: 16),
                        // 💡 4. CHAMAMOS O NOVO MÉTODO AQUI COM TUDO O QUE ELE PRECISA
                        _buildCardMapa(
                          data,
                          statusRealTime,
                          endOrigem,
                          endDestino,
                        ),
                      ],
                      if (index == indexEntrega &&
                          data['fotoUrlEntrega'] != null &&
                          data['fotoUrlEntrega'].toString().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildCardEntrega(data, context),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardColeta(Map<String, dynamic> data, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user_rounded,
                color: Colors.green.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Comprovante de Coleta Segura",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: const EdgeInsets.all(16),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          InteractiveViewer(
                            panEnabled: true,
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                data['comprovanteColetaUrl'].toString(),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.white,
                                size: 40,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          data['comprovanteColetaUrl'].toString(),
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 90,
                                height: 90,
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              ),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.zoom_in,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_filled,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Coletado em: ${data['comprovanteData'] != null ? item.formatarData(_parseData(data['comprovanteData'])) : 'Data indisponível'}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "Local da Coleta:\n${data['comprovanteEndereco'] ?? "Endereço não capturado"}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 💡 5. A NOVA FUNÇÃO LIMPA QUE DELEGA O TRABALHO PARA O COMPONENTE
  Widget _buildCardMapa(
    Map<String, dynamic> data,
    String statusRealTime,
    String endOrigem,
    String endDestino,
  ) {
    return CardRastreioLive(
      entregadorId: data['entregadorId'].toString(),
      enderecoOrigem: endOrigem,
      enderecoDestino: endDestino,
      status: statusRealTime,
    );
  }

  Widget _buildCardEntrega(Map<String, dynamic> data, BuildContext context) {
    final fotoUrl = data['fotoUrlEntrega']?.toString() ?? '';
    final endEntrega =
        data['enderecoEntrega']?.toString() ?? 'Endereço não capturado';
    final strDataEntrega = data['dataEntrega'] != null
        ? item.formatarData(_parseData(data['dataEntrega']))
        : 'Data indisponível';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.teal.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_rounded, color: Colors.teal.shade700),
              const SizedBox(width: 8),
              Text(
                "Comprovante de Entrega no Destino",
                style: TextStyle(
                  color: Colors.teal.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: const EdgeInsets.all(16),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          InteractiveViewer(
                            panEnabled: true,
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                fotoUrl,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.white,
                                size: 40,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          fotoUrl,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 90,
                                height: 90,
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              ),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.zoom_in,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Entregue em: $strDataEntrega",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "Local da entrega:\n$endEntrega",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmarCancelamento(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar Cancelamento"),
        content: const Text(
          "Deseja realmente cancelar esta solicitação? Esta ação não poderá ser desfeita.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Voltar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await controller.cancelarItem(item, usuarioLogado);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Solicitação cancelada."),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Erro: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
              }
            },
            child: const Text("Sim, Cancelar"),
          ),
        ],
      ),
    );
  }
}
