import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/controllers/clinica_controller.dart';
import 'package:vet_route/repositories/firestore_coleta_repository.dart';
import 'package:vet_route/models/clinica_model.dart';
import 'package:vet_route/models/chamado_coleta_model.dart';

class ClinicaDashboardMobileScreen extends StatefulWidget {
  final Clinica clinicaContexto;
  final String rotaQueChamou;

  const ClinicaDashboardMobileScreen({
    super.key,
    required this.clinicaContexto,
    required this.rotaQueChamou,
  });

  @override
  State<ClinicaDashboardMobileScreen> createState() =>
      _ClinicaDashboardMobileScreenState();
}

class _ClinicaDashboardMobileScreenState
    extends State<ClinicaDashboardMobileScreen> {
  late final ClinicaController _controller;

  final Color _indigoDark = const Color(0xFF1F2959);
  final Color _greenAccent = const Color(0xFF7FFFD4);
  final Color _bgOffWhite = const Color(0xFFF5F7FA);
  final Color _successColor = const Color(0xFF10B981);

  int _abaSelecionada = 0;

  // Variáveis do Modal
  String? _labIdSelecionado;
  String? _labNomeSelecionado;

  @override
  void initState() {
    super.initState();
    _controller = ClinicaController(FirestoreColetaRepository());
    _controller.inicializarDashboardRealtime(widget.clinicaContexto.id!);
    _controller.carregarLaboratorios();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _atualizarDados() async {
    await _controller.carregarLaboratorios();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgOffWhite,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          if (_controller.carregandoDashboard) {
            return Center(child: CircularProgressIndicator(color: _indigoDark));
          }

          final chamadosAtivos = _controller.chamadosAtivos;
          final chamadosHistorico = _controller.chamadosHistorico;

          return RefreshIndicator(
            color: _indigoDark,
            backgroundColor: Colors.white,
            onRefresh: _atualizarDados,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCabecalho(),
                  const SizedBox(height: 32),

                  _buildAcoesPrincipais(context),
                  const SizedBox(height: 32),

                  const Text(
                    "Visão Geral",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1F2959),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBoardMetricas(
                    qtdEmRota: _controller.qtdEmRota.toString(),
                    qtdAguardando: _controller.qtdAguardando.toString(),
                    qtdConcluidos: _controller.qtdConcluidos.toString(),
                  ),
                  const SizedBox(height: 32),

                  _buildSeletorDeAbas(),
                  const SizedBox(height: 24),

                  if (_abaSelecionada == 0)
                    _buildListaAtivas(chamadosAtivos)
                  else
                    _buildListaHistorico(chamadosHistorico),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCabecalho() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Olá, ${widget.clinicaContexto.nome}!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: _indigoDark,
                  letterSpacing: -1.0,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                "O que precisa ser transportado hoje?",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(Icons.storefront_rounded, color: _indigoDark, size: 24),
        ),
      ],
    );
  }

  Widget _buildAcoesPrincipais(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildBotaoAcao(
            "Agendar\nColeta",
            Icons.calendar_month_rounded,
            _indigoDark,
            Colors.white,
            () => _abrirModalNovoChamado(isEmergencia: false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBotaoAcao(
            "Emergência\nAgora",
            Icons.bolt_rounded,
            Colors.red.shade50,
            Colors.red.shade700,
            () => _abrirModalNovoChamado(isEmergencia: true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBotaoAcao(
            "Pedir\nInsumos",
            Icons.medical_services_rounded,
            Colors.teal.shade50,
            Colors.teal.shade700,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Redirecionando para o catálogo de tubos..."),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBotaoAcao(
    String titulo,
    IconData icone,
    Color corFundo,
    Color corTexto,
    VoidCallback acao,
  ) {
    return GestureDetector(
      onTap: acao,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: corFundo,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: corFundo.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, color: corTexto, size: 26),
            const SizedBox(height: 8),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: corTexto,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardMetricas({
    required String qtdEmRota,
    required String qtdAguardando,
    required String qtdConcluidos,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildCardMetrica(
            "Em Rota",
            qtdEmRota,
            Colors.blue.shade600,
            Icons.two_wheeler_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCardMetrica(
            "Aguardando",
            qtdAguardando,
            Colors.amber.shade700,
            Icons.hourglass_top_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCardMetrica(
            "Concluídas",
            qtdConcluidos,
            _successColor,
            Icons.check_circle_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildCardMetrica(
    String titulo,
    String valor,
    Color corIcone,
    IconData icone,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: corIcone.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icone, color: corIcone, size: 18),
          ),
          const SizedBox(height: 16),
          Text(
            valor,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: _indigoDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeletorDeAbas() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _abaSelecionada = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _abaSelecionada == 0
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _abaSelecionada == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    "Ativas & Agendadas",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _abaSelecionada == 0
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: _abaSelecionada == 0
                          ? _indigoDark
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _abaSelecionada = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _abaSelecionada == 1
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _abaSelecionada == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    "Dias Anteriores",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _abaSelecionada == 1
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: _abaSelecionada == 1
                          ? _indigoDark
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaAtivas(List<Map<String, dynamic>> chamadosAtivos) {
    if (chamadosAtivos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                "Nenhuma coleta ativa hoje.",
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: chamadosAtivos.map((chamado) {
        final status = chamado['status'] ?? 'Aguardando';
        final String idBruto = chamado['id'] ?? '';
        final idCurto = idBruto.length > 5
            ? idBruto.substring(0, 5).toUpperCase()
            : idBruto.toUpperCase();

        final isEmergencia = chamado['isEmergencia'] == true;
        final laboratorioNome = chamado['laboratorioNome'] ?? 'Laboratório';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_indigoDark, const Color(0xFF2A3673)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _indigoDark.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.tealAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "ID #$idCurto",
                      style: const TextStyle(
                        color: Colors.tealAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.gps_fixed_rounded,
                    color: Colors.white54,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isEmergencia
                          ? Colors.redAccent.withOpacity(0.2)
                          : Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEmergencia
                          ? Icons.warning_amber_rounded
                          : Icons.two_wheeler_rounded,
                      color: isEmergencia ? Colors.redAccent : Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Para: $laboratorioNome",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _indigoDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "A abrir o trajeto cartográfico do entregador...",
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "Acompanhar Trajeto",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildListaHistorico(List<Map<String, dynamic>> chamadosHistorico) {
    if (chamadosHistorico.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.history_rounded,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                "Nenhum histórico de dias anteriores.",
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: chamadosHistorico.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          final chamado = chamadosHistorico[index];
          final String idBruto = chamado['id'] ?? '';
          final idCurto = idBruto.length > 5
              ? idBruto.substring(0, 5).toUpperCase()
              : idBruto.toUpperCase();

          final labNome = chamado['laboratorioNome'] ?? 'Laboratório';

          String horaFormatada = "--:--";
          // 💡 MÁGICA DE PROTEÇÃO DE EXIBIÇÃO: Também previne erro na hora de exibir
          if (chamado['dataCriacao'] != null) {
            if (chamado['dataCriacao'] is Timestamp) {
              final data = (chamado['dataCriacao'] as Timestamp).toDate();
              horaFormatada = DateFormat('dd/MM HH:mm').format(data);
            } else if (chamado['dataCriacao'] is String) {
              final data = DateTime.tryParse(chamado['dataCriacao']);
              if (data != null) {
                horaFormatada = DateFormat('dd/MM HH:mm').format(data);
              }
            }
          }

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _successColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: _successColor, size: 18),
            ),
            title: Text(
              labNome,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              "Coleta #$idCurto",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            trailing: Text(
              horaFormatada,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
          );
        },
      ),
    );
  }

  void _abrirModalNovoChamado({required bool isEmergencia}) {
    _labIdSelecionado = null;
    _labNomeSelecionado = null;
    DateTime dataSelecionada = DateTime.now();
    TimeOfDay horaSelecionada = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final strData =
                "${dataSelecionada.day.toString().padLeft(2, '0')}/${dataSelecionada.month.toString().padLeft(2, '0')}/${dataSelecionada.year}";
            final strHora = horaSelecionada.format(context);

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                children: [
                  Icon(
                    isEmergencia
                        ? Icons.warning_amber_rounded
                        : Icons.calendar_today_rounded,
                    color: isEmergencia ? Colors.redAccent : _indigoDark,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEmergencia ? "Emergência" : "Agendar Coleta",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "1. Selecione o Laboratório",
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<List<Map<String, dynamic>>>(
                        valueListenable: _controller.laboratorios,
                        builder: (context, laboratorios, child) {
                          if (laboratorios.isEmpty) {
                            return const Text(
                              "⚠️ Nenhum laboratório encontrado.",
                              style: TextStyle(color: Colors.redAccent),
                            );
                          }
                          final List<DropdownMenuItem<String>> dropDownItems =
                              laboratorios.map((item) {
                                return DropdownMenuItem<String>(
                                  value: item['id'] as String,
                                  child: Text(item['nome'] as String),
                                );
                              }).toList();

                          return DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            items: dropDownItems,
                            value: _labIdSelecionado,
                            hint: const Text("Selecione um laboratório"),
                            onChanged: (val) {
                              setModalState(() {
                                _labIdSelecionado = val;
                                if (val != null) {
                                  final labSelecionado = laboratorios
                                      .firstWhere((l) => l['id'] == val);
                                  _labNomeSelecionado =
                                      labSelecionado['nome'] as String;
                                }
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "2. Data e Horário",
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: dataSelecionada,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2100),
                                );
                                if (pickedDate != null &&
                                    pickedDate != dataSelecionada) {
                                  setModalState(
                                    () => dataSelecionada = pickedDate,
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.calendar_month_rounded,
                                      color: Colors.indigo.shade400,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      strData,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: horaSelecionada,
                                );
                                if (pickedTime != null &&
                                    pickedTime != horaSelecionada) {
                                  setModalState(
                                    () => horaSelecionada = pickedTime,
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      color: Colors.indigo.shade400,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      strHora,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEmergencia
                        ? Colors.redAccent
                        : _indigoDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    if (_labIdSelecionado == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Selecione o Laboratório destino!"),
                        ),
                      );
                      return;
                    }
                    final momentoAgendado = DateTime(
                      dataSelecionada.year,
                      dataSelecionada.month,
                      dataSelecionada.day,
                      horaSelecionada.hour,
                      horaSelecionada.minute,
                    );

                    final chamado = ChamadoColetaModel(
                      id: '',
                      clinicaId: widget.clinicaContexto.id!,
                      clinicaNome: widget.clinicaContexto.nome,
                      laboratorioId: _labIdSelecionado!,
                      laboratorioNome: _labNomeSelecionado!,
                      status: 'Aguardando Entregador',
                      isEmergencia: isEmergencia,
                      dataCriacao:
                          DateTime.now(), // Isso envia o timestamp certo pro banco novo
                      dataAgendamento: momentoAgendado,
                    );

                    final sucesso = await _controller.criarChamado(chamado);

                    if (sucesso && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Chamado agendado com sucesso!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "Confirmar",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
