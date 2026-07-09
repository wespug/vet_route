import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/l10n/app_localizations.dart';
import 'package:vet_route/screens/web/clinicas/clinica_hub.dart';
import 'package:vet_route/screens/web/laboratorios/laboratorio_hub.dart';
import 'package:vet_route/services/auth_service.dart';
import 'package:vet_route/controllers/permissoes_controller.dart';

// Telas do Sistema Administrativo Web
import 'package:vet_route/screens/widgets/gestao_menus_hub.dart';
import 'package:vet_route/screens/widgets/gestao_perfis_hub.dart';
import 'package:vet_route/screens/widgets/gestao_submenus_hub.dart';
import 'package:vet_route/screens/widgets/gestao_usuarios_hub.dart';
import 'package:vet_route/screens/web/entregadores/entregadores_hub.dart';

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
  String _nomeUsuarioLogado = "A carregar...";
  String _emailUsuarioLogado = "A carregar...";
  String? _vinculoId;

  late Widget _conteudoAtual;
  late String _tituloAtual;

  final List<String> _menusExpandidosIds = [];

  @override
  void initState() {
    super.initState();
    _conteudoAtual = widget.conteudo;
    _tituloAtual = widget.titulo;
    _carregarDadosUsuario();
  }

  Future<void> _carregarDadosUsuario() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .get();
        if (doc.exists && mounted) {
          setState(() {
            _nomeUsuarioLogado = doc.data()?['nome'] ?? "Usuário";
            _emailUsuarioLogado = doc.data()?['email'] ?? "Sem E-mail";
            _vinculoId = doc.data()?['vinculoId'];
          });

          final perfilId = doc.data()?['perfilId'];
          if (perfilId != null) {
            await permissoesGlobais.inicializarParaUsuario(perfilId);
          }
        }
      } catch (e) {
        debugPrint(
          "❌ [DEBUG CHASSI] Falha crítica ao ler dados do usuário: $e",
        );
        if (mounted) {
          setState(() {
            _nomeUsuarioLogado = "Administrador";
            _emailUsuarioLogado =
                FirebaseAuth.instance.currentUser?.email ?? "";
          });
        }
      }
    }
  }

  static const Map<String, IconData> _iconesMapeados = {
    'local_hospital': Icons.local_hospital,
    'science': Icons.science,
    'motorcycle': Icons.motorcycle,
    'admin_panel_settings': Icons.admin_panel_settings_outlined,
    'layers': Icons.layers_rounded,
    'account_tree': Icons.account_tree_outlined,
    'people': Icons.people_alt_outlined,
    'dashboard': Icons.dashboard,
    'subdirectory_arrow_right': Icons.subdirectory_arrow_right_rounded,
    'analytics': Icons.analytics_outlined,
    'assignment': Icons.assignment_outlined,
    'payments': Icons.payments_outlined,
    'inventory': Icons.inventory_2_outlined,
  };

  // 💡 CENTRAL DE ROTEAMENTO (Agora limpa, focada nos Hubs Mestre e com DEEP LINK ativado!)
  Widget _obterTelaDestino(String chaveRota, String titulo) {
    switch (chaveRota) {
      // 🏥 Roteamento Clínicas
      case 'clinica_gestao':
      case 'clinica_dashboard':
      case 'clinica_adicionar_usuario':
        return ClinicasHub(rotaAbaAtiva: chaveRota); // 🚀 Injeta o Deep Link

      // 🔬 Roteamento Laboratórios
      case 'lista_laboratorios':
      case 'lista_laboratorios_aba':
      case 'lab_dashboard':
      case 'lab_adicionar_usuario':
      case 'lab_cadastro_exames':
        return LaboratoriosHub(
          rotaAbaAtiva: chaveRota,
        ); // 🚀 Injeta o Deep Link

      // 🏍️ Roteamento Entregadores
      case 'entregador_gestao':
      case 'entregador_dashboard':
        return EntregadoresHub(
          rotaAbaAtiva: chaveRota,
        ); // 🚀 Injeta o Deep Link

      // ⚙️ Roteamento de Configurações Globais
      case 'gestao_perfis':
        return const GestaoPerfisHub();
      case 'gestao_menus':
        return const GestaoMenusHub();
      case 'gestao_submenus':
        return const GestaoSubmenusHub();
      case 'gestao_usuarios':
        return const GestaoUsuarioHub();

      default:
        return Center(
          child: Text(
            "Módulo '$titulo' ($chaveRota) em desenvolvimento.",
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    const corMenuLateral = Color(0xFF343A40);
    const corFundo = Color(0xFFF4F6F9);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        return Scaffold(
          backgroundColor: corFundo,
          appBar: AppBar(
            title: Text(
              _tituloAtual,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 1,
          ),
          drawer: isDesktop
              ? null
              : _construirMenuLateral(context, corMenuLateral),
          body: Row(
            children: [
              if (isDesktop)
                Material(
                  elevation: 4.0,
                  color: corMenuLateral,
                  child: SizedBox(
                    width: 260,
                    child: _construirMenuLateral(context, corMenuLateral),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child:
                      _conteudoAtual, // Aqui o conteúdo já recebe o Deep Link na hora do build!
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _construirMenuLateral(BuildContext context, Color corFundo) {
    final i18n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
          width: double.infinity,
          color: const Color(0xFF23272B),
          child: Column(
            children: [
              const Icon(Icons.pets, size: 52, color: Colors.greenAccent),
              const SizedBox(height: 12),
              const Text(
                "VET ROUTE",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const Text(
                "Painel de Controle SaaS",
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(51),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.account_circle,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _nomeUsuarioLogado,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _emailUsuarioLogado,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(color: Colors.white24, height: 1),

        Expanded(
          child: ListenableBuilder(
            listenable: permissoesGlobais,
            builder: (context, child) {
              if (permissoesGlobais.carregando) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.greenAccent),
                );
              }

              if (permissoesGlobais.menusPermitidos.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    "Nenhum menu liberado para o seu perfil no Firestore.",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final menusOrdenados = List.of(permissoesGlobais.menusPermitidos);
              menusOrdenados.sort((a, b) => a.peso.compareTo(b.peso));

              return ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: menusOrdenados.length,
                itemBuilder: (context, index) {
                  final menu = menusOrdenados[index];
                  final submenus = permissoesGlobais.getSubmenusDoMenu(menu.id);
                  submenus.sort((a, b) => a.peso.compareTo(b.peso));

                  final iconData =
                      _iconesMapeados[menu.icone] ?? Icons.widgets_outlined;
                  final bool estaExpandido = _idEstaExpandido(menu.id);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _itemMenuBlindado(
                        iconData,
                        menu.titulo,
                        () {
                          _executarNavegacao(context, menu.titulo, menu.rota);
                        },
                        trailing: submenus.isEmpty
                            ? null
                            : IconButton(
                                icon: Icon(
                                  estaExpandido
                                      ? Icons.expand_less_rounded
                                      : Icons.expand_more_rounded,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _alternarExpansaoMenu(menu.id);
                                },
                              ),
                      ),

                      if (submenus.isNotEmpty && _idEstaExpandido(menu.id))
                        ...submenus.map((sub) {
                          final subIcon =
                              _iconesMapeados[sub.icone] ??
                              Icons.subdirectory_arrow_right_rounded;
                          return _itemMenuBlindado(subIcon, sub.titulo, () {
                            _executarNavegacao(context, sub.titulo, sub.rota);
                          }, isSubmenu: true);
                        }).toList(),
                    ],
                  );
                },
              );
            },
          ),
        ),

        const Divider(color: Colors.white24, height: 1),

        _itemMenuBlindado(
          Icons.exit_to_app,
          i18n.logout ?? 'Sair do Sistema',
          () async {
            permissoesGlobais.menusPermitidos.clear();
            permissoesGlobais.submenusPermitidos.clear();
            await AuthService().logout();
            if (context.mounted) {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            }
          },
          corTexto: Colors.redAccent,
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _itemMenuBlindado(
    IconData icone,
    String titulo,
    VoidCallback onTap, {
    bool isSubmenu = false,
    Color corTexto = Colors.white,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: isSubmenu
            ? const EdgeInsets.only(left: 56, right: 16)
            : const EdgeInsets.symmetric(horizontal: 24),
        leading: Icon(
          icone,
          color: isSubmenu
              ? Colors.white54
              : (corTexto == Colors.white ? Colors.white70 : corTexto),
          size: isSubmenu ? 18 : 24,
        ),
        title: Text(
          titulo,
          style: TextStyle(
            color: isSubmenu ? Colors.white70 : corTexto,
            fontSize: isSubmenu ? 13 : 14,
            fontWeight: corTexto != Colors.white
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        trailing: trailing,
        hoverColor: Colors.white12,
        onTap: onTap,
      ),
    );
  }

  bool _idEstaExpandido(String id) => _menusExpandidosIds.contains(id);

  void _alternarExpansaoMenu(String id) {
    setState(() {
      if (_menusExpandidosIds.contains(id)) {
        _menusExpandidosIds.remove(id);
      } else {
        _menusExpandidosIds.add(id);
      }
    });
  }

  void _executarNavegacao(
    BuildContext context,
    String titulo,
    String chaveRota,
  ) {
    final Widget telaDestino = _obterTelaDestino(chaveRota, titulo);

    setState(() {
      _tituloAtual = titulo;
      _conteudoAtual = telaDestino;
    });

    if (MediaQuery.of(context).size.width <= 800) {
      Navigator.of(context).pop();
    }
  }
}
