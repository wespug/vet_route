import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/controllers/clinica_controller.dart';
import 'package:vet_route/repositories/firestore_coleta_repository.dart';
import 'package:vet_route/models/clinica_model.dart';
import 'package:vet_route/models/chamado_coleta_model.dart';

// 💡 IMPORTAÇÕES DO ECOSSISTEMA DE INSUMOS
import 'package:vet_route/controllers/insumo_controller.dart';
import 'package:vet_route/models/insumo_model.dart';

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
                    _buildLista(chamadosAtivos, isHistorico: false)
                  else
                    _buildLista(chamadosHistorico, isHistorico: true),

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
            () => _abrirModalPedirInsumos(),
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
                    "Coletas Finalizadas", // 💡 MUDADO NO MOBILE TB
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

  Widget _buildLista(
    List<Map<String, dynamic>> chamados, {
    required bool isHistorico,
  }) {
    if (chamados.isEmpty) {
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
                isHistorico
                    ? Icons.history_rounded
                    : Icons.inventory_2_outlined,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                isHistorico
                    ? "Nenhum histórico finalizado."
                    : "Nenhuma solicitação ativa hoje.",
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

    if (isHistorico) {
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
          itemCount: chamados.length,
          separatorBuilder: (context, index) =>
              Divider(height: 1, color: Colors.grey.shade100),
          itemBuilder: (context, index) {
            final chamado = chamados[index];
            final String idBruto = chamado['id'] ?? '';
            final idCurto = idBruto.length > 5
                ? idBruto.substring(0, 5).toUpperCase()
                : idBruto.toUpperCase();
            final labNome = chamado['laboratorioNome'] ?? 'Laboratório';

            final isPedidoInsumo = chamado['tipoChamado'] == 'Insumo';

            String horaFormatada = "--:--";
            if (chamado['dataCriacao'] != null) {
              if (chamado['dataCriacao'] is Timestamp) {
                final data = (chamado['dataCriacao'] as Timestamp).toDate();
                horaFormatada = DateFormat('dd/MM HH:mm').format(data);
              } else if (chamado['dataCriacao'] is String) {
                final data = DateTime.tryParse(chamado['dataCriacao']);
                if (data != null)
                  horaFormatada = DateFormat('dd/MM HH:mm').format(data);
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
                  color: isPedidoInsumo
                      ? Colors.teal.shade50
                      : _successColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPedidoInsumo
                      ? Icons.medical_services_rounded
                      : Icons.check_rounded,
                  color: isPedidoInsumo ? Colors.teal : _successColor,
                  size: 18,
                ),
              ),
              title: Text(
                isPedidoInsumo ? "Insumos: $labNome" : labNome,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                "ID #$idCurto",
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

    return Column(
      children: chamados.map((chamado) {
        final status = chamado['status'] ?? 'Aguardando';
        final String idBruto = chamado['id'] ?? '';
        final idCurto = idBruto.length > 5
            ? idBruto.substring(0, 5).toUpperCase()
            : idBruto.toUpperCase();

        final isEmergencia = chamado['isEmergencia'] == true;
        final isPedidoInsumo = chamado['tipoChamado'] == 'Insumo';
        final laboratorioNome = chamado['laboratorioNome'] ?? 'Laboratório';

        final List<Color> cardGradient = isPedidoInsumo
            ? [const Color(0xFF0F5132), const Color(0xFF146C43)]
            : [_indigoDark, const Color(0xFF2A3673)];

        final iconData = isPedidoInsumo
            ? Icons
                  .inventory_2_rounded // 💡 Ícone ajustado
            : (isEmergencia
                  ? Icons.warning_amber_rounded
                  : Icons.motorcycle_rounded); // 💡 Ícone ajustado

        final iconColor = isPedidoInsumo
            ? Colors.tealAccent
            : (isEmergencia ? Colors.redAccent : Colors.white);

        final iconBgColor = isPedidoInsumo
            ? Colors.tealAccent.withOpacity(0.2)
            : (isEmergencia
                  ? Colors.redAccent.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1));

        String resumoItens = "";
        if (isPedidoInsumo && chamado['insumosSolicitados'] != null) {
          final lista = chamado['insumosSolicitados'] as List;
          final qtdTotal = lista.fold<int>(
            0,
            (sum, item) => sum + (item['quantidade'] as int? ?? 0),
          );
          resumoItens = " • $qtdTotal itens solicitados";
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: cardGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: cardGradient.first.withOpacity(0.25),
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
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isPedidoInsumo ? "SUPRIMENTOS #$idCurto" : "ID #$idCurto",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.5,
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
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: iconColor, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPedidoInsumo
                              ? "De: $laboratorioNome$resumoItens"
                              : "Para: $laboratorioNome",
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
                    foregroundColor: cardGradient.first,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("A abrir detalhes da logística..."),
                      ),
                    );
                  },
                  child: Text(
                    isPedidoInsumo
                        ? "Ver Itens Solicitados"
                        : "Acompanhar Trajeto",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 💡 MÁGICA NOVA NO MOBILE TAMBÉM: Remoção da Hora + Campo de Observação
  void _abrirModalNovoChamado({required bool isEmergencia}) {
    String? localLabIdSelecionado;
    String? localLabNomeSelecionado;
    DateTime dataSelecionada = DateTime.now();
    final TextEditingController observacaoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final strData =
                "${dataSelecionada.day.toString().padLeft(2, '0')}/${dataSelecionada.month.toString().padLeft(2, '0')}/${dataSelecionada.year}";

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
                          final dropDownItems = laboratorios.map((item) {
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
                            value: localLabIdSelecionado,
                            hint: const Text("Selecione um laboratório"),
                            onChanged: (val) {
                              setModalState(() {
                                localLabIdSelecionado = val;
                                if (val != null) {
                                  final labSelecionado = laboratorios
                                      .firstWhere((l) => l['id'] == val);
                                  localLabNomeSelecionado =
                                      labSelecionado['nome'] as String;
                                }
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      Text(
                        "2. Descreva o material",
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: observacaoController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: "Ex: 2 tubos de sangue...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        "3. Data Desejada",
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: dataSelecionada,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null &&
                              pickedDate != dataSelecionada)
                            setModalState(() => dataSelecionada = pickedDate);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
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
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.amber.shade800,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Após o agendamento, o laboratório irá confirmar o horário disponível na data solicitada.",
                                style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                    if (localLabIdSelecionado == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Selecione o Laboratório!"),
                        ),
                      );
                      return;
                    }
                    final momentoAgendado = DateTime(
                      dataSelecionada.year,
                      dataSelecionada.month,
                      dataSelecionada.day,
                      0, // Hora zerada
                      0,
                    );
                    final chamado = ChamadoColetaModel(
                      id: '',
                      clinicaId: widget.clinicaContexto.id!,
                      clinicaNome: widget.clinicaContexto.nome,
                      laboratorioId: localLabIdSelecionado!,
                      laboratorioNome: localLabNomeSelecionado!,
                      status: 'Aguardando Entregador',
                      isEmergencia: isEmergencia,
                      dataCriacao: DateTime.now(),
                      dataAgendamento: momentoAgendado,
                      tipoChamado: 'Coleta',
                      observacao: observacaoController
                          .text, // 💡 CAMPO ENVIADO PARA O BANCO
                    );

                    final sucesso = await _controller.criarChamado(chamado);
                    if (sucesso && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Agendado com sucesso!"),
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

  // 💡 MÁGICA REFATORADA: O modal Mobile agora salva na coleção pedidos_insumos
  void _abrirModalPedirInsumos() {
    String? localLabIdSelecionado;
    String? localLabNomeSelecionado;

    final InsumoController insumoController = InsumoController();
    Map<String, int> quantidades = {};
    bool enviando = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                children: [
                  const Icon(Icons.inventory_2_rounded, color: Colors.teal),
                  const SizedBox(width: 10),
                  const Text(
                    "Solicitar Insumos",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                        "1. Fornecedor (Laboratório)",
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<List<Map<String, dynamic>>>(
                        valueListenable: _controller.laboratorios,
                        builder: (context, laboratorios, child) {
                          if (laboratorios.isEmpty)
                            return const Text(
                              "⚠️ Nenhum laboratório cadastrado.",
                              style: TextStyle(color: Colors.redAccent),
                            );
                          final dropDownItems = laboratorios.map((item) {
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
                            value: localLabIdSelecionado,
                            hint: const Text("Selecione o Laboratório base"),
                            onChanged: (val) {
                              setModalState(() {
                                localLabIdSelecionado = val;
                                if (val != null) {
                                  final labSelecionado = laboratorios
                                      .firstWhere((l) => l['id'] == val);
                                  localLabNomeSelecionado =
                                      labSelecionado['nome'] as String;

                                  quantidades.clear();
                                  insumoController.carregarInsumos(val);
                                }
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      if (localLabIdSelecionado != null) ...[
                        Text(
                          "2. Itens Necessários",
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ValueListenableBuilder<bool>(
                            valueListenable: insumoController.isLoading,
                            builder: (context, isLoading, child) {
                              if (isLoading) {
                                return const Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.teal,
                                    ),
                                  ),
                                );
                              }
                              return ValueListenableBuilder<List<InsumoModel>>(
                                valueListenable: insumoController.insumos,
                                builder: (context, insumosList, child) {
                                  if (insumosList.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.all(24.0),
                                      child: Center(
                                        child: Text(
                                          "Este laboratório não possui insumos catalogados.",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    );
                                  }

                                  return Column(
                                    children: insumosList.map((insumo) {
                                      int qtdAtual =
                                          quantidades[insumo.id!] ?? 0;
                                      return Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey.shade100,
                                            ),
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    insumo.descricao,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  Text(
                                                    "${insumo.tipo} • ${insumo.volume}",
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade500,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    Icons
                                                        .remove_circle_outline_rounded,
                                                    color: qtdAtual > 0
                                                        ? Colors.teal
                                                        : Colors.grey.shade300,
                                                  ),
                                                  onPressed: () {
                                                    if (qtdAtual > 0)
                                                      setModalState(
                                                        () =>
                                                            quantidades[insumo
                                                                    .id!] =
                                                                qtdAtual - 1,
                                                      );
                                                  },
                                                ),
                                                SizedBox(
                                                  width: 24,
                                                  child: Text(
                                                    '$qtdAtual',
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons
                                                        .add_circle_outline_rounded,
                                                    color: Colors.teal,
                                                  ),
                                                  onPressed: () =>
                                                      setModalState(
                                                        () =>
                                                            quantidades[insumo
                                                                    .id!] =
                                                                qtdAtual + 1,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: enviando ? null : () => Navigator.pop(context),
                  child: const Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: enviando
                      ? null
                      : () async {
                          if (localLabIdSelecionado == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Selecione o Laboratório!"),
                              ),
                            );
                            return;
                          }

                          final insumosSelecionados = insumoController
                              .insumos
                              .value
                              .where((i) => (quantidades[i.id!] ?? 0) > 0)
                              .map(
                                (i) => {
                                  'insumoId': i.id,
                                  'descricao': i.descricao,
                                  'tipo': i.tipo,
                                  'quantidade': quantidades[i.id!],
                                },
                              )
                              .toList();

                          if (insumosSelecionados.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Selecione a quantidade de pelo menos 1 insumo!",
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          setModalState(() => enviando = true);

                          // 💡 AGORA SALVAMOS O MAP DIRETAMENTE NA COLEÇÃO CERTA!
                          final pedidoData = {
                            'clinicaId': widget.clinicaContexto.id,
                            'clinicaNome': widget.clinicaContexto.nome,
                            'laboratorioId': localLabIdSelecionado,
                            'status': 'Pendente',
                            'dataSolicitacao': FieldValue.serverTimestamp(),
                            'itens': insumosSelecionados,
                          };

                          final sucesso = await _controller.criarPedidoInsumo(
                            pedidoData,
                          );

                          if (sucesso && context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Pedido enviado com sucesso!"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else if (context.mounted) {
                            setModalState(() => enviando = false);
                          }
                        },
                  child: enviando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Solicitar Materiais",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      insumoController.dispose();
    });
  }
}
