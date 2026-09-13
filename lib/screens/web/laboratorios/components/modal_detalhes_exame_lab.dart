import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/models/coleta_model.dart';
import 'package:vet_route/controllers/gestao_exames_lab_controller.dart';

class ModalDetalhesExameLab extends StatefulWidget {
  final Coleta coleta;
  final GestaoExamesLabController
  controller; // 💡 Controladora injetada diretamente

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

  @override
  void dispose() {
    _nomeController.dispose();
    _veiculoController.dispose();
    _placaController.dispose();
    super.dispose();
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
      // 💡 Utiliza a controladora recebida no construtor
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erro ao despachar coleta."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isEnviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatadorData = DateFormat('dd/MM/yyyy HH:mm');
    final logs = List<Map<String, dynamic>>.from(
      widget.coleta.historico.map((e) => Map<String, dynamic>.from(e)),
    );

    logs.sort((a, b) {
      final dateA = a['data'] != null
          ? (a['data'] as dynamic).toDate()
          : DateTime.now();
      final dateB = b['data'] != null
          ? (b['data'] as dynamic).toDate()
          : DateTime.now();
      return dateA.compareTo(dateB);
    });

    final String codigoRaw =
        widget.coleta.codigoAcompanhamento ?? widget.coleta.id;
    final String codigoFormatado = codigoRaw.length >= 6
        ? codigoRaw.substring(0, 6).toUpperCase()
        : codigoRaw.toUpperCase();

    final bool isAguardando =
        widget.coleta.status.toLowerCase().contains('aguardando') ||
        widget.coleta.status.toLowerCase().contains('pendente');
    final bool temMotoboyAtribuido =
        widget.coleta.idDoEntregador.isNotEmpty ||
        (widget.coleta.nomeDoEntregador.isNotEmpty &&
            widget.coleta.nomeDoEntregador != 'Aguardando Entregador' &&
            widget.coleta.nomeDoEntregador != 'Não Atribuído');

    final bool exibirFormularioDespacho = isAguardando && !temMotoboyAtribuido;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 650,
        constraints: const BoxConstraints(maxHeight: 850),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.coleta.isEmergencia
                          ? Icons.flash_on_rounded
                          : Icons.science_rounded,
                      color: widget.coleta.isEmergencia
                          ? Colors.redAccent
                          : Colors.indigo,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Coleta #$codigoFormatado",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Status: ${widget.coleta.status.toUpperCase()}",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
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
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Clínica Solicitante",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  widget.coleta.origemVisual,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "Laboratório Destino",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  widget.coleta.destinoVisual,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Entregador Atribuído",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  widget.coleta.nomeDoEntregador,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "Data da Solicitação",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  widget.coleta.dataCriacao != null
                                      ? formatadorData.format(
                                          widget.coleta.dataCriacao!,
                                        )
                                      : '--',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (exibirFormularioDespacho) ...[
                      const Text(
                        "Despacho Logístico (Ação Requerida)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.deepOrange,
                        ),
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
                                    onChanged: (val) =>
                                        setState(() => _tipoTransporte = val!),
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
                                    onChanged: (val) =>
                                        setState(() => _tipoTransporte = val!),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (_tipoTransporte == 'parceiro') ...[
                              // 💡 Dropdown dinâmico alimentado 100% pela controladora
                              widget.controller.motoboysParceiros.isEmpty
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          "Nenhuma rota ativa encontrada para este laboratório.",
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 14,
                                            ),
                                      ),
                                      items: widget.controller.motoboysParceiros
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
                                        () => _entregadorSelecionadoId = val,
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                    : const Icon(Icons.send_rounded, size: 18),
                                label: Text(
                                  _isEnviando
                                      ? "Processando..."
                                      : "Confirmar Despacho",
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
                      "Log de Auditoria",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (logs.isEmpty)
                      const Text(
                        "Nenhum log registrado.",
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      ...logs.map((log) {
                        final dateLog = log['data'] != null
                            ? (log['data'] as dynamic).toDate()
                            : DateTime.now();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.radio_button_checked,
                                size: 16,
                                color: Colors.indigo,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          (log['status'] ?? '')
                                              .toString()
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          formatadorData.format(dateLog),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Por: ${log['usuario'] ?? 'Sistema'}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    if (log['observacao'] != null &&
                                        log['observacao'].toString().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4.0,
                                        ),
                                        child: Text(
                                          "Obs: ${log['observacao']}",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
