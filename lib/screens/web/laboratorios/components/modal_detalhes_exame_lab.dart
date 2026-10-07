import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/models/coleta_model.dart';
import 'package:vet_route/controllers/gestao_exames_lab_controller.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vet_route/screens/widgets/card_rastreio_live.dart';

class ModalDetalhesExameLab extends StatefulWidget {
  final Coleta coleta;
  final GestaoExamesLabController controller;

  const ModalDetalhesExameLab({
    super.key,
    required this.coleta,
    required this.controller,
  });

  @override
  State<ModalDetalhesExameLab> createState() => _ModalDetalhesExameLabState();
}

class _ModalDetalhesExameLabState extends State<ModalDetalhesExameLab> {
  String _tipoTransporte = 'parceiro';
  String? _entregadorSelecionadoId;

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _veiculoController = TextEditingController();
  final TextEditingController _placaController = TextEditingController();

  bool _isEnviando = false;
  bool _modoTrocaAtivo = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _veiculoController.dispose();
    _placaController.dispose();
    super.dispose();
  }

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
    if (s.contains('coletar') || s.contains('indo'))
      return {
        'texto': 'Motoboy no Local / A Caminho',
        'cor': Colors.purple.shade700,
      };
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

  DateTime _parseData(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    if (val is DateTime) return val;
    return DateTime.now();
  }

  String _formatarDataStr(DateTime data) {
    return DateFormat('dd/MM/yyyy HH:mm').format(data);
  }

  Future<void> _confirmarDespacho() async {
    String nomeFinal = '';
    String? idFinal;

    if (_tipoTransporte == 'parceiro') {
      if (_entregadorSelecionadoId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Selecione o Motoboy Parceiro."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final motoboy = widget.controller.motoboysParceiros.firstWhere(
        (e) => e['id'] == _entregadorSelecionadoId,
        orElse: () => {'id': '', 'nome': 'Entregador Desconhecido'},
      );
      nomeFinal = motoboy['nome']!;
      idFinal = motoboy['id'];
    } else {
      if (_nomeController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Informe o nome do motorista do App."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      nomeFinal = _nomeController.text.trim();
    }

    setState(() => _isEnviando = true);

    try {
      await widget.controller.despacharColetaUrgencia(
        coletaId: widget.coleta.id,
        tipoTransporte: _tipoTransporte,
        nomeEntregador: nomeFinal,
        entregadorId: idFinal,
        veiculo: _tipoTransporte == 'externo'
            ? _veiculoController.text.trim()
            : null,
        placa: _tipoTransporte == 'externo'
            ? _placaController.text.trim()
            : null,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erro ao despachar coleta."),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) setState(() => _isEnviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 850),
        padding: const EdgeInsets.all(24),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection(
                widget.coleta.isInsumo ? 'pedidos_insumos' : 'chamados_coleta',
              )
              .doc(widget.coleta.id)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(
                child: CircularProgressIndicator(color: Colors.indigo),
              );
            if (!snapshot.hasData || !snapshot.data!.exists)
              return const Center(
                child: Text("Documento não encontrado na base de dados."),
              );

            final Coleta coletaReativa = Coleta.fromFirestore(snapshot.data!);
            final docData =
                snapshot.data!.data() as Map<String, dynamic>? ?? {};

            final String statusRealTime =
                (docData['status'] ?? coletaReativa.status).toString();
            final configStatus = _obterConfigStatus(statusRealTime);

            final String codigoRaw =
                coletaReativa.codigoAcompanhamento ?? coletaReativa.id;
            final String codigoFormatado = codigoRaw.length >= 6
                ? codigoRaw.substring(0, 6).toUpperCase()
                : codigoRaw.toUpperCase();

            final nomeEntregador = docData['nomeEntregador']?.toString() ?? '';
            final entregadorId = docData['entregadorId']?.toString() ?? '';
            final isExterno = docData['isTransporteExterno'] ?? false;

            final List<Map<String, dynamic>> rawLogs =
                List<Map<String, dynamic>>.from(
                  docData['historicoLogs'] ?? docData['historico'] ?? [],
                ).map((e) => Map<String, dynamic>.from(e)).toList();

            if (docData['comprovanteColetaUrl'] != null &&
                docData['comprovanteColetaUrl'].toString().isNotEmpty) {
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
                  'usuario': nomeEntregador.isNotEmpty
                      ? nomeEntregador
                      : 'Entregador',
                  'data': docData['comprovanteData'] ?? Timestamp.now(),
                  'observacao':
                      'Pacote coletado e validado. Entregador a caminho do destino.',
                });
              }
            }

            if (docData['fotoUrlEntrega'] != null &&
                docData['fotoUrlEntrega'].toString().isNotEmpty) {
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
                  'usuario': nomeEntregador.isNotEmpty
                      ? nomeEntregador
                      : 'Entregador',
                  'data': docData['dataEntrega'] ?? Timestamp.now(),
                  'observacao': 'Pacote entregue e finalizado com sucesso.',
                });
              }
            }

            rawLogs.sort((a, b) {
              final dateA = a['data'] != null
                  ? _parseData(a['data'])
                  : DateTime.now();
              final dateB = b['data'] != null
                  ? _parseData(b['data'])
                  : DateTime.now();
              return dateA.compareTo(dateB);
            });

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
                if (bairro.toString().isNotEmpty) partes.add(bairro.toString());
                return partes.isNotEmpty
                    ? partes.join(' - ')
                    : 'Endereço incompleto';
              }
              return 'Endereço não disponível no sistema';
            }

            final enderecoOrigem = extrairEnderecoSeguro(
              docData['clinicaOrigem'],
            );
            final enderecoDestino = extrairEnderecoSeguro(
              docData['laboratorioDestino'],
            );

            final bool isAguardando =
                statusRealTime.toLowerCase().contains('aguardando') ||
                statusRealTime.toLowerCase().contains('pendente');
            final bool temMotoboyAtribuido =
                (entregadorId.isNotEmpty) ||
                (nomeEntregador.isNotEmpty &&
                    nomeEntregador != 'Aguardando Entregador' &&
                    nomeEntregador != 'Não Atribuído');

            final bool podeTrocarEntregador =
                !statusRealTime.toLowerCase().contains('transporte') &&
                !statusRealTime.toLowerCase().contains('rota') &&
                !statusRealTime.toLowerCase().contains('concluido') &&
                !statusRealTime.toLowerCase().contains('entregue') &&
                !statusRealTime.toLowerCase().contains('cancelado');

            final bool exibirFormularioDespacho =
                (isAguardando && !temMotoboyAtribuido) || _modoTrocaAtivo;

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
                            coletaReativa.isInsumo
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
                              "Coleta #$codigoFormatado",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              coletaReativa.isInsumo
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
                      onPressed: () => Navigator.pop(context),
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
                                valor: coletaReativa.isEmergencia
                                    ? "Coleta de Urgência"
                                    : "Coleta Agendada",
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
                                          coletaReativa.origemVisual,
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
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        "Data da Solicitação",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        coletaReativa.dataCriacao != null
                                            ? _formatarDataStr(
                                                coletaReativa.dataCriacao!,
                                              )
                                            : '--',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
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
                                          coletaReativa.destinoVisual,
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

                        if (temMotoboyAtribuido && !_modoTrocaAtivo)
                          _buildEntregadorCardLive(
                            docData,
                            nomeEntregador,
                            entregadorId,
                            isExterno,
                            podeTrocarEntregador,
                          ),

                        if (exibirFormularioDespacho) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Despacho Logístico (Ação Requerida)",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.deepOrange,
                                ),
                              ),
                              if (_modoTrocaAtivo)
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _modoTrocaAtivo = false),
                                  child: const Text(
                                    "Cancelar Troca",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: RadioListTile<String>(
                                        title: const Text(
                                          "Motoboy Parceiro",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        value: 'parceiro',
                                        groupValue: _tipoTransporte,
                                        activeColor: Colors.deepOrange,
                                        contentPadding: EdgeInsets.zero,
                                        onChanged: (val) => setState(
                                          () => _tipoTransporte = val!,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: RadioListTile<String>(
                                        title: const Text(
                                          "App Externo (Uber/99)",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        value: 'externo',
                                        groupValue: _tipoTransporte,
                                        activeColor: Colors.deepOrange,
                                        contentPadding: EdgeInsets.zero,
                                        onChanged: (val) => setState(
                                          () => _tipoTransporte = val!,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (_tipoTransporte == 'parceiro') ...[
                                  widget.controller.motoboysParceiros.isEmpty
                                      ? const Center(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            child: Text(
                                              "Nenhuma rota ativa encontrada.",
                                              style: TextStyle(
                                                color: Colors.redAccent,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        )
                                      : DropdownButtonFormField<String>(
                                          value: _entregadorSelecionadoId,
                                          hint: const Text(
                                            "Selecione o Entregador",
                                          ),
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 14,
                                                ),
                                          ),
                                          items: widget
                                              .controller
                                              .motoboysParceiros
                                              .map((moto) {
                                                return DropdownMenuItem<String>(
                                                  value: moto['id'],
                                                  child: Text(
                                                    moto['nome'] ??
                                                        'Entregador sem nome',
                                                  ),
                                                );
                                              })
                                              .toList(),
                                          onChanged: (val) => setState(
                                            () =>
                                                _entregadorSelecionadoId = val,
                                          ),
                                        ),
                                ] else ...[
                                  TextFormField(
                                    controller: _nomeController,
                                    decoration: InputDecoration(
                                      labelText: "Nome do Motorista (App)",
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          controller: _veiculoController,
                                          decoration: InputDecoration(
                                            labelText: "Veículo (Ex: Honda CG)",
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 1,
                                        child: TextFormField(
                                          controller: _placaController,
                                          decoration: InputDecoration(
                                            labelText: "Placa",
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _isEnviando
                                        ? null
                                        : _confirmarDespacho,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepOrange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    icon: _isEnviando
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.send_rounded,
                                            size: 18,
                                          ),
                                    label: Text(
                                      _isEnviando
                                          ? "Processando..."
                                          : (_modoTrocaAtivo
                                                ? "Confirmar Troca"
                                                : "Confirmar Despacho"),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        const Text(
                          "Histórico de Movimentação",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildHistoricoLista(
                          rawLogs,
                          docData,
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
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        "Fechar",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
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

  Widget _buildEntregadorCardLive(
    Map<String, dynamic> data,
    String nomeEntregador,
    String entregadorId,
    bool isAppExterno,
    bool podeTrocarEntregador,
  ) {
    String extrairVeiculo(dynamic v) {
      if (v == null) return '';
      if (v is String) return v;
      if (v is Map) {
        final marca = v['marca']?.toString() ?? '';
        final modelo = v['modelo']?.toString() ?? '';
        return "$marca $modelo".trim();
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
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAppExterno
                    ? Icons.local_taxi_rounded
                    : Icons.sports_motorsports_rounded,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAppExterno
                        ? "Motorista de App Externo"
                        : "Entregador Designado",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nomeEntregador,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isAppExterno
                            ? Icons.directions_car_rounded
                            : Icons.directions_bike_rounded,
                        size: 14,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          veiculo,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green.shade800,
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
                          color: Colors.green.shade300,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.pin_outlined,
                        size: 14,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        placa,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (podeTrocarEntregador)
              OutlinedButton.icon(
                onPressed: () => setState(() => _modoTrocaAtivo = true),
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: const Text("Trocar Entregador"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepOrange,
                  side: const BorderSide(color: Colors.deepOrange),
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
              final str = "${v['marca'] ?? ''} ${v['modelo'] ?? ''}".trim();
              if (str.isNotEmpty) veiculo = str;
              if (v['placa'] != null) placa = v['placa'].toString();
            }
          }
          if (uData['placa'] != null &&
              uData['placa'].toString().trim().isNotEmpty)
            placa = uData['placa'].toString();
        }
        return renderContainer(veiculo, placa);
      },
    );
  }

  Widget _buildHistoricoLista(
    List<Map<String, dynamic>> logs,
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
          (l['status'] ?? '').toString().toLowerCase().contains('transporte') ||
          (l['status'] ?? '').toString().toLowerCase().contains('rota') ||
          (l['status'] ?? '').toString().toLowerCase().contains('coletado'),
    );
    if (indexColeta == -1) indexColeta = logs.length - 1;

    int indexEntrega = logs.indexWhere(
      (l) =>
          (l['status'] ?? '').toString().toLowerCase().contains('concluido') ||
          (l['status'] ?? '').toString().toLowerCase().contains('entregue'),
    );
    if (indexEntrega == -1) indexEntrega = logs.length - 1;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final bool isUltimo = index == logs.length - 1;
        final configHist = _obterConfigStatus(log['status']?.toString() ?? '');
        final dateLog = log['data'] != null
            ? _parseData(log['data'])
            : DateTime.now();

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
                        "Por: ${log['usuario'] ?? 'Sistema'} em ${_formatarDataStr(dateLog)}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (log['observacao'] != null &&
                          log['observacao'].toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Obs: ${log['observacao']}",
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color:
                                (log['status'] ?? '')
                                    .toString()
                                    .toLowerCase()
                                    .contains('recusad')
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
                          "Coletado em: ${data['comprovanteData'] != null ? _formatarDataStr(_parseData(data['comprovanteData'])) : 'Data indisponível'}",
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
        ? _formatarDataStr(_parseData(data['dataEntrega']))
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
}
