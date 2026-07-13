import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/controllers/clinica_controller.dart';

// 🛠️ CORREÇÃO DA INJEÇÃO: Assumindo a instância FirebaseColetaRepository que sua Controller pede
import 'package:vet_route/repositories/firestore_coleta_repository.dart';

class ClinicaDashboardMobileScreen extends StatefulWidget {
  final String rotaQueChamou;

  const ClinicaDashboardMobileScreen({super.key, required this.rotaQueChamou});

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

  @override
  void initState() {
    super.initState();
    // 🛠️ CORREÇÃO DA INJEÇÃO: Passando a implementação concreta para a classe Abstrata
    _controller = ClinicaController(FirestoreColetaRepository());
    _controller.inicializarDashboardRealtime();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
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
                _buildBoardMetricas(),
                const SizedBox(height: 32),

                if (_controller.chamadosAtivos.isNotEmpty) ...[
                  const Text(
                    "Em Andamento",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1F2959),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._controller.chamadosAtivos.map(
                    (chamado) => _buildCardAtivo(chamado),
                  ),
                  const SizedBox(height: 32),
                ],

                const Text(
                  "Últimas Coletas",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F2959),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTabelaHistorico(),
              ],
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Olá, Clínica!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: _indigoDark,
                letterSpacing: -1.0,
              ),
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
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Abertura do fluxo de agendamento integrado...",
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBotaoAcao(
            "Emergência\nAgora",
            Icons.bolt_rounded,
            Colors.red.shade50,
            Colors.red.shade700,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Protocolo de Coleta de Emergência acionado no Firestore!",
                  ),
                ),
              );
            },
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
                  content: Text(
                    "Redirecionando para o catálogo de tubos e insumos...",
                  ),
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

  Widget _buildBoardMetricas() {
    return Row(
      children: [
        Expanded(
          child: _buildCardMetrica(
            "Em Rota",
            _controller.qtdEmRota.toString(),
            Colors.blue.shade600,
            Icons.two_wheeler_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCardMetrica(
            "Aguardando",
            _controller.qtdAguardando.toString(),
            Colors.amber.shade700,
            Icons.hourglass_top_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCardMetrica(
            "Concluídas",
            _controller.qtdConcluidos.toString(),
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

  Widget _buildCardAtivo(Map<String, dynamic> chamado) {
    final status = chamado['status'] ?? 'A Caminho';
    final idCurto = chamado['id'].toString().length > 5
        ? chamado['id'].toString().substring(0, 5).toUpperCase()
        : chamado['id'].toString().toUpperCase();

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
                // 🛠️ CORREÇÃO: Removido o Color literal que deu "Not a constant expression" e substituído por cor direta
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
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.two_wheeler_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Status do Envio",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
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
                      "Abrindo rastreio cartográfico do entregador...",
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
  }

  Widget _buildTabelaHistorico() {
    if (_controller.chamadosHistorico.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Text(
            "Nenhuma coleta concluída recentemente.",
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
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
        itemCount: _controller.chamadosHistorico.length > 5
            ? 5
            : _controller.chamadosHistorico.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          final chamado = _controller.chamadosHistorico[index];
          final idCurto = chamado['id'].toString().length > 5
              ? chamado['id'].toString().substring(0, 5).toUpperCase()
              : chamado['id'].toString().toUpperCase();
          final labNome = chamado['laboratorioNome'] ?? 'Laboratório Destino';

          String horaFormatada = "--:--";
          if (chamado['dataCriacao'] != null) {
            final data = (chamado['dataCriacao'] as Timestamp).toDate();
            horaFormatada = DateFormat('dd/MM HH:mm').format(data);
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
}
