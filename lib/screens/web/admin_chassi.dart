import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/l10n/app_localizations.dart';
import 'package:vet_route/services/auth_service.dart';
import 'package:vet_route/controllers/permissoes_controller.dart';

// Telas do Sistema Administrativo Web
import 'package:vet_route/screens/web/laboratorios/lista_laboratorios_screen.dart';
import 'package:vet_route/screens/widgets/gestao_menus_hub.dart';
import 'package:vet_route/screens/widgets/gestao_perfis_hub.dart';
import 'package:vet_route/screens/widgets/gestao_submenus_hub.dart';
import 'package:vet_route/screens/widgets/gestao_usuarios_hub.dart';
import 'package:vet_route/screens/web/entregador_gestao_web.dart';
import 'package:vet_route/screens/web/clinica_gestao_web.dart';

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

  late Widget _conteudoAtual;
  late String _tituloAtual;

  // 💡 Lista que armazena os IDs dos menus que estão expandidos atualmente
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
          });

          final perfilId = doc.data()?['perfilId'];
          if (perfilId != null) {
            await permissoesGlobais.inicializarParaUsuario(perfilId);
          }
        }
      } catch (e) {
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

  // ROTEADOR DE ÍCONES NATIVOS DO FIRESTORE
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

  // ROTEADOR DE TELAS ADMINISTRATIVAS WEB REAL
  static final Map<String, Widget Function()> _telasMapeadas = {
    'clinica_gestao': () => ClinicaGestaoWeb(),
    'lista_laboratorios': () => const ListaLaboratoriosScreen(),
    'entregador_gestao': () => EntregadorGestaoWeb(),
    'gestao_perfis': () => const GestaoPerfisHub(),
    'gestao_menus': () => const GestaoMenusHub(),
    'gestao_submenus': () => const GestaoSubmenusHub(),
    'gestao_usuarios': () => const GestaoUsuarioHub(),
  };

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
                  child: _conteudoAtual,
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
                  color: Colors.black.withValues(alpha: 0.2),
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
                    "A carregar permissões...",
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
                      // 💡 Argumentos posicionais corrigidos
                      _itemMenuBlindado(
                        iconData,
                        menu.titulo,
                        () {
                          // 💡 Clique no texto: renderiza a tela central imediatamente
                          _executarNavegacao(context, menu.titulo, menu.rota);
                        },
                        // Se houver submenu, injeta o IconButton isolado na direita, mantendo o alinhamento
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
                                  // 💡 Clique na seta: Apenas expande/colapsa de forma estática
                                  _alternarExpansaoMenu(menu.id);
                                },
                              ),
                      ),

                      // Renderização condicional dos filhos sem quebrar o alinhamento visual
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

  // 💡 Auxiliar de Estado local para gerenciar quais itens estão abertos (Limpo a duplicação)
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
    debugPrint("🛣️ Roteando área central para chave: $chaveRota");
    final construtoraTela = _telasMapeadas[chaveRota];

    final Widget telaDestino = construtoraTela != null
        ? construtoraTela()
        : Center(
            child: Text(
              "Módulo '$titulo' ($chaveRota) em desenvolvimento.",
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );

    setState(() {
      _tituloAtual = titulo;
      _conteudoAtual = telaDestino;
    });

    if (MediaQuery.of(context).size.width <= 800) {
      Navigator.of(context).pop();
    }
  }
}
