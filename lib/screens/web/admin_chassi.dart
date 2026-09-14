import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/services/auth_service.dart';
import 'package:vet_route/controllers/permissoes_controller.dart';

// 🏥 IMPORTAÇÃO DAS VIEWS DE GESTÃO DO SAAS
import 'package:vet_route/screens/web/clinicas/clinica_hub.dart';
import 'package:vet_route/screens/web/laboratorios/laboratorio_hub.dart';
import 'package:vet_route/screens/web/entregadores/entregadores_hub.dart';
import 'package:vet_route/screens/widgets/gestao_menus_hub.dart';
import 'package:vet_route/screens/widgets/gestao_perfis_hub.dart';
import 'package:vet_route/screens/widgets/gestao_submenus_hub.dart';
import 'package:vet_route/screens/widgets/gestao_usuarios_hub.dart';

class AdminChassi extends StatelessWidget {
  final Widget conteudo;
  final String titulo;

  const AdminChassi({super.key, required this.conteudo, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return _AdminChassiStateful(conteudo: conteudo, titulo: titulo);
  }
}

class _AdminChassiStateful extends StatefulWidget {
  final Widget conteudo;
  final String titulo;
  const _AdminChassiStateful({required this.conteudo, required this.titulo});

  @override
  State<_AdminChassiStateful> createState() => _AdminChassiStatefulState();
}

class _AdminChassiStatefulState extends State<_AdminChassiStateful> {
  String _rotaAtivaId = "";
  Widget? _mioloCustomizado;

  final List<String> _menusAbertosIds = [];

  static const Map<String, IconData> _iconesMapeados = {
    'local_hospital': Icons.local_hospital_rounded,
    'science': Icons.science_rounded,
    'motorcycle': Icons.two_wheeler_rounded,
    'admin_panel_settings': Icons.admin_panel_settings_rounded,
    'layers': Icons.layers_rounded,
    'account_tree': Icons.account_tree_rounded,
    'people': Icons.people_alt_rounded,
    'dashboard': Icons.grid_view_rounded,
    'analytics': Icons.analytics_rounded,
    'assignment': Icons.assignment_rounded,
    'payments': Icons.credit_card_rounded,
    'inventory': Icons.inventory_rounded,
    'route': Icons.alt_route_rounded,
    'hail': Icons.hail_rounded,
  };

  @override
  void initState() {
    super.initState();
    _carregarContextosIniciais();
  }

