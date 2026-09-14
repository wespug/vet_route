import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vet_route/models/clinica_model.dart';
import 'package:vet_route/models/item_logistica_model.dart';
import 'package:vet_route/controllers/chamado_coleta_controller.dart';
import 'package:vet_route/controllers/pedido_insumo_controller.dart';
import 'package:vet_route/screens/web/clinicas/modal/modal_novo_chamado.dart';
import 'components/item_card_coleta_mobile.dart';
import 'components/modal_pedido_insumo_mobile.dart';

class ClinicaMobileScr extends StatefulWidget {
  final Clinica clinicaContexto;

  const ClinicaMobileScr({super.key, required this.clinicaContexto});

  @override
  State<ClinicaMobileScr> createState() => _ClinicaMobileScrState();
}

class _ClinicaMobileScrState extends State<ClinicaMobileScr> {
  late final ChamadoColetaController _controller;
  int _selectedSegment = 0;

  bool _mostrarInsumos = true;
  bool _mostrarAgendadas = true;
  bool _mostrarUrgencias = true;
  bool _ordemMaisRecente = true;

  @override
  void initState() {
    super.initState();
    _controller = ChamadoColetaController();
    _controller.carregarChamados(widget.clinicaContexto.id!);
    _controller.carregarLaboratorios();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Painel Operacional",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.clinicaContexto.nome,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black87,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _controller.isLoading,
        builder: (context, isLoading, child) {
          if (isLoading) {
            return const Center(child: CupertinoActivityIndicator(radius: 14));
          }

          final listenableTarget = _selectedSegment == 0
              ? _controller.itensAtivos
              : _controller.itensHistorico;

          return ValueListenableBuilder<List<ItemLogisticaModel>>(
            valueListenable: listenableTarget,
            builder: (context, listaExibicao, child) {
              final Set<String> _idsLista = {};
              final List<ItemLogisticaModel> listaUnica = [];
              for (var item in listaExibicao) {
                if (!_idsLista.contains(item.id)) {
                  _idsLista.add(item.id);
                  listaUnica.add(item);
                }
              }

              int qtdAguardando = 0;
              int qtdEmRota = 0;
              for (var item in listaUnica) {
                final statusLower = item.status.toLowerCase().trim();
                if (statusLower.contains('aguardando')) {
                  qtdAguardando++;
                } else if (statusLower.contains('rota') ||
                    statusLower.contains('caminho')) {
                  qtdEmRota++;
                }
              }

              List<ItemLogisticaModel> listaFiltrada = listaUnica.where((item) {
                final isEmergencia = item.nomeTipoFormatado
                    .toLowerCase()
                    .contains('urg');
                if (item.isInsumo && !_mostrarInsumos) return false;
                if (!item.isInsumo && isEmergencia && !_mostrarUrgencias)
                  return false;
                if (!item.isInsumo && !isEmergencia && !_mostrarAgendadas)
                  return false;
                return true;
              }).toList();

              listaFiltrada.sort((a, b) {
                if (_ordemMaisRecente) {
                  return b.dataCriacao.compareTo(a.dataCriacao);
                } else {
                  return a.dataCriacao.compareTo(b.dataCriacao);
                }
              });

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildBotaoAcao(
                                context,
                                "Pedir\nInsumos",
                                Icons.inventory_2_rounded,
                                Colors.teal,
                                () => _solicitarAberturaModalInsumos(context),
                              ),
                              const SizedBox(width: 12),
                              _buildBotaoAcao(
                                context,
                                "Coleta\nAgendada",
                                Icons.calendar_today_rounded,
                                Colors.indigo,
                                () => _abrirModal(context, isEmergencia: false),
                              ),
                              const SizedBox(width: 12),
                              _buildBotaoAcao(
                                context,
                                "Coleta de\nUrgência",
                                Icons.flash_on_rounded,
                                Colors.redAccent.shade700,
                                () => _abrirModal(context, isEmergencia: true),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          const Text(
                            "Status Logístico Hoje",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  "Aguardando\nColeta",
                                  qtdAguardando.toString(),
                                  Icons.hourglass_top_rounded,
                                  Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricCard(
                                  "Em Rota /\nTrânsito",
                                  qtdEmRota.toString(),
                                  Icons.route_rounded,
                                  Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          SizedBox(
                            width: double.infinity,
                            child: CupertinoSlidingSegmentedControl<int>(
                              backgroundColor: Colors.grey.shade300.withOpacity(
                                0.5,
                              ),
                              thumbColor: Colors.white,
                              groupValue: _selectedSegment,
                              children: {
                                0: _buildSegmentText("Ativos", 0),
                                1: _buildSegmentText("Histórico", 1),
                              },
                              onValueChanged: (val) {
                                if (val != null)
                                  setState(() => _selectedSegment = val);
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // 💡 NOVO PAINEL DE CONTROLE DE EXIBIÇÃO (Estilo Apple / Premium)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Filtros de Exibição",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(
                                  () => _ordemMaisRecente = !_ordemMaisRecente,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.indigo.shade100,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _ordemMaisRecente
                                            ? "Mais Recentes"
                                            : "Mais Antigos",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.indigo.shade700,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        _ordemMaisRecente
                                            ? CupertinoIcons.sort_down
                                            : CupertinoIcons.sort_up,
                                        size: 14,
                                        color: Colors.indigo.shade700,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildFiltroAppleCard(
                                "Insumos",
                                _mostrarInsumos,
                                CupertinoIcons.cube_box_fill,
                                Colors.teal,
                                (val) => setState(() => _mostrarInsumos = val),
                              ),
                              const SizedBox(width: 10),
                              _buildFiltroAppleCard(
                                "Agendadas",
                                _mostrarAgendadas,
                                CupertinoIcons.calendar,
                                Colors.indigo,
                                (val) =>
                                    setState(() => _mostrarAgendadas = val),
                              ),
                              const SizedBox(width: 10),
                              _buildFiltroAppleCard(
                                "Urgências",
                                _mostrarUrgencias,
                                CupertinoIcons.bolt_fill,
                                Colors.redAccent.shade700,
                                (val) =>
                                    setState(() => _mostrarUrgencias = val),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (listaFiltrada.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.doc_text_search,
                              size: 60,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Nenhum item corresponde aos filtros.",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 40,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: ItemCardColetaMobile(
                              item: listaFiltrada[index],
                            ),
                          );
                        }, childCount: listaFiltrada.length),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFiltroAppleCard(
    String titulo,
    bool isSelected,
    IconData icone,
    Color corAtiva,
    Function(bool) onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(!isSelected),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? corAtiva : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? corAtiva : Colors.grey.shade300,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: corAtiva.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(
                icone,
                size: 20,
                color: isSelected ? Colors.white : Colors.grey.shade500,
              ),
              const SizedBox(height: 6),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentText(String texto, int index) {
    final isSelected = _selectedSegment == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.black87 : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildBotaoAcao(
    BuildContext context,
    String titulo,
    IconData icone,
    Color cor,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icone, color: cor, size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String titulo,
    String valor,
    IconData icone,
    Color cor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icone, color: cor.withOpacity(0.7), size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                valor,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: cor,
                ),
              ),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _abrirModal(BuildContext context, {required bool isEmergencia}) {
    showDialog(
      context: context,
      builder: (_) => ModalNovoChamado(
        isEmergencia: isEmergencia,
        controller: _controller,
        clinicaContexto: widget.clinicaContexto,
      ),
    );
  }

  void _solicitarAberturaModalInsumos(BuildContext context) {
    final pedidoController = PedidoInsumoController();

    final user = FirebaseAuth.instance.currentUser;
    final usuarioAudit = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : (user?.email ?? 'Usuário Mobile');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ModalPedidoInsumoMobile(
        controller: pedidoController,
        clinicaContexto: widget.clinicaContexto,
        usuarioLogado: usuarioAudit,
      ),
    );
  }
}