  Future<void> _carregarContextosIniciais() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .get();
        final perfilId = userDoc.data()?['perfilId'];
        if (perfilId != null) {
          await permissoesGlobais.inicializarParaUsuario(perfilId);
        }
      }
    } catch (e) {
      debugPrint("Erro ao carregar contextos no Chassi: $e");
    }
  }

  // =========================================================================
  // 🚀 O ROTEADOR CENTRAL DA WEB - 100% DINÂMICO E DESACOPLADO
  // =========================================================================
  Widget _obterTelaDestino(String chaveRota) {
    debugPrint("🚀 Chassi Web requisitando Rota: '$chaveRota'");

    // 1. ROTEAMENTO DINÂMICO DOS HUBS DE OPERAÇÃO
    if (chaveRota.startsWith('clinica_')) {
      return ClinicasHub(rotaAbaAtiva: chaveRota);
    }

    if (chaveRota.startsWith('lab_')) {
      return LaboratoriosHub(rotaAbaAtiva: chaveRota);
    }

    if (chaveRota.startsWith('entregador_')) {
      return const EntregadoresHub();
    }

    // 2. ROTEAMENTO INTELIGENTE DE ADMINISTRAÇÃO E CONFIGURAÇÕES
    final rotaLower = chaveRota.toLowerCase();
    if (rotaLower.contains('submenu')) return const GestaoSubmenusHub();
    if (rotaLower.contains('menu')) return const GestaoMenusHub();
    if (rotaLower.contains('perfi') || rotaLower.contains('perfil'))
      return const GestaoPerfisHub();
    if (rotaLower.contains('usuario') || rotaLower.contains('usuário'))
      return GestaoUsuarioHub();

    // 3. FALLBACK - SE A ROTA AINDA NÃO EXISTE NO APP
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.build_circle_outlined,
            size: 48,
            color: Colors.orange.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "Módulo '$chaveRota' registrado no Banco,\nmas a tela Flutter ainda não foi mapeada no Chassi.",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _executarNavegacao(String chaveRota, String idAtivo) {
    setState(() {
      _rotaAtivaId = idAtivo;
      _mioloCustomizado = _obterTelaDestino(chaveRota);
    });
  }

  @override
  Widget build(BuildContext context) {
    const corSidebarDark = Color(0xFF10163A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Row(
        children: [
          // ─── BARRA LATERAL ESQUERDA (SIDEBAR) ───
          Container(
            width: 280,
            color: corSidebarDark,
            child: Column(
              children: [
                _buildHeaderSidebar(),
                Expanded(child: _buildMenuLateralDinamico()),
                _buildFooterSidebar(),
              ],
            ),
          ),

          // ─── ÁREA DE CONTEÚDO PRINCIPAL (DIREITA) ───
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _mioloCustomizado ?? widget.conteudo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSidebar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.04), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7FFFD4).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: Color(0xFF7FFFD4),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            "VET ROUTE",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuLateralDinamico() {
    return ListenableBuilder(
      listenable: permissoesGlobais,
      builder: (context, child) {
        if (permissoesGlobais.carregando) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF7FFFD4),
              strokeWidth: 2,
            ),
          );
        }

        final menusWeb = permissoesGlobais.menusPermitidos
            .where((m) => m.isWeb == true)
            .toList();
        menusWeb.sort((a, b) => a.peso.compareTo(b.peso));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          itemCount: menusWeb.length,
          itemBuilder: (context, index) {
            final menu = menusWeb[index];
            final submenus = permissoesGlobais
                .getSubmenusDoMenu(menu.id)
                .where((s) => s.isWeb == true)
                .toList();
            submenus.sort((a, b) => a.peso.compareTo(b.peso));

            final iconData =
                _iconesMapeados[menu.icone] ?? Icons.widgets_rounded;
            final bool estaAberto = _menusAbertosIds.contains(menu.id);
            final bool menuSelecionado = _rotaAtivaId == menu.id;

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(hoverColor: Colors.white.withOpacity(0.04)),
                    child: Material(
                      color: menuSelecionado
                          ? const Color(0xFF1F2959)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        dense: true,
                        horizontalTitleGap: 12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        leading: Icon(
                          iconData,
                          color: menuSelecionado
                              ? const Color(0xFF7FFFD4)
                              : Colors.white70,
                          size: 20,
                        ),
                        title: Text(
                          menu.titulo,
                          style: TextStyle(
                            color: menuSelecionado
                                ? Colors.white
                                : Colors.white.withOpacity(0.87),
                            fontWeight: menuSelecionado
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 13.5,
                          ),
                        ),
                        trailing: submenus.isEmpty
                            ? null
                            : Icon(
                                estaAberto
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: Colors.white30,
                                size: 16,
                              ),
                        onTap: () {
                          if (submenus.isEmpty) {
                            _executarNavegacao(menu.rota, menu.id);
                          } else {
                            setState(
                              () => estaAberto
                                  ? _menusAbertosIds.remove(menu.id)
                                  : _menusAbertosIds.add(menu.id),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                  if (submenus.isNotEmpty && estaAberto)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 2),
                      child: Column(
                        children: submenus.map((sub) {
                          final bool subSelecionado = _rotaAtivaId == sub.id;
                          return Padding(
                            padding: const EdgeInsets.only(left: 14, bottom: 2),
                            child: Material(
                              color: subSelecionado
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                dense: true,
                                horizontalTitleGap: 10,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                leading: Icon(
                                  Icons.circle,
                                  color: subSelecionado
                                      ? const Color(0xFF7FFFD4)
                                      : Colors.white24,
                                  size: 6,
                                ),
                                title: Text(
                                  sub.titulo,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: subSelecionado
                                        ? Colors.white
                                        : Colors.white60,
                                    fontWeight: subSelecionado
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                ),
                                onTap: () =>
                                    _executarNavegacao(sub.rota, sub.id),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFooterSidebar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.04), width: 1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          hoverColor: Colors.red.shade900.withOpacity(0.15),
          leading: const Icon(
            Icons.power_settings_new_rounded,
            color: Colors.redAccent,
            size: 20,
          ),
          title: const Text(
            'Desligar Painel',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: 13.5,
            ),
          ),
          onTap: () async {
            await AuthService().logout();
            if (mounted) {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            }
          },
        ),
      ),
    );
  }
}
